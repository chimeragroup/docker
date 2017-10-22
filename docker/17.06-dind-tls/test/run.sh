#!/bin/bash

set -eo pipefail

[[ `uname` == 'Darwin' ]] && {
	which greadlink gsed gzcat gecho > /dev/null && {
		alias readlink=greadlink sed=gsed zcat=gzcat echo=gecho
		if [ ! -f /usr/local/Cellar/gnu-getopt/1.1.6/bin/getopt ]; then
		    echo 'ERROR: GNU getopt is required for Mac'
		    echo 'brew install gnu-getopt'
		    exit 1;
		fi
		alias getopt=/usr/local/Cellar/gnu-getopt/1.1.6/bin/getopt
	} || {
		echo 'ERROR: GNU utils required for Mac.'
		exit 1
	}
}

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"


cname="docker-daemon-container-$RANDOM-$RANDOM"
cid="$(
	docker run --rm -d -it \
		--privileged \
		--name "$cname" \
		-h docker \
		"$image"
)"

. "$dir/../../../test/retry.sh" 'docker exec $cname docker version'

cname2="docker-daemon-container-$RANDOM-$RANDOM"
cid2="$(
	docker run --rm -d  \
	    --link "${cname}:docker" \
		--privileged \
		-h docker2 \
		-e 'DOCKER_HOST_NAME=docker2' \
		--name "$cname2" \
		"$image"
)"

trap "docker stop $cid $cid2 && rm -rf /tmp/${cname}/keys > /dev/null" EXIT

exec_on_container_2() {
	docker exec $cname2 "$@"
}

. "$dir/../../../test/retry.sh" 'exec_on_container_2 docker -H "tcp://docker2:2376" version'


# Copy client certs to second container
mkdir -p /tmp/${cname}/keys
for file in ca.pem cert.pem key.pem; do
    docker cp ${cname}:/root/.docker/${file} /tmp/${cname}/keys/${file}
    docker cp /tmp/${cname}/keys/${file} ${cname2}:/root/.docker/${file}
done

# Do stuff on container 2 targeting container 1 through TLS
exec_on_container_2 docker -H "tcp://docker:2376" version

