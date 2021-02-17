FROM golang:1.15-buster as configurability
MAINTAINER brian.wilkinson@1and1.co.uk
WORKDIR /go/src/github.com/1and1internet/configurability
RUN git clone https://github.com/1and1internet/configurability.git . \
	&& make main nginx \
	&& echo "configurability successfully built"

FROM 1and1internet/debian-8:latest
MAINTAINER brian.wilkinson@fasthosts.co.uk
ARG DEBIAN_FRONTEND=noninteractive
COPY files /
COPY --from=configurability /go/src/github.com/1and1internet/configurability/bin/configurator /usr/bin/configurator
COPY --from=configurability /go/src/github.com/1and1internet/configurability/bin/plugins/* /opt/configurability/goplugins/
ENV SSL_KEY=/ssl/ssl.key \
    SSL_CERT=/ssl/ssl.crt \
    DOCUMENT_ROOT=html
RUN \
    apt-get update && apt-get install -o Dpkg::Options::=--force-confdef -y nginx && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i -r -e '/^user www-data;/d' /etc/nginx/nginx.conf && \
    echo "daemon off;" >> /etc/nginx/nginx.conf && \
    sed -i -e '/sendfile on;/a\        client_max_body_size 0\;' /etc/nginx/nginx.conf && \
    sed -i -e 's/gzip on/#gzip on/' /etc/nginx/nginx.conf && \
    sed -i -e 's/gzip_disable/#gzip_disable/' /etc/nginx/nginx.conf && \
    rm /etc/nginx/sites-available/* /etc/nginx/sites-enabled/default && \
    chmod -R 777 /var/log/nginx && \
    chmod -R 755 /hooks /init && \
    chmod 755 /var/www && \
    mkdir -p /var/www/html && \
    chmod 777 /var/www/html /var/lib/nginx /etc/DOCUMENT_ROOT && \
    chmod -R 666 /etc/nginx/sites-enabled/* /etc/nginx/conf.d/*

EXPOSE 8080 8443
