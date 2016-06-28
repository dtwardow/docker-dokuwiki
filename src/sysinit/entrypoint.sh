#!/bin/bash

# Exit on error during script execution
set -e

case ${1} in
    app:start)
        chown -R www-data:www-data \
          ${DATA_PATH}/data \
          ${DATA_PATH}/conf \
          ${DATA_PATH}/lib/tpl \
          ${DATA_PATH}/lib/plugins
        chmod -R 0775 \
          ${DATA_PATH}/data \
          ${DATA_PATH}/conf \
          ${DATA_PATH}/lib/tpl \
          ${DATA_PATH}/lib/plugins

        exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
        ;;
    app:backup)
        /usr/sbin/backup.sh
        ;;
    app:restore)
        /usr/sbin/restore.sh
        ;;
    *)
         if [[ -x $1 ]]; then
            $1
         else
            prog=$(which $1)
            if [[ -n ${prog} ]] ; then
                shift 1
                $prog $@
            else
                echo "ERROR: Parameter mssing!"
                echo "Possible Values:"
                echo "   app:start , app:backup , app:restore"
            fi
        fi
        ;;
esac

