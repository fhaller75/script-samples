#!/bin/ksh 
###########################################################################
#
# Send alert mail on toi events
#
# Parameters	:	$1: mail body file path
# 			$2: alert type
# Prerequisites	:	$OLY2TA_HOME must be defined
#                       $AAAHOME must be defined
#
###########################################################################
#
# Created	: 	FHA/Umea - 01/04/2015
# Major versions:
# 01/04/2015 - FHA/Umea : Creation as Oly2TA_Mail
# 02/10/2015 - FHA/Umea : Modify as Oly2TA_Send_Mail: use sendmail and
#                         other improvements
# 15/12/2017 - FHA/Umea : Add attachment for Mifid reports
#
###########################################################################

#
# Check parameters
#
if [ "$OLY2TA_HOME" = ""  -o ! -x "$OLY2TA_HOME/config/Oly2TA$OLY2TA_SITE.cfg" ]; then
  echo "\nERROR: \$OLY2TA_HOME is not defined or is set to a wrong value !" 
  exit 255
fi

if [ "$AAAHOME" = ""  -o ! -x "$AAAHOME/admin/scripts/initaaa.cfg" ]; then
  echo "\nERROR: \$OLY2TA_HOME is not defined or is set to a wrong value !"
  exit 255
fi

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "\nUSAGE: $0 body_file alert_type [attachment]"
  echo "where:"
  echo "    body_file  : file containing the mail body"
  echo "    alert_type : type of alert, defined as a section in Oly2TA_Email.ini"
  echo "    attachment : mail attachment file (optional)"
  exit 255
fi

#
# Initialization
#
readonly BODY_FILE=$1
readonly ALERT_TYPE=$2
readonly ATTACHMENT=$3

. $OLY2TA_HOME/config/Oly2TA$OLY2TA_SITE.cfg
. $OLY2TA_SCRIPT/Oly2TA_Function.fct
. $AAAHOME/admin/scripts/initaaa.cfg

SHELLNAME=$(basename $0 .sh)
totalret=0

if [[ -r /etc/application ]]; then
  ENV=$(cat /etc/application | tr 'a-z' 'A-Z')
else
  ENV=$(echo $AAAENV | tr 'a-z' 'A-Z')
fi

# Debug mode: 0=OFF / 1=ON
DEBUG=${DEBUG:-0}

# Temp files
TMPFILE1=${OLY2TA_TMP}/${SHELLNAME}.$$.tmp1
TMPFILE2=${OLY2TA_TMP}/${SHELLNAME}.$$.tmp2
TMPFILE3=${OLY2TA_TMP}/${SHELLNAME}.$$.tmp3

#
# Main
#
oly2ta_log_fct "Mail" "INFO" "Start email process $$"

# Check body file
if [[ ! -r $BODY_FILE ]]; then
  oly2ta_log_fct "Mail" "FATAL" "Mail body file $BODY_FILE cannot be read, aborting"
  exit 255
fi
# Check attachment file
if [[ ! -z $ATTACHMENT && ! -r $ATTACHMENT ]]; then
  oly2ta_log_fct "Mail" "FATAL" "Mail body file $BODY_FILE cannot be read, aborting"
  exit 255
fi

# Get recipients from ini file and add to mail header
MAILTO=$(${OLY2TA_SCRIPT}/read_ini_file.sh $OLY2TA_CONFIG/Oly2TA_Email.ini $ALERT_TYPE MAILTO)
ret=$?; (( totalret += $ret ))
if [[ "$MAILTO" = "" ]]; then
  oly2ta_log_fct "Mail" "ERROR" "MAILTO not found for alert type $ALERT_TYPE"
  exit 255
fi
sed "s/^To:.*/&,$MAILTO/" $BODY_FILE >$TMPFILE1
ret=$?; (( totalret += $ret ))
if (( $ret == 0 )); then
  cat $TMPFILE1 >$BODY_FILE
  ret=$?; (( totalret += $ret ))
fi

MAILCC=$(${OLY2TA_SCRIPT}/read_ini_file.sh $OLY2TA_CONFIG/Oly2TA_Email.ini $ALERT_TYPE MAILCC)
ret=$?; (( totalret += $ret ))
if [[ "$MAILCC" = "" ]]; then
  oly2ta_log_fct "Mail" "WARN" "  MAILCC not found for alert type $ALERT_TYPE"
else
  sed "s/^Cc:.*/&,$MAILCC/" $BODY_FILE >$TMPFILE2
  ret=$?; (( totalret += $ret ))
  if (( $ret == 0 )); then
    cat $TMPFILE2 >$BODY_FILE
    ret=$?; (( totalret += $ret ))
  fi
fi

# Add secure:t in subject if sent outside
outside=$(nawk '
/^To|^Cc:|^Bcc/ {sub(/^.*:/, "", $0); mailstr=","mailstr $0;}

function secure_t() {
  # split addresses into an array
  split(mailstr, mails, /[,;]/);
  outside=0
  for (i in mails) {
    # Reduce to domain
    if (mails[i] ~ /@/) {
      sub(/^.*@/, "", mails[i]);
      # Detect if outside of bhimail.lu/ch
      if (mails[i] !~ /bhimail\.(lu|ch) *$/) {
        outside=1;
      }
    }
  }
  print outside;
}

END {
  secure_t();
}' $BODY_FILE)
ret=$?; (( totalret += $ret ))
if (( $ret != 0 )); then
  oly2ta_log_fct "Mail" "ERROR" " Failure while checking external email addresses"
fi
if (( $outside == 1 )); then
  sed "s/^Subject:/&secure:t : /" $BODY_FILE >$TMPFILE3
  ret=$?; (( totalret += $ret ))
  if (( $ret == 0 )); then
    cat $TMPFILE3 >$BODY_FILE
    ret=$?; (( totalret += $ret ))
  fi
fi

# If not Prod env, do not send to recipients in the message header fields
if [[ "$ENV" != PROD* ]]; then
  MAIL_CMD="sendmail"
else
  MAIL_CMD="sendmail -t"
fi

if [[ $DEBUG -gt 0 ]]; then
  MAIL_CMD="$MAIL_CMD -v"
fi

# Add attachment and cloase boundary
boundary=$(grep "^\--::BOUNDARY::" $BODY_FILE | head -1)
if [[ ! -z $ATTACHMENT ]]; then
  ATTACH_NAME=$(basename $ATTACHMENT)
  ATTACH_EXT=${ATTACH_NAME##*.}
  echo "${boundary}" >>$BODY_FILE
  echo "Content-Type: application/${ATTACH_EXT}; name=\"${ATTACH_NAME}\""  >>$BODY_FILE
  echo "Content-Transfer-Encoding: base64" >>$BODY_FILE
  echo "Content-Disposition: attachment; filename=\"${ATTACH_NAME}\"" >>$BODY_FILE
  uuencode -m $ATTACHMENT $ATTACH_NAME >>$BODY_FILE
fi
echo "${boundary}--" >>$BODY_FILE

# Log and send mail
oly2ta_log_fct "Mail" "INFO" "  Mail command: $MAIL_CMD \"${MAILTO}\" <${BODY_FILE}"
oly2ta_log_fct "Mail" "INFO" "    $(grep "^To:" ${BODY_FILE})"
oly2ta_log_fct "Mail" "INFO" "    $(grep "^Cc:" ${BODY_FILE})"
oly2ta_log_fct "Mail" "INFO" "    $(grep "^Bcc:" ${BODY_FILE})"
oly2ta_log_fct "Mail" "INFO" "    $(grep "^Subject:" ${BODY_FILE})"

$MAIL_CMD -F "Triple'A $ENV Notification - do not reply" "${MAILTO}" <${BODY_FILE}
ret=$?; (( totalret += $ret ))
if [ $ret -eq 0 ]; then
  oly2ta_log_fct "Mail" "INFO" "  Mail sent successfully"
else
  oly2ta_log_fct "Mail" "ERROR" " Mail sent with error $ret"
fi

#
# Exit
#
oly2ta_log_fct "Mail" "INFO" "End of email process $$"

if [[ $totalret -eq 0 && $DEBUG -eq 0 ]];then
  rm -f ${OLY2TA_TMP}/${SHELLNAME}.$$.*
fi

exit $totalret

