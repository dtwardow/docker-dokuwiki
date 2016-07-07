#!/bin/bash

# Exit on error during script execution
set -e

case ${1} in
    app:start)
        # copy original files to volumes
        echo "Copy dist conf files ..."
        cp -r ${DATA_PATH}/conf_org/* ${DATA_PATH}/conf

        if [ ! "$(ls -A ${DATA_PATH}/data)" ]; then
            echo "Copy initial data dir ..."
            cp -r ${DATA_PATH}/data_org/* ${DATA_PATH}/data
        fi
        if [ ! "$(ls -A ${DATA_PATH}/lib/plugins)" ]; then
            echo "Copy initial plugins dir ..."
            cp -r ${DATA_PATH}/lib/plugins_org/* ${DATA_PATH}/lib/plugins
        fi
        if [ ! "$(ls -A ${DATA_PATH}/lib/tpl)" ]; then
            echo "Copy initial tpl dir ..."
            cp -r ${DATA_PATH}/lib/tpl_org/* ${DATA_PATH}/lib/tpl
        fi

        # copy initial config if local.php is missing (replacement for install.php)
        if [ ! -f ${DATA_PATH}/conf/local.php ]; then
            echo "Copy initial config files ..."
            cp -r ${DATA_PATH}/conf_init/* ${DATA_PATH}/conf/
        fi

        # correct permissions of volumes
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

        # start wiki
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

