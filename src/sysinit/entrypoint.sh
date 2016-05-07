#!/bin/bash

case ${1} in
    app:start)
        /usr/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf
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

