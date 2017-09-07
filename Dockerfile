FROM debian:jessie
MAINTAINER Dennis Twardowsky <twardowsky@gmail.com>

# Set the version you want of Twiki
ENV DOKUWIKI_VERSION 2017-02-19e
ENV DOKUWIKI_CSUM 09bf175f28d6e7ff2c2e3be60be8c65f

ENV LAST_REFRESHED 07. Sep 2017

ENV DATA_PATH=/dokuwiki
ENV TRANSFER_PATH=/transfer.d

# Set company's proxy server
RUN if [ x${http_proxy} != "x" ]; then \
       echo "Acquire::http::Proxy \"${http_proxy}\";" > /etc/apt/apt.conf; \
    fi

# Update & install packages & cleanup afterwards
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install \
      wget \
      lighttpd \
      php5-fpm php5-cgi php5-gd php-net-smtp \
      php5-mcrypt php5-ldap php5-sqlite \
      php5-mysql php5-pgsql php5-json \
      php5-xmlrpc \
      gettext-base \
      supervisor && \
    apt-get clean autoclean && \
    apt-get autoremove && \
    rm -rf /var/lib/{apt,dpkg,cache,log}

# Download & check & deploy dokuwiki & cleanup
# rename data, conf, plugins & tpl directories to tmp location
RUN wget -q -O /dokuwiki.tgz "http://download.dokuwiki.org/src/dokuwiki/dokuwiki-$DOKUWIKI_VERSION.tgz" && \
    if [ "$DOKUWIKI_CSUM" != "$(md5sum /dokuwiki.tgz | awk '{print($1)}')" ];then echo "Wrong md5sum of downloaded file!"; exit 1; fi && \
    mkdir ${DATA_PATH} && \
    tar -zxf dokuwiki.tgz -C ${DATA_PATH} --strip-components 1 && \
    rm dokuwiki.tgz ${DATA_PATH}/install.php && \
    mv ${DATA_PATH}/data/ ${DATA_PATH}/data_org/ && \
    mv ${DATA_PATH}/conf/ ${DATA_PATH}/conf_org/ && \
    mv ${DATA_PATH}/lib/plugins/ ${DATA_PATH}/lib/plugins_org/ && \
    mv ${DATA_PATH}/lib/tpl/ ${DATA_PATH}/lib/tpl_org/ && \
    mkdir ${DATA_PATH}/data/ ${DATA_PATH}/conf/ ${DATA_PATH}/lib/plugins/ ${DATA_PATH}/lib/tpl/

# initial config (replacement of install.php)
ADD src/dokuwiki/conf/ ${DATA_PATH}/conf_init/

# Set up ownership
RUN chown -R www-data:www-data ${DATA_PATH}

# Configure lighttpd
ADD src/lighttpd/dokuwiki.conf /tmp/dokuwiki.conf
RUN envsubst '$DATA_PATH' < /tmp/dokuwiki.conf > /etc/lighttpd/conf-available/20-dokuwiki.conf
RUN lighty-enable-mod dokuwiki fastcgi accesslog
RUN mkdir /var/run/lighttpd && chown www-data.www-data /var/run/lighttpd

# Configure SupervisorD
ADD src/sysinit/supervisor/*.conf /etc/supervisor/conf.d/

RUN mkdir ${TRANSFER_PATH}
ADD src/tools/*               /usr/sbin/
ADD src/sysinit/entrypoint.sh /usr/sbin/

EXPOSE 80
VOLUME ["${DATA_PATH}/data/","${DATA_PATH}/lib/plugins/","${DATA_PATH}/conf/","${DATA_PATH}/lib/tpl/","/var/log/"]

ENTRYPOINT ["/usr/sbin/entrypoint.sh"]

