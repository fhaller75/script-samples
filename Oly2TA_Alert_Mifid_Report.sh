#!/usr/bin/ksh
###########################################################################
#
# Send Mifid reports to managers upon creation
#
# Parameters	: input_user
#                 portfolio_code
#                 report_file
# Prerequisites	: $OLY2TA_HOME must be defined
#                 OLY2TA_HOME must be defined
#
###########################################################################
#
# Versions:
# 14/12/2017 - FHA/Umea : Creation
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

if (( $# != 3 )); then
  echo "\nUSAGE: $0 input_user portfolio_code report_file"
  exit 255
fi

#
# Initialization
#
readonly INPUT_USER=$1
readonly PTF_CODE=$2
readonly REP_FILE=$3

. $OLY2TA_HOME/config/Oly2TA$OLY2TA_SITE.cfg
. $OLY2TA_SCRIPT/Oly2TA_Function.fct
. $AAAHOME/admin/scripts/initaaa.cfg

SHELLNAME=$(basename $0 .sh)
totalret=0

# Debug mode: 0=OFF / 1=ON / >1=SQL_ON
DEBUG=${DEBUG:-0}

oly2ta_log_fct "Alert" "INFO" "Start alert processing for portfolio $PTF_CODE with Mifid report $REP_FILE "
#
# Additional checks
#
if [[ ! -r $REP_FILE ]]; then
  oly2ta_log_fct "Alert" "FATAL" "Report file $REP_FILE cannot be read"
  exit 255
fi

if [[ -z $MIFID_REP_DIR || ! -d $MIFID_REP_DIR ]]; then
  oly2ta_log_fct "Alert" "FATAL" "Report directory not defined or incorrect: $MIFID_REP_DIR "
  exit 255
fi

#
# Temp files/dir
#
DATA_FILE=$OLY2TA_TMP/$SHELLNAME.$$.dat
BODY_FILE=$OLY2TA_TMP/$SHELLNAME.$$.body

readonly REP_PROC_DIR=${MIFID_REP_DIR}/${INPUT_USER}/_processing
readonly REP_SENT_DIR=${MIFID_REP_DIR}/${INPUT_USER}/_sent
readonly REP_ERR_DIR=${MIFID_REP_DIR}/${INPUT_USER}/_in_error
for subdirpath in $REP_PROC_DIR $REP_SENT_DIR $REP_ERR_DIR ;do
  if [[ ! -d ${subdirpath} ]]; then
    mkdir -p ${subdirpath}
    ret=$?
    if (( $ret != 0 )); then
      oly2ta_log_fct "Alert" "FATAL" "Sub-directory $subdirpath creation error code: $ret "
      exit 255
    fi
  fi
  if [[ ! -w $subdirpath || ! -x $subdirpath ]]; then
    oly2ta_log_fct "Alert" "FATAL" "Sub-directory $subdirpath not writable "
    exit 255
  fi
done

#
# Main
#
readonly ALERT_TYPE=MIFID_REPORT
readonly REP_NAME=$(basename ${REP_FILE})
mv $REP_FILE $REP_PROC_DIR/$REP_NAME
ret=$?
if (( $ret != 0 )); then
  oly2ta_log_fct "Alert" "FATAL" "Error $ret when moving $REP_FILE to $REP_PROC_DIR "
  exit 255
fi

oly2ta_log_fct "Alert" "INFO" "  Run Mifid alert query on portfolio $PTF_CODE "
if [[ $DEBUG -gt 1 ]]; then
  ISQL_ECHO=" -e"
fi
isql -U${AAAUSER} -P${AAAUSERPWD} -w1000 -b ${ISQL_ECHO} <<-EOT >$DATA_FILE 2>&1
set nocount on
go
use aaamaindb
go
set rowcount 1
go

select char(10)

-- Main fields
|| '::FIELD::portfolio::DATA::' ||
    p.code
    + char(10)

-- Managers
|| '::FIELD::mgr_email::DATA::' ||
    (select m.e_mail_address_c from manager m
     where  code = "$INPUT_USER")
    + char(10)
|| '::FIELD::mgr_denom::DATA::' ||
    (select m.denom from manager m
     where  code = "$INPUT_USER")
    + char(10)
|| '::FIELD::rm_email::DATA::' ||
    rm.e_mail_address_c
    + char(10)

from   portfolio p, manager rm
where  p.code = "$PTF_CODE"
and    p.admin_mgr_id *= rm.id
go

EOT
let totalret+=$?

if [[ ! -s $DATA_FILE ]]; then
  oly2ta_log_fct "Alert" "ERROR" " Alert data file $DATA_FILE empty for portfolio $PTF_CODE "
  totalret=255
else
  oly2ta_log_fct "Alert" "INFO" "  Build mail content for $PTF_CODE $ALERT_TYPE"
  ${OLY2TA_SCRIPT}/Oly2TA_Alert_Layout.sh $DATA_FILE $ALERT_TYPE >$BODY_FILE 2>&1
  let totalret+=$?

  if [[ ! -s $BODY_FILE ]]; then
    oly2ta_log_fct "Alert" "ERROR" " Mail body file $BODY_FILE empty for portfolio $PTF_CODE"
    totalret=255
  else
    oly2ta_log_fct "Alert" "INFO" "  Send alert mail for $PTF_CODE $ALERT_TYPE"
    ${OLY2TA_SCRIPT}/Oly2TA_Send_Mail.sh $BODY_FILE $ALERT_TYPE $REP_PROC_DIR/$REP_NAME
    ret=$?
    let totalret+=$?
    if (( $ret == 0 )); then
      mv $REP_PROC_DIR/$REP_NAME $REP_SENT_DIR/.
      ((totalret += $?))
    else
      mv $REP_PROC_DIR/$REP_NAME $REP_ERR_DIR/.
      ((totalret += $?))
    fi
  fi
fi

#
# Exit
#
oly2ta_log_fct "Alert" "INFO" "End of alert processing on portfolio $PTF_CODE "

retrc=$(cat $DATA_FILE | grep "Msg")
if [[ $totalret -eq 0 && "$retrc" == "" && $DEBUG -eq 0 ]];then
  rm -f $DATA_FILE $BODY_FILE
fi

# Feedback return code to WTX map
#echo $totalret

exit $totalret

