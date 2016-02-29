#!/usr/bin/env sh
#
# rmp-prerecord-schedule    Start/Stop the Pre-record Schedule Tool.
#
# chkconfig:   35 99 99
# description: Provides execution functions for installed service
#
# Usage: service (start|stop|status|restart)
#
. /etc/rc.d/init.d/functions

SERVICE="rmp-prerecord-schedule"

[ -f /etc/default/$SERVICE ] && . /etc/default/$SERVICE

LOG_FILE=/var/log/$SERVICE.log
PID_FILE=/var/run/$SERVICE.pid
EXEC_FILE=/usr/lib/$SERVICE/start.sh


start() {
  echo -n $"Starting $SERVICE "
  daemon --pidfile=${PID_FILE} "$EXEC_FILE >> $LOG_FILE 2>&1 &"
  retval=$?
  echo
  return $retval
}

stop() {
  echo -n $"Stopping $SERVICE "
  killproc -p $PID_FILE
  retval=$?
  echo
  return $retval
}

restart() {
  stop
  start
}

reload() {
  restart
}

force_reload() {
  restart
}

rh_status() {
  status -p $PID_FILE $SERVICE
}

rh_status_q() {
  rh_status >/dev/null 2>&1
}

case "$1" in
  start)
    rh_status_q && exit 0
    $1
    ;;
  stop)
    rh_status_q || exit 0
    $1
    ;;
  restart)
    $1
    ;;
  reload)
    rh_status_q || exit 7
    $1
    ;;
  force-reload)
    force_reload
    ;;
  status)
    rh_status
    ;;
  condrestart|try-restart)
    rh_status_q || exit 0
    restart
    ;;
  *)
    echo $"Usage: $0 {start|stop|status|restart|condrestart|try-restart|reload|force-reload}"
    exit 2
esac

exit $?