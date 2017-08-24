#!/bin/ksh
################################################################################
#
# Script to copy the historical performance from the previous -000 portfolios
# onto the new -02x portfolios as part of the Mifid2 migration.
# Should:
#   - detect target portfolios based on code, parent code and existing chronos
#   - copy required chronos and notepads (tbd) into the new ptfs
#   - create a new chrono with TWR at migration date
#
# Parameters    : None
#
# Prerequisites : $OLY2TA_HOME must be defined
#
################################################################################
#
# Author        : F.Haller/Umea
#
# Major Versions
# 09/08/2017    : Creation
#
################################################################################

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
readonly RUNDATE=$(date +%d/%m/%Y)
if [[ ! -z $OLY2TA_SITE ]]; then
  readonly PREFIX=${OLY2TA_SITE#*_}_
fi

# Tempfiles
readonly PTF_LIST_FILE=${OLY2TA_TMP}/${SCRIPT_NAME}.$$.ptf_list

################################################################################
# Functions
################################################################################
#
# Get list of portfolios to migrate
# Globals:
#   SQL_CMD
#   AAAMAINDB
#   OLY2TA_TMP
#   SCRIPT_NAME
# Arguments:
#   None
# Outputs:
#   one line per parent/child ptf pair, with line format child_code;parent_code
# Returns:
#   func_ret : error code
#
get_ptf_list() {
  #set -x
  local ret
  local func_ret=0
  local readonly TMP_FILE_1=${OLY2TA_TMP}/${SCRIPT_NAME}.get_ptf_list.$$.tmp1
  $SQL_CMD <<-EOT >$TMP_FILE_1
use $AAAMAINDB
go
select "::DATA::", cp.code, pp.code
from    portfolio cp, portfolio pp
where   pp.id = cp.parent_port_id
and     pp.active_f = 1
and     pp.code like "L_______-02[3-7]"
and     cp.code like "L_______-000"
and not exists (select 'X' from port_chrono ch
                where  ch.portfolio_id = pp.id
                and    ch.nature_e = 104 /* Migrated perf */)
go
EOT
  ret=$?
  ((func_ret+=$ret))
  retmsg=$(grep -c "Msg" $TMP_FILE_1)
  ((func_ret+=$retmsg))
  if [[ $ret -ne 0 || $retmsg -ne 0 ]]; then
    echo "DEBUG: get_ptf_list SQL_CMD ret:$ret retmsg:$retmsg" >&2
    cat $TMP_FILE_1 >&2
    oly2ta_log_fct "Batch" "ERROR" "  When getting portfolios to process:\n$(cat $TMP_FILE_1)"
  fi

  awk '/::DATA::/ {print $2";"$3}' $TMP_FILE_1
  ret=$?
  ((func_ret+=$ret))

  return $func_ret
}

#
# Get DAT line of the migrated perf chrono for one ptf
# Globals:
#   SQL_CMD
#   AAAMAINDB
#   AAAREPDB
#   OLY2TA_TMP
#   SCRIPT_NAME
# Arguments:
#   $1: src_ptf
#   $2: target_ptf
# Outputs:
#   port_chrono DAT line
# Returns:
#   func_ret : error code
#
get_mig_perf_line() {
  #set -x
  local src_ptf=$1
  local target_ptf=$2
  local ret
  local func_ret=0
  local readonly TMP_FILE_1=${OLY2TA_TMP}/${SCRIPT_NAME}.get_mig_perf_line_${src_ptf}.$$.tmp1
  local readonly TMP_FILE_2=${OLY2TA_TMP}/${SCRIPT_NAME}.get_mig_perf_line_${src_ptf}.$$.tmp2
  $SQL_CMD <<-EOT >$TMP_FILE_1
use $AAAMAINDB
go
set nocount on
set dateformat dmy
declare @return_status int_t
declare @ptf_curr code_t

select @ptf_curr=c.code
from   portfolio p, currency c
where  p.currency_id = c.id
and    p.code = "$target_ptf"

exec @return_status = exec_fin_analysis_all_domain
@output_type_e=3,
@function="return",
@dim_port='portfolio',
-- @dim_entity='one',
-- @dim_entity='portfolio',
@port_object="$src_ptf",
-- @dim_instr=NULL,
-- @instr_object=NULL,
@calc_from_d="31/12/2016",
@calc_ref_d="$RUNDATE",
@calc_till_d="$RUNDATE",
@currency=@ptf_curr,
@format="ABN_PERFO_SYS",
@comp_data_e=0,         /*On-line*/
-- @def_curr_f=0,
-- @default_f=0,
-- @check_trading_f=1,
-- @disp_result_f=0,    /*Yes*/
-- @dynamic_weight_f=0, /*No*/
@port_cons_rule_e=2,    /*Detailed*/
-- @strat_link_nat_e=0, /*All Link Nature*/
-- @min_link_priority_n=NULL,
-- @max_link_priority_n=NULL,
@min_status_e=40,       /*Accounted*/
@max_status_e=40,       /*Accounted*/
@language="en",
@ret_det_level_e=0,     /*Global*/
@zero_qty_f=0,          /*Excl.Zero Pos*/
@status_fus_f=0,
-- @def_fusion_date_rule_f=1,
-- @return_fct_f=0,
@close_pos_f=0,         /*Keep Positions*/
@debt_f=0,              /*Exclude Debts */
@load_hierarchy_f=1,    /*No Hierarchy*/
@load_pos_f=0,          /*Include Pos*/
-- @fus_sub_nat_f=0,    /*Keep Sub-Pos*/
@load_non_discret_f=1,  /*Non-Discretionary included*/
@fund_split_rule_e=0,   /*<None>*/
@fund_split_level_e=0,  /*<None>*/
-- @non_enum_instr_f=0,
-- @risk_exp_f=0,       /*Accounting View*/
-- @option_risk_rule_e=0,/*<None>*/
-- @pos_logical_rule_e=1
-- @fusion_date_rule_e=1,/*<None>*/
@val_rule_param="",
-- @quote_val_rule=NULL,
-- @exch_val_rule=NULL,
-- @pos_val_rule_e=0,   /*Nothing to load*/
-- @ext_post_list=NULL,
-- @event_flow_mask=1,
-- @perf_attrib_method_e=0,/*Standard*/
-- @perf_attrib_freq_e=0,/*Regular*/
-- @return_analysis_e=0,/*Ret nal et perf attrib*/
-- @freq1_n=1,
-- @freq1_unit_e=0,
-- @freq2_n=1,
@freq2_unit_e=4,
@calc_from=NULL,                /*<PMSTA08940-BRO-091211*/
@calc_till=NULL,
@calc_strat=NULL,
@calc_freq=NULL,
@calc_ref=NULL,                 /*>PMSTA08940-BRO-091211*/
@cash_flow_mgt_e=NULL,          /*PMSTA00485-BRO-061031*/
@dummy_min_status_e=NULL,       /*PMSTA00344-CHU-070123*/
@dummy_max_status_e=NULL,       /*PMSTA00344-CHU-070123*/
@func_res_list_def_t=NULL ,     /*PMSTA07121-EFE-090209*/
@dim_func_result_dict_id=NULL , /*PMSTA07121-EFE-090209*/
@case_mgmt_search_c=NULL ,      /*PMSTA07121-EFE-090209*/
@generate_case_f=NULL           /*PMSTA08705-DDV-091111*/
go
EOT
  ret=$?
  ((func_ret+=$ret))
  retmsg=$(grep -c "Msg" $TMP_FILE_1)
  ((func_ret+=$retmsg))
  if [[ $ret -ne 0 || $retmsg -ne 0 ]]; then
    echo "DEBUG: get_mig_perf_line SQL_CMD:1 ret:$ret retmsg:$retmsg" >&2
    cat $TMP_FILE_1 >&2
    oly2ta_log_fct "Batch" "ERROR" "  When running performance function on $src_ptf:\n$(cat $TMP_FILE_1)"
  fi

  # Get the return status, is also the r_dataset_id if output is repdb
  dataset_id=$(awk '/return status/ {printf("%d",$4)}' $TMP_FILE_1)
  if [ "$dataset_id" = "-1" ]; then
    oly2ta_log_fct "Batch" "ERROR" "  Financial function wrong return code on $src_ptf: $dataset_id"
    ((func_ret+=1))
  fi

  # Get result file
  $SQL_CMD <<-EOT >$TMP_FILE_2
use $AAAMAINDB
go
set nocount on

declare @ptf_curr code_t

select @ptf_curr=c.code
from   portfolio p, currency c
where  p.currency_id = c.id
and    p.code = "$target_ptf"

select '::DATA::'
     , @ptf_curr, convert(varchar, r.final, 103), 104, r.cum_twr
     , "Migrated_from:$src_ptf"
from   $AAAREPDB..ABN_PERFO_SYS r
where  r.r_dataset_id = $dataset_id
and    r.filter = 1
and    r.final = convert(datetime, "$RUNDATE", 103)
go
EOT
  ret=$?
  ((func_ret+=$ret))
  retmsg=$(grep -c "Msg" $TMP_FILE_2)
  ((func_ret+=$retmsg))
  if [[ $ret -ne 0 || $retmsg -ne 0 ]]; then
    echo "DEBUG: get_mig_perf_line SQL_CMD:2 ret:$ret retmsg:$retmsg" >&2
    cat $TMP_FILE_2 >&2
    oly2ta_log_fct "Batch" "ERROR" "  When getting performance result on $src_ptf:\n$(cat $TMP_FILE_2)"
  fi

  awk -v OFS=";" -v target_ptf="$target_ptf" '/::DATA::/ {
    print "DAT " target_ptf, $2, $3, $4, $5, $6
  }' ${TMP_FILE_2}
  ret=$?
  ((func_ret+=$ret))

  return $func_ret
}

#
# Create chronos import file for one ptf
# Globals:
#   SQL_CMD
#   AAAMAINDB
#   OLY2TA_TMP
#   SCRIPT_NAME
# Arguments:
#   $1: src_ptf
#   $2: target_ptf
#   $3: imp_file
# Returns:
#   func_ret : error code
# 
create_ptf_chr_imp() {
  #set -x
  local src_ptf=$1
  local target_ptf=$2
  local imp_file=$3
  local readonly TMP_FILE_1=${OLY2TA_TMP}/${SCRIPT_NAME}.ptf_chr_${target_ptf}.$$.tmp1
  local ret
  local func_ret=0
  $SQL_CMD <<-EOT >$TMP_FILE_1
use $AAAMAINDB
go
select "::DATA::"
     , cur.code, convert(varchar, ch.validity_d, 103), ch.nature_e, ch.value_n
     , str_replace(ch.comment_c, ";", ",")
from   portfolio p, port_chrono ch, currency cur
where  ch.portfolio_id = p.id
and    ch.currency_id = cur.id
and    p.code = "$src_ptf"
and    ( ch.nature_e in (1, 102, 103)
         or ( ch.nature_e in (150, 151, 152, 153, 161, 162, 163, 171, 172, 173)
              and ch.validity_d > "31-Dec-2015" ) )
order by ch.nature_e, ch.validity_d
go
EOT
  ret=$?
  ((func_ret+=$ret))
  retmsg=$(grep -c "Msg" $TMP_FILE_1)
  ((func_ret+=$retmsg))
  if [[ $ret -ne 0 || $retmsg -ne 0 ]]; then
    echo "DEBUG: create_ptf_chr_imp SQL_CMD ret:$ret retmsg:$retmsg" >&2
    cat $TMP_FILE_1 >&2
    oly2ta_log_fct "Batch" "ERROR" "  When getting chronos to copy:\n$(cat $TMP_FILE_1)"
  fi

  # Prepare header
  cat <<-EOT >${imp_file}
SET DATAFORMAT DELIMITED
SET SEPARATOR ;
SET DATEFORMAT DD-MM-YYYY
SET THOUSAND ,
SET DECIMAL .
CMD INSUPD port_chrono
ATT portfolio_id.code currency_id.code validity_d nature_e value_n comment_c
EOT
  ret=$?
  ((func_ret+=$ret))

  # Data lines for copied chronos
  awk -v OFS=";" -v target_ptf="$target_ptf" '/::DATA::/ {
    print "DAT " target_ptf, $2, $3, $4, $5, $6
  }' ${TMP_FILE_1} >>${imp_file}
  ret=$?
  ((func_ret+=$ret))

  # Data line for migrated perf chrono
  get_mig_perf_line $src_ptf $target_ptf >>$imp_file
  ret=$?
  ((func_ret+=$ret))
  if (( $ret != 0 )); then
    echo "DEBUG: create_ptf_chr_imp get_mig_perf ret:$ret" >&2
    oly2ta_log_fct "Batch" "ERROR" "  Return code when getting migrated perf: $ret"
  fi

  return $func_ret
}

#
# Create notepad import file for one ptf
# Globals:
#   SQL_CMD
#   AAAMAINDB
#   OLY2TA_TMP
#   SCRIPT_NAME
# Arguments:
#   $1: src_ptf
#   $2: target_ptf
#   $3: imp_file
# Returns:
#   func_ret : error code
# 
create_ptf_note_imp() {
  #set -x
  local src_ptf=$1
  local target_ptf=$2
  local imp_file=$3
  local readonly TMP_FILE_1=${OLY2TA_TMP}/${SCRIPT_NAME}.ptf_note_${target_ptf}.$$.tmp1
  local ret
  local func_ret=0
  $SQL_CMD <<-EOT >$TMP_FILE_1
use $AAAMAINDB
go
select "::DATA::"
     , p.code, convert(varchar, n.note_d, 103), t.code, n.title_c
     , str_replace(n.note_c, ";", ",")
from   notepad n, portfolio p, type t
where  n.entity_dict_id = 800 and n.object_id = p.id
and    n.type_id = t.id
and    t.code = "PERF_BEGIN_D"
and    p.code = "$src_ptf"
go
EOT
  ret=$?
  ((func_ret+=$ret))
  retmsg=$(grep -c "Msg" $TMP_FILE_1)
  ((func_ret+=$retmsg))
  if [[ $ret -ne 0 || $retmsg -ne 0 ]]; then
    echo "DEBUG: create_ptf_chr_imp SQL_CMD ret:$ret retmsg:$retmsg" >&2
    cat $TMP_FILE_1 >&2
    oly2ta_log_fct "Batch" "ERROR" "  When getting chronos to copy:\n$(cat $TMP_FILE_1)"
  fi

  # Prepare header
  cat <<-EOT >${imp_file}
SET DATAFORMAT DELIMITED
SET SEPARATOR ;
SET DATEFORMAT DD-MM-YYYY
SET THOUSAND ,
SET DECIMAL .
CMD INSUPD notepad portfolio
ATT entity object note_d type title_c note_c
EOT
  ret=$?
  ((func_ret+=$ret))

  # Data lines for copied notepad
  awk -v OFS=";" -v target_ptf="$target_ptf" '/::DATA::/ {
    print "DAT portfolio", target_ptf, $3, $4, $5, $6
  }' ${TMP_FILE_1} >>${imp_file}
  ret=$?
  ((func_ret+=$ret))

  return $func_ret
}

#
# Get Oly2TA Import daemon status
# Output result: Import status (RUNNING,SUSPEND,STOPPED,RESUME)
#
oly2ta_get_status() {
  cat $OLY2TA_HOME/.IMPORT_STATUS$OLY2TA_SITE
}

#
# Import a file
# Globals:
#   OLY2TA_SCRIPT
#   OLY2TA_IMPORT
#   PREFIX
#   CURRENTDATE
# Arguments:
#   $1: imp_file
# Returns:
#   func_ret : error code
#
oly2ta_imp_file() {
  #set -x
  local imp_file=$1
  local timed_imp_filename=${PREFIX}${CURRENTDATE}.$(basename ${imp_file})
  local ret
  local func_ret=0
  oly2ta_log_fct "Batch" "INFO" "    Sending $imp_file to import"
  mv $imp_file $OLY2TA_IMPORT/$timed_imp_filename
  ret=$?
  ((func_ret+=$ret))
  if [ "`oly2ta_get_status`" != "RUNNING" ]
  then
    $OLY2TA_SCRIPT/Oly2TA_Import_File.sh $timed_imp_filename
    ret=$?
    ((func_ret+=$ret))
    if (( $ret != 0 )); then
      echo "DEBUG: oly2ta_imp_file Oly2TA_Import_File.sh ret:$ret" >&2
      oly2ta_log_fct "Import" "ERROR" "Unable to import file: $timed_imp_filename"
    fi
  fi
  return $func_ret
}
################################################################################

################################################################################
# Main
################################################################################
oly2ta_log_fct "Batch" "INFO" "Start of $0"

# Get portfolios to migrate
get_ptf_list >$PTF_LIST_FILE
ret=$?
((totalret+=$ret))
if (( $ret != 0 )); then
  echo "DEBUG: get_ptf_list ret:$ret" >&2
  oly2ta_log_fct "Batch" "ERROR" "  Return code when getting portfolios to process: $ret"
fi
cat $PTF_LIST_FILE

readonly PTF_LIST_COUNT=$(wc -l $PTF_LIST_FILE | awk '{print $1}')
oly2ta_log_fct "Batch" "INFO" "  Found $PTF_LIST_COUNT portfolio(s) to process"

# Loop on each ptf to migrate
loop_count=0
for ptf_line in $(cat $PTF_LIST_FILE); do
  ((loop_count+=1))
  src_ptf=$(echo "$ptf_line" | cut -d";" -f1)
  target_ptf=$(echo "$ptf_line" | cut -d";" -f2)
  oly2ta_log_fct "Batch" "INFO" "  Start migration ${loop_count}/${PTF_LIST_COUNT} from $src_ptf to $target_ptf"

  # Copy chronos
  PTF_CHR_IMP_FILE=${OLY2TA_TMP}/Mifid2_MigPerf_port_chrono_${target_ptf}.imp
  create_ptf_chr_imp $src_ptf $target_ptf "$PTF_CHR_IMP_FILE"
  ret=$?
  ((totalret+=$ret))
  if (( $ret != 0 )); then
    echo "DEBUG: create_ptf_chr_imp ret:$ret" >&2
    oly2ta_log_fct "Batch" "ERROR" "  Return code when creating port_chrono import file: $ret"
  fi
  oly2ta_imp_file $PTF_CHR_IMP_FILE
  ret=$?
  ((totalret+=$ret))
  if (( $ret != 0 )); then
    echo "DEBUG: oly2ta_imp_file ret:$ret" >&2
    oly2ta_log_fct "Batch" "ERROR" "  Return code when importing port_chrono: $ret"
  fi

  # Copy notepad
  PTF_NOTE_IMP_FILE=${OLY2TA_TMP}/Mifid2_MigPerf_note_${target_ptf}.imp
  create_ptf_note_imp $src_ptf $target_ptf "$PTF_NOTE_IMP_FILE"
  ret=$?
  ((totalret+=$ret))
  if (( $ret != 0 )); then
    echo "DEBUG: create_ptf_note_imp ret:$ret" >&2
    oly2ta_log_fct "Batch" "ERROR" "  Return code when creating notepad import file: $ret"
  fi
  oly2ta_imp_file $PTF_NOTE_IMP_FILE
  ret=$?
  ((totalret+=$ret))
  if (( $ret != 0 )); then
    echo "DEBUG: oly2ta_imp_file ret:$ret" >&2
    oly2ta_log_fct "Batch" "ERROR" "  Return code when importing notepad: $ret"
  fi
done

################################################################################
# Cleanup and Exit
#
if (( $totalret == 0 )); then
  rm -f ${OLY2TA_TMP}/${SCRIPT_NAME}*.$$.*
fi

oly2ta_log_fct "Batch" "INFO" "End of $0 with code $totalret"
exit $totalret
