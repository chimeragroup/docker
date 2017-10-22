#!/bin/sh
set -e

# Server key
openssl genrsa -aes256 -passout pass:${KEY_PASS} -out server.pass.key 4096
openssl rsa -passin pass:${KEY_PASS} -in server.pass.key -out ca-key.pem
rm server.pass.key
openssl req -new -x509 -subj "/CN=${DOCKER_HOST_NAME}/OU=Dev/O=Chimera/L=DFW/ST=TX/C=US" \
    -days ${KEY_EXPIRE_DAYS} -key ca-key.pem -sha256 -out ca.pem
openssl genrsa -out server-key.pem 4096
openssl req -subj "/CN=${DOCKER_HOST_NAME}" -sha256 -new -key server-key.pem -out server.csr
echo "subjectAltName = DNS:${DOCKER_HOST_NAME},IP:0.0.0.0,IP:127.0.0.1" >> extfile.cnf
echo extendedKeyUsage = serverAuth >> extfile.cnf
openssl x509 -req -days ${KEY_EXPIRE_DAYS} -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile extfile.cnf

# Client key
openssl genrsa -out key.pem 4096
openssl req -subj '/CN=client' -new -key key.pem -out client.csr
echo extendedKeyUsage = clientAuth >> extfile.cnf
openssl x509 -req -days ${KEY_EXPIRE_DAYS} -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out cert.pem -extfile extfile.cnf

# Clean up
rm -v client.csr server.csr
chmod -v 0400 ca-key.pem key.pem server-key.pem
chmod -v 0444 ca.pem server-cert.pem cert.pem

# Secure client
mkdir -pv ~/.docker
cp -v ca.pem ~/.docker/ && cp -v cert.pem ~/.docker/ && cp -v key.pem ~/.docker/

if [ "$#" -eq 0 -o "${1#-}" != "$1" ]; then
	set -- dockerd \
	    --tlsverify --tlscacert=ca.pem --tlscert=server-cert.pem --tlskey=server-key.pem \
		--host=unix:///var/run/docker.sock \
		--host=0.0.0.0:2376 \
		--storage-driver=vfs \
		"$@"
fi

if [ "$1" = 'dockerd' ]; then
	set -- sh "$(which dind)" "$@"
fi

exec "$@"