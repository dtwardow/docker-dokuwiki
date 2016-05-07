#!/bin/sh

if [ ! -d "${DATA_PATH}" ]; then
    echo "ERROR: Data-Directory <${DATA_PATH}> doesn't exist!" > /dev/stderr
    exit 2;
fi

if [ ! -d "${TRANSFER_PATH}" ]; then
    echo "ERROR: Tranfer-Directory <${TRANSFER_PATH}> doesn't exist!" > /dev/stderr
    exit 3;
fi

_DATE_=$(date +%Y%m%d)

cd ${DATA_PATH}
tar czf ${TRANSFER_PATH}/dokuwiki-${_DATE_}.tar.gz data conf lib/plugins lib/tpl

