## Docker w/TLS
These are extended versions of the [official docker images](https://hub.docker.com/_/docker/).  The purpose of these extended versions is to provide secure TLS versions of the "*-dind" tags.  If you do not need TLS for your "docker-in-docker" endeavors, please use the [official images](https://hub.docker.com/_/docker/).

You may be asking yourself, "What is the purpose of this?".  One scenario would be if you were developing software that inspects or performs operation on docker hosts remotely.  With these images one could easily use them for integration testing on the aforementioned software.  


### Supported tags and respective `Dockerfile` links
* [`17.10-dind-tls`](https://github.com/chimeragroup/docker/blob/master/docker/17.10-dind-tls/Dockerfile), [`17.10`](https://github.com/chimeragroup/docker/blob/master/docker/17.10-dind-tls/Dockerfile), [`edge`](https://github.com/chimeragroup/docker/blob/master/docker/17.10-dind-tls/Dockerfile), [`latest`](https://github.com/chimeragroup/docker/blob/master/docker/17.10-dind-tls/Dockerfile) [(Dockerfile)](https://github.com/chimeragroup/docker/blob/master/docker/17.10-dind-tls/Dockerfile)
* [`17.09-dind-tls`](https://github.com/chimeragroup/docker/blob/master/docker/17.09-dind-tls/Dockerfile), [`17.09`](https://github.com/chimeragroup/docker/blob/master/docker/17.09-dind-tls/Dockerfile) [(Dockerfile)](https://github.com/chimeragroup/docker/blob/master/docker/17.09-dind-tls/Dockerfile)
* [`17.06-dind-tls`](https://github.com/chimeragroup/docker/blob/master/docker/17.06-dind-tls/Dockerfile), [`17.06`](https://github.com/chimeragroup/docker/blob/master/docker/17.06-dind-tls/Dockerfile) [(Dockerfile)](https://github.com/chimeragroup/docker/blob/master/docker/17.06-dind-tls/Dockerfile)


### Links
* Docker official images
  [official images](https://hub.docker.com/_/docker/).

* Github source repository 
  [chimeragroup docker repo](https://github.com/chimeragroup/docker)


### Starting a secure instance
By default the hostname is expected to be "**docker**".  You can override this default (see examples further down).

**Note:** This image includes EXPOSE 2376 (the SECURE Docker port), so standard container linking will make it automatically available to the linked containers (as the following examples illustrate).

```bash
docker run --rm --privileged -h docker --name secure-docker-1 -d chimeragroup/docker:edge
```


### Where are the keys?
All of the server and signed client keys are generated on startup and are in **/**.  Also, the client keys are copied to **/root/.docker** to make the client on the container instance secure by default.  If you need to extract the client keys to connect remotely:

```bash
mkdir -p /tmp/secure-docker-1/keys
for file in ca.pem cert.pem key.pem; do
    docker cp secure-docker-1:/root/.docker/${file} /tmp/secure-docker-1/keys/${file}
done
```


### Environmental variables

| Variable              | Default                   | Description  |
| --------------------- |:-------------------------:| ------------:|
| **DOCKER_HOST_NAME**  | docker                    | The docker hostname the certificate expects (Common Name).  Whatever you set this to you will also want to pass the -h flag when running the container with the same hostname. |
| **DOCKER_HOST**       | tcp://docker:2376         | The docker host the client will use to connect to docker. |
| **KEY_EXPIRE_DAYS**   | 365                       | Number of days the certificate is valid. |
| **KEY_PASS**          | (a long random string...) | The password string used to create encryption keys.  Note: I have not tested this will special characters.  I used the following command to generate a random string: `openssl rand -hex 32` |



### Multi-container example
The following example creates two secure instances with the second instance's client pointing to the first over TLS.

**Create the instances**
```bash
docker run --rm --privileged -h docker --name secure-docker-1 -d chimeragroup/docker:edge
docker run --rm --privileged -h docker2 -e 'DOCKER_HOST_NAME=docker2' --link "secure-docker-1:docker" --name secure-docker-2 -d chimeragroup/docker:edge
```

**Copy the client keys from the first container to the second** 
```bash
mkdir -p /tmp/secure-docker-1/keys
for file in ca.pem cert.pem key.pem; do
    docker cp secure-docker-1:/root/.docker/${file} /tmp/secure-docker-1/keys/${file}
    docker cp /tmp/secure-docker-1/keys/${file} secure-docker-2:/root/.docker/${file}
done
```

**Verify second host can connect to first**
```bash
docker exec secure-docker-2 docker -H "tcp://docker:2376" version
```
