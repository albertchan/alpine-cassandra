FROM alpine:3.7
MAINTAINER Albert Chan <atfchan@gmail.com>

ARG VERSION=3.11.2

# Important!  Update this no-op ENV variable when this Dockerfile
# is updated with the current date. It will force refresh of all
# of the base images and things like `apt-get update` won't be using
# old cached versions when the Dockerfile is built.
ENV REFRESHED_AT=2018-05-28 \
    LANG=en_US.UTF-8 \
    TERM=xterm \
    HOME=/

# Update Alpine environment
RUN mkdir /opt && \
    apk add --update --no-cache ca-certificates openjdk8 python wget

# Install gosu
ENV GOSU_VERSION=1.10
RUN set -x && \
    apk add --no-cache --virtual .gosu-deps \
        dpkg \
        gnupg \
        openssl && \
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" && \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" && \
    wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" && \
    export GNUPGHOME="$(mktemp -d)" && \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu && \
    rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc && \
    chmod +x /usr/local/bin/gosu && \
    gosu nobody true && \
    apk --purge del .gosu-deps

# Install Cassandra
ENV CASSANDRA_VERSION=${VERSION} \
    CASSANDRA_HOME=/opt/cassandra \
    CASSANDRA_CONFIG=/etc/cassandra \
    CASSANDRA_PERSIST_DIR=/var/lib/cassandra \
    CASSANDRA_DATA=/var/lib/cassandra/data \
    CASSANDRA_COMMITLOG=/var/lib/cassandra/commitlog \
    CASSANDRA_LOG=/var/log/cassandra \
    CASSANDRA_USER=cassandra

## Create data directories that should be used by Cassandra
RUN mkdir -p ${CASSANDRA_DATA} \
             ${CASSANDRA_CONFIG} \
             ${CASSANDRA_LOG} \
             ${CASSANDRA_COMMITLOG}

## Install it and reduce container size
RUN apk --update --no-cache add wget ca-certificates tar && \
    wget https://archive.apache.org/dist/cassandra/${CASSANDRA_VERSION}/apache-cassandra-${CASSANDRA_VERSION}-bin.tar.gz -P /tmp && \
    tar -xvzf /tmp/apache-cassandra-${CASSANDRA_VERSION}-bin.tar.gz -C /tmp/ && \
    mv /tmp/apache-cassandra-${CASSANDRA_VERSION} ${CASSANDRA_HOME} && \
    apk --purge del wget ca-certificates tar && \
    rm -r /tmp/apache-cassandra-${CASSANDRA_VERSION}-bin.tar.gz \
          /var/cache/apk/*

# Setup entrypoint and bash to execute it
COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN apk add --update --no-cache bash && \
    chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/bin/bash", "/docker-entrypoint.sh"]

# Add default config
RUN mv ${CASSANDRA_HOME}/conf/* ${CASSANDRA_CONFIG}
COPY ./conf/* ${CASSANDRA_CONFIG}/
RUN chmod +x ${CASSANDRA_CONFIG}/*.sh

# Add cassandra bin to PATH
ENV PATH=$PATH:${CASSANDRA_HOME}/bin \
    CASSANDRA_CONF=${CASSANDRA_CONFIG}

# Change directories ownership and access rights
RUN adduser -D -s /bin/sh ${CASSANDRA_USER} && \
    chown -R ${CASSANDRA_USER}:${CASSANDRA_USER} ${CASSANDRA_HOME} \
                                                 ${CASSANDRA_PERSIST_DIR} \
                                                 ${CASSANDRA_DATA} \
                                                 ${CASSANDRA_CONFIG} \
                                                 ${CASSANDRA_LOG} \
                                                 ${CASSANDRA_COMMITLOG} && \
    chmod 777 ${CASSANDRA_HOME} \
              ${CASSANDRA_PERSIST_DIR} \
              ${CASSANDRA_DATA} \
              ${CASSANDRA_CONFIG} \
              ${CASSANDRA_LOG} \
              ${CASSANDRA_COMMITLOG}

USER ${CASSANDRA_USER}
WORKDIR ${CASSANDRA_HOME}

# Expose data volume
VOLUME ${CASSANDRA_PERSIST_DIR}

# 7000: intra-node communication
# 7001: TLS intra-node communication
# 7199: JMX
# 9042: CQL
# 9160: thrift service
EXPOSE 7000 7001 7199 9042 9160

CMD ["cassandra", "-f"]
