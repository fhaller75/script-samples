#!/bin/ksh
###########################################################################
#
# As part of the Mifid2 migration:
# Script to create the parent/child relationship between the new -02x portfolios
# and the previous -000 portfolios in order to merge the operations history
# for the 2017 reports.
# Should:
#   - detect target portfolios based on Olympic's specific other numbering 360
#   - create parent/child link from new to previous ptfs
#   - break the parent/child link from -000 to -307 and -9 ptfs if any
#
# Parameters    : None
#
# Prerequisites : $OLY2TA_HOME must be defined
#
###########################################################################
#
# Author        : F.Haller/Umea
#
# Major Versions
# 10/08/2017    : Creation
#
###########################################################################

#
# Check parameters
#
if [ -z "$OLY2TA_HOME" ]; then
  echo "ERROR : OLY2TA_HOME environment variable must be defined, aborting."
  exit 255
fi

#
# Initializations
#
. $OLY2TA_HOME/config/Oly2TA$OLY2TA_SITE.cfg
. $OLY2TA_SCRIPT/Oly2TA_Function.fct

totalret=0

#
# Globals
#
readonly SCRIPT_NAME=$(basename $0 .sh)
readonly SQL_CMD="${SYBASE}/${SYBASE_OCS}/bin/isql -U$AAAUSER -P$AAAUSERPWD -S$DSQUERY -w2000"
readonly CURRENTDATE="`oly2ta_getdate_fct`"
if [[ ! -z $OLY2TA_SITE ]]; then
  readonly PREFIX=${OLY2TA_SITE#*_}_
fi

dt=$(date +%Y%m%d)

# Tempfiles
readonly TMP_FILE_1=${OLY2TA_TMP}/${SCRIPT_NAME}.$$.tmp1

###################################################################
#  Functions
###################################################################
#
# Get Oly2TA Import daemon status
# Output result: Import status (RUNNING,SUSPEND,STOPPED,RESUME)
#
oly2ta_get_status() {
  cat $OLY2TA_HOME/.IMPORT_STATUS$OLY2TA_SITE
}
###################################################################

#
# Main
#
oly2ta_log_fct "Batch" "INFO" "Start of $0"
###################################################################
#  Run db2 query select FDBNUM
###################################################################
db2 connect to $OLY2TA_DB2_SERVER user $OLY2TA_DB2_USER using $OLY2TA_DB2_PASSWD >/dev/null
ret=$?
((totalret+=$ret))
if (( $ret == 0 )); then
  echo "db2 connection successfull."
else
  echo "Problem with db2 connection!! Please check credentials. "
  oly2ta_log_fct "Batch" "FATAL" "  db2 connection error: $ret"
  exit 255
fi

db2 +p -x "
  SELECT '::DATA::'
       , NURACI
       , NUGRE
       , LPAD(TRIM(LEFT(TRIM(NUREFE), 7)), 7, '0')
    FROM ${OLY2TA_OLYLIB}FDBNUM
   WHERE NUETAT = ''
     AND NUTYPE='360'
   ORDER BY NURACI
" >${OLY2TA_TMP}/Mifid2_FDBNUM360_$dt.dat 2>${OLY2TA_TMP}/Mifid2_FDBNUM360_$dt.err
ret=$?
((totalret+=$ret))
if [[ $ret -eq 0 || $ret -eq 1 ]]; then
  echo "Data fetched in ${OLY2TA_TMP}/Mifid2_FDBNUM360_$dt.dat file."
  rm -f ${OLY2TA_TMP}/Mifid2_FDBNUM360_$dt.err
else
  echo "Problem with select statement:"
  cat ${OLY2TA_TMP}/Mifid2_FDBNUM360_$dt.err
  oly2ta_log_fct "Batch" "FATAL" "  db2 select statement error: $ret. Please check ${OLY2TA_TMP}/Mifid2_FDBNUM360_$dt.err"
  exit 255
fi

###################################################################
# Format output data to create the import file
###################################################################
cat <<-EOT > ${OLY2TA_TMP}/Mifid2_parent_ptf_$dt.imp
SET DATEFORMAT DD-MM-YYYY
SET DATAFORMAT DELIMITED
SET SEPARATOR ;
SET THOUSAND ,
CMD UPDATE portfolio
ATT code parent_port_id.code acc_plan active_f comm_mgr archive_d autocreated_f bal_pos_rule_set book_pre_adj_f book_val_rule cash_adj_f admin_mgr curr_conv_d curr_lend_val_rule currency DISCARD denom DISCARD DISCARD DISCARD DISCARD DISCARD DISCARD instr_lend_val_rule language lock_type ud_manag_type mgt_begin_d mgt_end_d name nature_e old_currency DISCARD DISCARD DISCARD DISCARD DISCARD pl_rule port_set_f DISCARD quote_val_rule DISCARD ret_freq_n DISCARD ret_risk_f synth_arch_d tax_convention tax_status_e third type ud_agent_third ud_begin_d ud_center_third ud_default_account.code ud_end_d ud_eu_fisc_res_gb_f ud_eu_fiscal_country ud_eu_information_exchange_f ud_eu_tax_f ud_first_name ud_gera3_manager ud_gera_grp_third ud_mgt_resp_e ud_nati1_geo ud_nati2_geo ud_nati3_geo ud_nati4_geo ud_nati_geo ud_profile_type ud_qi_f ud_resid1_geo ud_resid2_geo ud_resid3_geo ud_resid4_geo ud_resid_geo ud_risk_geo ud_risk_type ud_short_name ud_status_e
EOT
ret=$?
((totalret+=$ret))

att_count=$(awk '/^ATT / {print NF-1}' ${OLY2TA_TMP}/Mifid2_parent_ptf_$dt.imp)
awk -v OFS=";" -v att_count=$att_count '/::DATA::/ {
  att_keep="";
  for (i=1; i<=att_count-2; i++)
    att_keep="KEEP;" att_keep;
  print "DAT L"$4"-000", "L"$2"-"$3, att_keep;
}' ${OLY2TA_TMP}/Mifid2_FDBNUM360_$dt.dat >>${OLY2TA_TMP}/Mifid2_parent_ptf_$dt.imp
ret=$?
((totalret+=$ret))
if (( $ret != 0 )); then
  echo "Problem with import file formating:"
  cat ${OLY2TA_TMP}/Mifid2_parent_ptf_$dt.imp
  oly2ta_log_fct "Batch" "FATAL" "  import file formating error: $ret. Please check ${OLY2TA_TMP}/Mifid2_parent_ptf_$dt.imp"
  exit 255
fi
echo "Created imp file ${OLY2TA_TMP}/Mifid2_parent_ptf_$dt.imp"
dat_count=$(grep -c "^DAT " ${OLY2TA_TMP}/Mifid2_parent_ptf_$dt.imp)
oly2ta_log_fct "Batch" "INFO" "  Found $dat_count portfolio(s) to update"

###################################################################
# Run import
###################################################################
# Put import in folder where import DAEMON is looking
oly2ta_log_fct "Batch" "INFO" "  Sending Mifid2_parent_ptf_$dt.imp to import"
mv ${OLY2TA_TMP}/Mifid2_parent_ptf_$dt.imp $OLY2TA_IMPORT/${PREFIX}${CURRENTDATE}.Mifid2_parent_ptf_$dt.imp
ret=$?
((totalret+=$ret))
if [ "`oly2ta_get_status`" != "RUNNING" ]
then 
  $OLY2TA_SCRIPT/Oly2TA_Import_File.sh ${PREFIX}${CURRENTDATE}.Mifid2_parent_ptf_$dt.imp
  ret=$?
  ((totalret+=$ret))
  if (( $ret != 0 )); then
    echo "Problem while importing file: ${PREFIX}${CURRENTDATE}.Mifid2_parent_ptf_$dt.imp"
    oly2ta_log_fct "Import" "ERROR" "Unable to import file: ${PREFIX}${CURRENTDATE}.Mifid2_parent_ptf_$dt.imp"
  fi	
fi

###################################################################
# Delete old links
###################################################################
$SQL_CMD <<-EOT >$TMP_FILE_1
use $AAAMAINDB
go
UPDATE portfolio
   SET ocp.parent_port_id = NULL
  FROM portfolio ocp
       JOIN portfolio cp
         ON cp.id = ocp.parent_port_id
       JOIN portfolio pp
         ON pp.id = cp.parent_port_id
 WHERE pp.code like "L_______-02[3-7]"
   AND cp.code like "L_______-000"
go
EOT
ret=$?
((totalret+=$ret))
retmsg=$(grep -c "Msg" $TMP_FILE_1)
((totalret+=$retmsg))
if [[ $ret -ne 0 || $retmsg -ne 0 ]]; then
  echo "DEBUG: delete old links SQL_CMD ret:$ret retmsg:$retmsg" >&2
  cat $TMP_FILE_1 >&2
  oly2ta_log_fct "Batch" "ERROR" "  When deleting old links:\n$(cat $TMP_FILE_1)"
fi
row_count=$(awk '/affected/ {sub(/\(/, ""); printf("%d",$1)}' $TMP_FILE_1)
oly2ta_log_fct "Batch" "INFO" "  Deleted $row_count old parent/child link(s)"

################################################################################
# Cleanup and Exit
#
if (( $totalret == 0 )); then
  rm -f ${OLY2TA_TMP}/${SCRIPT_NAME}*.$$.* $TMP_FILE_1
  rm -f ${OLY2TA_TMP}/Mifid2_FDBNUM360_$dt.dat
fi

oly2ta_log_fct "Batch" "INFO" "End of $0 with code $totalret"
exit $totalret

