FROM alpine:3.9

# Set the version you want of Twiki
ENV DOKUWIKI_VERSION 2018-04-22b
ENV DOKUWIKI_CSUM 605944ec47cd5f822456c54c124df255

ENV DATA_PATH=/dokuwiki
ENV TRANSFER_PATH=/transfer.d

# Add Alpine-PHP repo
ADD https://dl.bintray.com/php-alpine/key/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub
RUN echo "@php https://dl.bintray.com/php-alpine/v3.9/php-7.3" >> /etc/apk/repositories

# Update & install packages & cleanup afterwards
RUN apk add --update --no-cache \
      wget gettext \
      lighttpd \
      php-fpm@php php-cgi@php php-gd@php php7-pear-net_smtp@php \
      php7-mcrypt php-ldap@php php-session@php php-iconv@php php-zlib@php php-bz2@php php-curl@php php-intl@php \
      php-pdo@php php-pdo_sqlite@php php-pdo_pgsql@php php-pdo_mysql@php php-json@php \
      php-xml@php php-xmlrpc@php \
      supervisor

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

# Configure lighttpd
ADD src/lighttpd/dokuwiki.conf /tmp/dokuwiki.conf
RUN envsubst '$DATA_PATH' < /tmp/dokuwiki.conf > /etc/lighttpd/dokuwiki.conf && \
    echo "include \"dokuwiki.conf\"" >> /etc/lighttpd/lighttpd.conf 

# Configure SupervisorD
ADD src/sysinit/supervisor/*.ini /etc/supervisor.d/

# Backup & Restore
RUN mkdir ${TRANSFER_PATH}
ADD src/tools/*               /usr/sbin/

# SysInit
ADD src/sysinit/entrypoint.sh /

EXPOSE 80
VOLUME ["${DATA_PATH}/data/","${DATA_PATH}/lib/plugins/","${DATA_PATH}/conf/","${DATA_PATH}/lib/tpl/","/var/log/"]

ENTRYPOINT ["/entrypoint.sh"]
HEALTHCHECK --interval=5m --start-period=10s --timeout=3s CMD wget --quiet http://localhost/ || exit 1

