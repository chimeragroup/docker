FROM docker:17.06-dind
MAINTAINER Jonathan Bailey<jonathan@chimeria.group>

RUN apk update && \
    apk --no-cache add openssl && \
    rm -rf /var/cache/apk/*

COPY dockerd-tls-entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/dockerd-tls-entrypoint.sh

ENV DOCKER_HOST_NAME docker
ENV DOCKER_HOST tcp://${DOCKER_HOST_NAME}:2376
ENV DOCKER_TLS_VERIFY=1
ENV KEY_EXPIRE_DAYS 365
ENV KEY_PASS c8b84bfcfd614d2a95487383e716801bad684abee37f5b88f432fa8897a82b31

EXPOSE 2376

ENTRYPOINT ["dockerd-tls-entrypoint.sh"]
CMD []