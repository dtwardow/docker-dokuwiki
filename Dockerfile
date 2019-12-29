FROM alpine:3

# Set the version you want of Twiki
ENV DOKUWIKI_VERSION 2018-04-22b
ENV DOKUWIKI_CSUM 605944ec47cd5f822456c54c124df255

ENV DATA_PATH=/dokuwiki
ENV TRANSFER_PATH=/transfer.d

# Add Alpine-PHP repo
#ADD https://dl.bintray.com/php-alpine/key/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub
#RUN echo "@php https://dl.bintray.com/php-alpine/v3.10.3/php-7.3" >> /etc/apk/repositories

# Update & install packages & cleanup afterwards
RUN apk add --update --no-cache \
      wget gettext \
      lighttpd \
      php7-fpm php7-cgi php7-gd \
      php7-mcrypt php7-ldap php7-session php7-iconv php7-zlib php7-bz2 php7-curl php7-intl \
      php7-pdo php7-pdo_sqlite php7-pdo_pgsql php7-pdo_mysql php7-json php7-dom \
      php7-xml php7-xmlrpc php7-xmlreader php7-xmlwriter php7-openssl php7-exif php7-ftp \
      php7-gettext php7-imap php7-recode php7-calendar php7-simplexml \
      php7-sockets php7-soap php7-snmp php7-xsl php7-zip \
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
HEALTHCHECK --interval=10s --start-period=5s --timeout=5s CMD wget --quiet http://localhost/ || exit 1

