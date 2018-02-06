#!/usr/bin/ksh
###########################################################################
#
# Oly2TA_Alert.sh
#
# Procedure used to run and control the TAP alerts triggered by polling
# queries (some other alerts are also triggered by subscription)
#
# Parameters    :  ACTION
# Output  :  None
# Prerequisites :   
#  - Variable $OLY2TA_HOME must be set
#  - Configuration file $OLY2TA_HOME/Oly2TA$OLY2TA_SITE.cfg
#    must be up-to-date
#
# Exit values   :   0   if OK
#      255 if not OK
#
############################################################################
#
# Creation : Frédéric Haller / Umea Consulting - 27/04/2016
#
############################################################################
#
# Initialisations
#
if [[ "$OLY2TA_HOME" = ""  || ! -x "$OLY2TA_HOME/config/Oly2TA$OLY2TA_SITE.cfg" ]]
then
  echo "\nERROR: \$OLY2TA_HOME is not defined or is set to a wrong value !"
  exit 255
fi

if [[ "$AAAHOME" = ""  || ! -x "$AAAHOME/admin/scripts/initaaa.cfg" ]]
then
  echo "\nERROR: \$AAAHOME is not defined or is set to a wrong value !"
  exit 255
fi

. $OLY2TA_HOME/config/Oly2TA$OLY2TA_SITE.cfg
. $OLY2TA_SCRIPT/Oly2TA_Function.fct

SHELLNAME=`basename $0 .sh`

#oly2ta_log_fct "Alert" "DEBUG" "OLY2TA_ALERT_GRP_BOUND_SEC : $OLY2TA_ALERT_GRP_BOUND_SEC"
OLY2TA_ALERT_LOOP_SEC=${OLY2TA_ALERT_LOOP_SEC:-20}
OLY2TA_ALERT_GRACE_MIN=${OLY2TA_ALERT_GRACE_MIN:-2}
OLY2TA_ALERT_GRP_GRACE_SEC=${OLY2TA_ALERT_GRP_GRACE_SEC:-6}
OLY2TA_ALERT_GRP_BOUND_SEC=${OLY2TA_ALERT_GRP_BOUND_SEC:-3}

############################################################################
#
# Functions
#

#
# Get the daemon status
# Output result: status (RUNNING,STOPPING,STOPPED)
#
oly2ta_get_status() {
  cat $OLY2TA_HOME/.ALERT_STATUS$OLY2TA_SITE
}

#
# Set the daemon status
# Input parameter 1 : status (RUNNING,STOPPING,STOPPED)
#
oly2ta_set_status() {
  echo "$1" > $OLY2TA_HOME/.ALERT_STATUS$OLY2TA_SITE
}

#
# Get the daemon pid
# Output result: pid
#
oly2ta_get_pid() {
  cat $OLY2TA_TMP/.${SHELLNAME}${OLY2TA_SITE}.pid 2> /dev/null
}

#
# Store the daemon pid
#
oly2ta_set_pid() {
  echo "$$" > $OLY2TA_TMP/.${SHELLNAME}${OLY2TA_SITE}.pid
  ret_code=$?
  if [[ $ret_code != 0 ]]
  then
    oly2ta_log_fct "Alert" "ERROR" "Alert deamon could not set pid file $OLY2TA_TMP/.${SHELLNAME}${OLY2TA_SITE}.pid, aborting..."
    exit 255   
  fi
}

#
# Get Mifid reports to send
# Globals:
#   MIFID_REP_DIR
# Arguments:
#   None
# Returns:
#   None
#
mifid_get_rep() {
  for mgrdir in $(ls -d ${MIFID_REP_DIR}/!(AOF)/); do
    ls ${mgrdir}MifidReport*.pdf 2>&-
    ret=$?
    if (( $ret == 2 )); then
      #oly2ta_log_fct "Alert" "DEBUG" "$mgrdir is empty"
      continue
    elif (( $ret > 0 )); then
      oly2ta_log_fct "Alert" "ERROR" "Alert deamon, error while detecting report files"
    fi
  done
}

#
# Get the alert-triggering orders
# Includes a count of orders sent at the same time, to detect "big session" situations
#   - Case 1: Delayed orders
# Globals : OLY2TA_ALERT_GRACE_MIN     : grace delay, in minutes since last modif, after which we consider an order as delayed
#           OLY2TA_ALERT_GRP_BOUND_SEC : interval, in seconds before and after creation_time_d, within which we consider orders 
#                                        as belonging to the same session
#           OLY2TA_ALERT_GRP_GRACE_SEC : nb of seconds added to the grace delay, per each order found in the same session
#
syb_get_orders() {
  CURDATE=`date +%Y%m%d`
  RESFILE=$OLY2TA_TMP/$SHELLNAME.$$.`date +%Y%d%m_%H%M%S`.res
  $SYBASE/$SYBASE_OCS/bin/isql -U$AAAUSER -P$AAAUSERPWD -w300 <<-EOSQL >$RESFILE
use $AAAMAINDB
go
-- DELAYED ORDERS
select "::ORDER::", eo.code, eo.status_e, count(1), convert(varchar(8), eo.last_modif_d, 108)
from   ext_order eo, ext_order cnt
where  eo.code like "AAA${CURDATE}%" and eo.parent_oper_nat_e in (0, 3)
and    cnt.code like "AAA${CURDATE}%" 
and    cnt.creation_time_d >= dateadd(ss, -${OLY2TA_ALERT_GRP_BOUND_SEC}, eo.creation_time_d)
and    cnt.creation_time_d < dateadd(ss, ${OLY2TA_ALERT_GRP_BOUND_SEC} + 1, eo.creation_time_d)
and    eo.status_e in (30, 35, 40)
group by eo.code
having eo.last_modif_d < dateadd(ss, -((60 * ${OLY2TA_ALERT_GRACE_MIN}) + (${OLY2TA_ALERT_GRP_GRACE_SEC} * (count(1)-1))), getdate())
go
EOSQL
  ret=$?
  msgcount=$(grep -c "^Msg " ${RESFILE})
  nawk '/::ORDER::/ {print $2";"$3";"$4";"$5}' ${RESFILE}
  if [[ $msgcount -ne 0 || $ret -ne 0 ]]; then
    oly2ta_log_fct "Alert" "ERROR" "Alert deamon, SQL error detected in orders query"
  else
    rm -f $RESFILE
  fi
}


#
# Check parameters
#
case "$1" in
  DAEMON$OLY2TA_SITE)
    ;;
  RUN|STOP|RESET|STATUS)
    ;;
  HELP|*)
    cat <<-EOT

USAGE: OLY2TA_Alert.sh [ACTION]
Where ACTION is
      RUN : start alert daemon
      STOP : stop alert daemon
      RESET : reset alert daemon status
      STATUS : show alert daemon status
      HELP : display command usage
EOT
    exit 255
    ;;
esac

ACTION=$1

#
# Main
#

# 
# Depending on the ACTION parameter
#
case "$ACTION" in
  STOP)
    oly2ta_set_status "STOPPING"
    oly2ta_log_fct "Alert" "INFO" "Alert daemon, status changed to `oly2ta_get_status`!"
    exit 0
    ;;
  RESET)
    oly2ta_set_status "RESET"
    oly2ta_log_fct "Alert" "INFO" "Alert daemon, status changed to `oly2ta_get_status`!"
    exit 0
    ;;
  STATUS)
    PID=`oly2ta_get_pid`
    nbproc=$(ps -fp $PID 2>/dev/null | grep $0 | grep DAEMON$OLY2TA_SITE | grep -v grep | wc -l | awk '{print $1}')
    if [[ "`oly2ta_get_status`" = "STOPPED" && $nbproc -gt 0 ]]; then
      echo "Alert daemon status : `oly2ta_get_status`, ERROR : $nbproc Alert DAEMON$OLY2TA_SITE running"
    else
      if [[ "`oly2ta_get_status`" != "RESET" && "`oly2ta_get_status`" != "STOPPED" && $nbproc -eq 0 ]]; then
        echo "Alert daemon status : `oly2ta_get_status`, ERROR : alert DAEMON$OLY2TA_SITE process $PID not found"
      else
        echo "Alert daemon status : `oly2ta_get_status`, $nbproc alert DAEMON$OLY2TA_SITE running"
      fi
    fi
    exit 0
    ;;
  RUN)
    #oly2ta_log_fct "Alert" "DEBUG" "OLY2TA_ALERT_GRP_BOUND_SEC : $OLY2TA_ALERT_GRP_BOUND_SEC"
    nohup $OLY2TA_SCRIPT/$(basename $0) DAEMON$OLY2TA_SITE >$OLY2TA_LOG/OLY2TA_Alert.nohup.out 2>&1 &
    exit 0
    ;;
  DAEMON$OLY2TA_SITE)
    PID=`oly2ta_get_pid`
    #oly2ta_log_fct "Alert" "DEBUG" "Alert daemon, pid is $PID"
    if [[ "`oly2ta_get_status`" != "STOPPED" && "`oly2ta_get_status`" != "RESET" && "`oly2ta_get_status`" != "STOPPING" ]]; then
      if [[ $(ps -fp $PID 2>/dev/null | grep $0 | grep -v $$ | grep -v grep | wc -l | awk '{print $1}') -ne 0 ]]; then
        oly2ta_log_fct "Alert" "WARN" "Alert daemon, process is already running, aborting RUN action"
        exit 255
      else
        oly2ta_log_fct "Alert" "ERROR" "Alert daemon, bad status: RESET option must be used!"
        exit 255
      fi
    fi

    if [[ $(ps -fp $PID 2>/dev/null | grep $0 | grep -v $$ | grep -v grep | wc -l | awk '{print $1}') -ne 0 ]]; then
      oly2ta_log_fct "Alert" "WARN" "Alert daemon, process is already running, resetting status to RUNNING"
      oly2ta_set_status "RUNNING"
      exit 255
    fi

    oly2ta_set_pid
    oly2ta_set_status "RUNNING"
    oly2ta_log_fct "Alert" "INFO" "Alert daemon, status changed to `oly2ta_get_status`!"
    oly2ta_log_fct "Alert" "INFO" "Alert daemon, Initializing..."
    oly2ta_log_fct "Alert" "INFO" "Loop delay: $OLY2TA_ALERT_LOOP_SEC sec"

    #oly2ta_log_fct "Alert" "DEBUG" "OLY2TA_ALERT_GRACE_MIN     : $OLY2TA_ALERT_GRACE_MIN"
    #oly2ta_log_fct "Alert" "DEBUG" "OLY2TA_ALERT_GRP_BOUND_SEC : $OLY2TA_ALERT_GRP_BOUND_SEC"
    #oly2ta_log_fct "Alert" "DEBUG" "OLY2TA_ALERT_GRP_GRACE_SEC : $OLY2TA_ALERT_GRP_GRACE_SEC"
    ;;
esac

# Mifid reports activation
if [[ -z $MIFID_REP_DIR || ! -d $MIFID_REP_DIR || ! -r $MIFID_REP_DIR ]]; then
  oly2ta_log_fct "Alert" "ERROR" "Alert deamon: MIFID_REP_DIR not defined or not readable"
  readonly MIFID_ALERT=0
else
  oly2ta_log_fct "Alert" "INFO" "Alert deamon: will send reports from: $MIFID_REP_DIR "
  readonly MIFID_ALERT=1
fi

# Infinite loop
while true; do

  case "`oly2ta_get_status`" in
  STOPPING)
    #oly2ta_log_fct "Alert" "DEBUG" "STOPPING detected"
    /usr/bin/rm -f $OLY2TA_TMP/.${SHELLNAME}${OLY2TA_SITE}.pid
    #oly2ta_log_fct "Alert" "DEBUG" "break"
    break
    ;;
  esac

  if [[ "`oly2ta_get_pid`" = "" ]]
  then 
    oly2ta_log_fct "Alert" "ERROR" "Alert daemon, pid could not be found in $OLY2TA_TMP/.${SHELLNAME}${OLY2TA_SITE}.pid, aborting..."
    oly2ta_set_status "STOPPED"
    break
  fi

  # Order status alerts
  for order in $(syb_get_orders); do
    order_code=$(echo $order | cut -d\; -f1)
    status_e=$(echo $order | cut -d\; -f2)
    grp_count=$(echo $order | cut -d\; -f3)
    last_modif=$(echo $order | cut -d\; -f4)

    #oly2ta_log_fct "Alert" "DEBUG" "order_code:$order_code status_e:$status_e grp_count:$grp_count last_modif:$last_modif"

    retfile=$OLY2TA_TMP/.Oly2TA_Alert_Order_Status.$order_code.$status_e.ret
    if [[ -s $retfile && "`cat $retfile`" == 0 ]]; then
      oly2ta_log_fct "Alert" "INFO " "Alert daemon, alert for order $order_code in status $status_e was already sent"
      continue
    fi
    oly2ta_log_fct "Alert" "INFO" "Alert daemon, detected order $order_code in status $status_e last modified at $last_modif"
    if (( $grp_count > 1 ));then
      oly2ta_log_fct "Alert" "INFO" "Alert daemon, sending alert for order $order_code exceeding the extended delay of $OLY2TA_ALERT_GRACE_MIN min + $(( ${OLY2TA_ALERT_GRP_GRACE_SEC} * (${grp_count} - 1) )) sec for the $grp_count simultaneous orders "
    else
      oly2ta_log_fct "Alert" "INFO" "Alert daemon, sending alert for order $order_code exceeding the delay of $OLY2TA_ALERT_GRACE_MIN min "
    fi
    $OLY2TA_SCRIPT/Oly2TA_Alert_Order_Status.sh $order_code $status_e ORDER_DELAY >$retfile
  done

  sleep $OLY2TA_ALERT_LOOP_SEC
  #oly2ta_log_fct "Alert" "DEBUG" "Alert daemon, looping..."

  # Mifid reports
  if (( $MIFID_ALERT == 1 )); then
    for rep_file in $(mifid_get_rep); do
      oly2ta_log_fct "Alert" "INFO" "Alert daemon, found: $rep_file"
      local input_user_root=$(echo $rep_file | sed "s,^${MIFID_REP_DIR}/*,,")
      local input_user=${input_user_root%%/*}
      local ptf_code=$(basename $rep_file | cut -d_ -f2)
      $OLY2TA_SCRIPT/Oly2TA_Alert_Mifid_Report.sh $input_user $ptf_code $rep_file
      ret=$?
      if (( $ret != 0 )); then
	oly2ta_log_fct "Alert" "ERROR" "Oly2TA_Alert_Mifid_Report.sh returned error: $ret"
      fi
    done
  fi

done
#
# Exiting
#
#oly2ta_log_fct "Alert" "DEBUG" "In Exit routine"
oly2ta_set_status "STOPPED"
oly2ta_log_fct "Alert" "INFO" "Alert daemon, Exiting..."
exit 0
