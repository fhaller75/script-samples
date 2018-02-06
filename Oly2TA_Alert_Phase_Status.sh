#!/usr/bin/ksh
###########################################################################
#
# Raise an alert based on the status of a batch phase
#
# Parameters	:	phase
#                       status
#                       level
# Prerequisites	:	$OLY2TA_HOME must be defined
#
###########################################################################
#
# Versions:
# 03/11/2015 - FHA/Umea : Creation
#
###########################################################################

#
# Check parameters
#
if [ "$OLY2TA_HOME" = ""  -o ! -x "$OLY2TA_HOME/config/Oly2TA$OLY2TA_SITE.cfg" ]
then
	echo "\nERROR: \$OLY2TA_HOME is not defined or is set to a wrong value !" 
	exit 255
fi

if [ "$AAAHOME" = ""  -o ! -x "$AAAHOME/admin/scripts/initaaa.cfg" ]
then
	echo "\nERROR: \$AAAHOME is not defined or is set to a wrong value !" 
	exit 255
fi

if [ $# -ne 3 ]
then
	echo "\nUSAGE: $0 status phase level"
	exit 255
fi

#
# Initialization
#
STATUS=$1
PHASE=$2
LEVEL=$3

. $OLY2TA_HOME/config/Oly2TA$OLY2TA_SITE.cfg
. $OLY2TA_SCRIPT/Oly2TA_Function.fct
. $AAAHOME/admin/scripts/initaaa.cfg

SHELLNAME=$(basename $0 .sh)
totalret=0

# Debug mode: 0=OFF / 1=ON
if [ "$DEBUG" == "" ]; then
   export DEBUG=0
fi

DATAFILE=$OLY2TA_TMP/$SHELLNAME.$$.dat
BODYFILE=$OLY2TA_TMP/$SHELLNAME.$$.body

#
# Main
#
oly2ta_log_fct "Alert" "INFO" "Start alert processing for phase $PHASE $STATUS status"

case $STATUS in
  Delay|Ended)
    ALERT_TYPE=PHASE_STATUS
    ;;
  *)
    oly2ta_log_fct "Alert" "ERROR" " Status $STATUS unknown, alert type could not be determined"
    exit 255;;
esac

oly2ta_log_fct "Alert" "INFO" "  Extract alert data"
echo "::FIELD::phase::DATA::${PHASE}" >>$DATAFILE
echo "::FIELD::status::DATA::${STATUS}" >>$DATAFILE
echo "::FIELD::level::DATA::${LEVEL}" >>$DATAFILE
echo "::FIELD::alert_datetime::DATA::"$(date +"%d/%m/%Y %H:%M:%S") >>$DATAFILE

if [[ $DEBUG -gt 1 ]]; then
  DB2OPTIONS="$DB2OPTIONS -v"
fi
db2 -td\; <<EOT | grep '::FIELD::' | sed 's/ *$//' >>$DATAFILE
connect to $OLY2TA_DB2_SERVER user $OLY2TA_DB2_USER using $OLY2TA_DB2_PASSWD;

select CONCAT('::FIELD::business_date::DATA::',
       TO_CHAR(TO_DATE(TAAIY8, 'YYYYMMDD'), 'DD/MM/YYYY'))
from   ${OLY2TA_TAPARM} 
where  TACODE = 'DATE' AND TAID = '002';

select CONCAT('::FIELD::flag_datetime::DATA::',
       TO_CHAR(TIME_STAMP, 'DD/MM/YYYY HH24:MI:SS'))
from   ${FLAGTBL}
where  TIME_STAMP=(select max(TIME_STAMP) from ${FLAGTBL});

quit;
EOT
let totalret+=$?

if [[ -s $DATAFILE ]]; then
  oly2ta_log_fct "Alert" "INFO" "  Build mail content for phase $PHASE $STATUS status"
  ${OLY2TA_SCRIPT}/Oly2TA_Alert_Layout.sh $DATAFILE $ALERT_TYPE > $BODYFILE 2>&1
  let totalret+=$?
else
  oly2ta_log_fct "Alert" "ERROR" " Alert data file $DATAFILE empty for phase $PHASE $STATUS status"
  totalret=255
fi

if [[ -s $BODYFILE ]]; then
  oly2ta_log_fct "Alert" "INFO" "  Send mail for phase $PHASE $STATUS status"
  ${OLY2TA_SCRIPT}/Oly2TA_Send_Mail.sh $BODYFILE $ALERT_TYPE
  let totalret+=$?
else
  oly2ta_log_fct "Alert" "ERROR" " Mail body file $BODYFILE empty for phase $PHASE $STATUS status"
  totalret=255
fi

#
# Exit
#
oly2ta_log_fct "Alert" "INFO" "End of alert processing on phase $PHASE $STATUS status with code $totalret"

retrc=$(cat $DATAFILE | grep "Msg")
if [[ $totalret -eq 0 && "$retrc" == "" && $DEBUG -eq 0 ]];then
  rm -f $DATAFILE $BODYFILE
fi

# Feedback return code to WTX map
#echo $totalret

exit $totalret

