FROM tinco/passenger-standalone-alpine-node

# Run when Alpine cdn is down
RUN sed -i -e 's/dl-cdn/dl-4/g' /etc/apk/repositories

RUN apk add --no-cache --virtual build-deps binutils build-base ruby-dev linux-headers curl-dev pcre-dev ruby-rake && \
    apk add --no-cache -X http://dl-3.alpinelinux.org/alpine/edge/main libexecinfo libexecinfo-dev

# Node.JS Section
ENV NODE_VERSION=v6.4.0 NPM_VERSION=2
RUN apk add libgcc libstdc++ && \
    apk add --virtual node-deps --no-cache curl make gcc g++ python linux-headers paxctl gnupg ca-certificates && \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys \
      9554F04D7259F04124DE6B476D5A82AC7E37093B \
      94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
      0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
      FD3A5288F042B6850C66B31F09FE44734EB7990E \
      71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
      DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
      C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
      B9AE9905FFD7803F25714661B63B535A4C206CA9 && \
    curl -o node-${NODE_VERSION}.tar.gz -sSL https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}.tar.gz && \
    curl -o SHASUMS256.txt.asc -sSL https://nodejs.org/dist/${NODE_VERSION}/SHASUMS256.txt.asc && \
    gpg --verify SHASUMS256.txt.asc && \
    grep node-${NODE_VERSION}.tar.gz SHASUMS256.txt.asc | sha256sum -c - && \
    tar -zxf node-${NODE_VERSION}.tar.gz && \
    cd node-${NODE_VERSION} && \
    export GYP_DEFINES="linux_use_gold_flags=0" && \
    ./configure --prefix=/usr && \
    NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
    make -j${NPROC} -C out mksnapshot BUILDTYPE=Release && \
    paxctl -cm out/Release/mksnapshot && \
    make -j${NPROC} && \
    make install && \
    paxctl -cm /usr/bin/node && \
    cd / && \
    rm -rf /etc/ssl /node-${NODE_VERSION}.tar.gz /SHASUMS256.txt.asc /node-${NODE_VERSION} \
      /usr/share/man /tmp/* /var/cache/apk/* /root/.gnupg

ADD build-init /bin/build-init
RUN chmod +x /bin/build-init

ENTRYPOINT ["build-init"]
