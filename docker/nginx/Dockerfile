# docker/nginx/Dockerfile
FROM ubuntu:22.04

ENV OPENRESTY_VERSION=1.21.4.1
ENV DEBIAN_FRONTEND=noninteractive

# Install build tools and libs (including libpq-dev required by ngx_postgres)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential ca-certificates wget curl git pkg-config \
    libpcre3-dev libssl-dev zlib1g-dev libreadline-dev \
    libncurses5-dev libxml2-dev libexpat1-dev libgd-dev \
    libpq-dev autoconf automake libtool unzip lua5.3 lua5.3-dev luarocks \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

# Download, extract and compile OpenResty with the exact flags you requested
RUN wget https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz && \
    tar xzf openresty-${OPENRESTY_VERSION}.tar.gz && \
    cd openresty-${OPENRESTY_VERSION} && \
    ./configure --prefix=/opt/openresty \
                --with-pcre-jit \
                --with-ipv6 \
                --without-http_redis2_module \
                --with-http_iconv_module \
                --with-http_postgres_module \
                -j8 && \
    make -j8 && \
    make install && \
    cd /opt && \
    rm -rf openresty-${OPENRESTY_VERSION}* openresty-${OPENRESTY_VERSION}.tar.gz

ENV PATH="/opt/openresty/bin:/opt/openresty/nginx/sbin:${PATH}"
# ensure luarocks installs into OpenResty's lua path (lua-resty-prometheus is pure lua)
RUN luarocks install lua-resty-prometheus

# Copy nginx config and lua scripts from build context (ensure you build with docker/nginx as context)
COPY nginx.conf /opt/openresty/nginx/conf/nginx.conf
COPY lua/ /opt/openresty/nginx/lua/

# create log dir and ensure permissions
RUN mkdir -p /opt/openresty/nginx/logs && chmod -R 755 /opt/openresty/nginx

EXPOSE 80

CMD ["openresty", "-g", "daemon off;"]
