# VERSION 0.1
# AUTHOR:          Dennis Twardowsky <twardowsky@gmail.com>
# ORIGINAL AUTHOR: Miroslav Prasil <miroslav@prasil.info>
# DESCRIPTION:     Image with DokuWiki & lighttpd
# TO_BUILD:        docker build -t mprasil/dokuwiki .
# TO_RUN:          docker run -d -p 80:80 --name my_wiki mprasil/dokuwiki


FROM debian:jessie
MAINTAINER Dennis Twardowsky <twardowsky@gmail.com>

# Set the version you want of Twiki
ENV DOKUWIKI_VERSION 2015-08-10a
ENV DOKUWIKI_CSUM a4b8ae00ce94e42d4ef52dd8f4ad30fe

ENV LAST_REFRESHED 6. September 2015

ENV DATA_PATH=/dokuwiki

# Set company's proxy server
RUN if [ x${http_proxy} != "x" ]; then \
       echo "Acquire::http::Proxy \"${http_proxy}\";" > /etc/apt/apt.conf; \
    fi

# Update & install packages & cleanup afterwards
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install wget lighttpd php5-cgi php5-gd gettext-base && \
    apt-get clean autoclean && \
    apt-get autoremove && \
    rm -rf /var/lib/{apt,dpkg,cache,log}

# Download & check & deploy dokuwiki & cleanup
RUN wget -q -O /dokuwiki.tgz "http://download.dokuwiki.org/src/dokuwiki/dokuwiki-$DOKUWIKI_VERSION.tgz" && \
    if [ "$DOKUWIKI_CSUM" != "$(md5sum /dokuwiki.tgz | awk '{print($1)}')" ];then echo "Wrong md5sum of downloaded file!"; exit 1; fi && \
    mkdir ${DATA_PATH} && \
    tar -zxf dokuwiki.tgz -C ${DATA_PATH} --strip-components 1 && \
    rm dokuwiki.tgz

# Set up ownership
RUN chown -R www-data:www-data ${DATA_PATH}

# Configure lighttpd
ADD dokuwiki.conf /tmp/dokuwiki.conf
RUN envsubst '$DATA_PATH' < /tmp/dokuwiki.conf > /etc/lighttpd/conf-available/20-dokuwiki.conf
RUN lighty-enable-mod dokuwiki fastcgi accesslog
RUN mkdir /var/run/lighttpd && chown www-data.www-data /var/run/lighttpd

EXPOSE 80
VOLUME ["${DATA_PATH}/data/","${DATA_PATH}/lib/plugins/","${DATA_PATH}/conf/","${DATA_PATH}/lib/tpl/","/var/log/"]

ENTRYPOINT ["/usr/sbin/lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"]

