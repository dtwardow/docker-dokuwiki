#!/bin/sh

if [ ! -d "${DATA_PATH}" ]; then
    echo "ERROR: Data-Directory <${DATA_PATH}> doesn't exist!" > /dev/stderr
    exit 1;
fi

if [ ! -d "${TRANSFER_PATH}" ]; then
    echo "ERROR: Transfer-Directory <${TRANSFER_PATH}> doesn't exist!" > /dev/stderr
    exit 2;
fi

for _FILE_ in ${TRANSFER_PATH}/*.tar.gz; do
    echo "Restore <${_FILE_}> to ${DATA_PATH}" > /dev/stderr
    cd ${DATA_PATH} && tar xzf ${_FILE_} 
done

chown -R www-data:www-data ${DATA_PATH}

