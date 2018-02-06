#!/usr/bin/ksh
###########################################################################
#
# Raise an alert on an order based on its status and subscription code
#
# Parameters	:	order_code
#                       status_e
#                       MODIF/ORDER_DELAY/Subscription Code
# Prerequisites	:	$OLY2TA_HOME must be defined
#
###########################################################################
#
# Versions:
# 27/03/2015 - FHA/Umea : Creation
# 30/06/2015 - FHA/Umea : Change script name, split extraction from
#                         formatting, adapt for "placed" orders
# 06/06/2016 - FHA/Umea : Add parameter for modification alerts
# 30/08/2016 - FHA/Umea : Subscription code as ALERT_TYPE for all new cases
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
  echo "\nUSAGE: $0 order_code status_e {MODIF|ORDER_DELAY|subscription_code}"
  exit 255
fi

#
# Initialization
#
OPECODE=$1
STATUS=$2
SUBCODE=$3

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
oly2ta_log_fct "Alert" "INFO" "Start alert processing for order $OPECODE with status $STATUS $SUBCODE "

if [[ "$SUBCODE" == @(ORD_Alert_Exec|ORD_Alert_Reject|MODIF|ORDER_DELAY) ]]; then
  # The old way
  case $STATUS in
    15)
      ALERT_TYPE=ORDER_REJECT
      ;;
    30|35|40)
      ALERT_TYPE=ORDER_DELAY
      ;;
    75|78)
      if [[ "$SUBCODE" == "MODIF" ]]; then
        ALERT_TYPE=ORDER_EXECMOD
      else
        ALERT_TYPE=ORDER_EXEC
      fi
      ;;
    *)
      oly2ta_log_fct "Alert" "ERROR" " Alert type could not be determined"
      exit 255;;
  esac
else
  # The new way: use subscription code
  ALERT_TYPE=$(echo $SUBCODE | tr [a-z] [A-Z])
fi

oly2ta_log_fct "Alert" "INFO" "  Run TAP alert query on $OPECODE "
if [[ $DEBUG -gt 1 ]]; then
  ISQL_ECHO=" -e"
fi
isql -U${AAAUSER} -P${AAAUSERPWD} -w1000 -b ${ISQL_ECHO} <<-EOT >$DATAFILE 2>&1
set nocount on
go
use aaamaindb
go
set rowcount 1
go

select char(10)

-- Main fields
|| '::FIELD::code::DATA::' ||
    eo.code
    + char(10)
|| '::FIELD::accounting_code::DATA::' ||
    eo.accounting_code
    + char(10)
|| '::FIELD::nature::DATA::' ||
    ( select pv.name from dict_perm_value pv, dict_attribute a
      where  pv.attribute_dict_id = a.dict_id
      and    a.entity_dict_id = 1004 and a.sqlname_c = "nature_e"
      and    pv.perm_val_nat_e = eo.nature_e )
    + ( select case when RIGHT(t.code, 1) = "O" then " Opening"
                    when RIGHT(t.code, 1) = "C" then " Closing"
                    else ""
               end
        from type t where t.id = eo.type_id )
    + char(10)
|| '::FIELD::portfolio::DATA::' ||
    p.code
    + char(10)
|| '::FIELD::status_e::DATA::' ||
    convert(varchar, eo.status_e)
    + char(10)
|| '::FIELD::status::DATA::' ||
    ( select pv.name
      from dict_perm_value pv, dict_attribute a
      where  pv.attribute_dict_id = a.dict_id
      and    a.entity_dict_id = 1004 and a.sqlname_c = "status_e"
      and    pv.perm_val_nat_e = ${STATUS} )
    + char(10)

-- Instr
|| '::FIELD::instr_code::DATA::' ||
    i.code
    + char(10)
|| '::FIELD::instr_denom::DATA::' ||
    i.denom
    + char(10)
|| '::FIELD::instr_isin::DATA::' ||
    ( select left(syn.code, 12)
      from   instrument i, synonym syn, codification cod
      where  syn.codification_id = cod.id
      and    syn.entity_dict_id = 900 and syn.object_id = i.id and cod.code = "001"
      and    i.id = eo.instr_id )
    + char(10)

-- Managers
|| '::FIELD::mgr_denom::DATA::' ||
    m.denom
    + char(10)
|| '::FIELD::mgr_email::DATA::' ||
    m.e_mail_address_c
    + char(10)
|| '::FIELD::rm_email::DATA::' ||
    rm.e_mail_address_c
    + char(10)

-- Order characteristics
|| '::FIELD::order_limit_date::DATA::' ||
    convert(char(10), eo.order_limit_d, 103)
    + char(10)
|| '::FIELD::order_limit_quote::DATA::' ||
    convert(varchar, convert(decimal(21,9), eo.limit_quote_n))
    + char(10)
|| '::FIELD::order_mode_type::DATA::' ||
    ( select t.name from type t
      where  t.id = eo.order_mode_type_id )
    + char(10)
|| '::FIELD::order_nat::DATA::' ||
    ( select pv.name from dict_perm_value pv, dict_attribute a
      where  pv.attribute_dict_id = a.dict_id
      and    a.entity_dict_id = 1004 and a.sqlname_c = "order_nat_e"
      and    pv.perm_val_nat_e = eo.order_nat_e )
    + char(10)
|| '::FIELD::order_original_qty::DATA::' ||
    convert(varchar, convert(decimal(21,9), eo.ud_order_original_qty_n))
    + char(10)

-- Executions
|| '::FIELD::avg_exec_price::DATA::' ||
    convert(varchar, convert(decimal(21,9), eo.ud_avg_exec_price_n))
    + char(10)
|| '::FIELD::price_unit::DATA::' ||
    case when i.price_calc_rule_e in (2, 4, 5, 19)
         then '%'
    else
         ( select cur.denom from currency cur
           where  cur.id = i.ref_curr_id )
    end
    + char(10)
|| '::FIELD::executed_qty0::DATA::' ||
    convert(varchar, convert(decimal(21,9), eo.ud_executed_qty0_n))
    + char(10)
|| '::FIELD::executed_price0::DATA::' ||
    convert(varchar, convert(decimal(21,9), ud_executed_price0_n))
    + char(10)
|| '::FIELD::exec_datetime0::DATA::' ||
    convert(char(10), eo.ud_exec_datetime0_d, 103) + ' '
    + convert(char(8), eo.ud_exec_datetime0_d, 20)
    + char(10)
|| '::FIELD::executed_qty1::DATA::' ||
    convert(varchar, convert(decimal(21,9), eo.ud_executed_qty1_n))
    + char(10)
|| '::FIELD::executed_price1::DATA::' ||
    convert(varchar, convert(decimal(21,9), ud_executed_price1_n))
    + char(10)
|| '::FIELD::exec_datetime1::DATA::' ||
    convert(char(10), eo.ud_exec_datetime1_d, 103) + ' '
    + convert(char(8), eo.ud_exec_datetime1_d, 20)
    + char(10)
|| '::FIELD::executed_qty2::DATA::' ||
    convert(varchar, convert(decimal(21,9), eo.ud_executed_qty2_n))
    + char(10)
|| '::FIELD::executed_price2::DATA::' ||
    convert(varchar, convert(decimal(21,9), ud_executed_price2_n))
    + char(10)
|| '::FIELD::exec_datetime2::DATA::' ||
    convert(char(10), eo.ud_exec_datetime2_d, 103) + ' '
    + convert(char(8), eo.ud_exec_datetime2_d, 20)
    + char(10)
|| '::FIELD::executed_qty3::DATA::' ||
    convert(varchar, convert(decimal(21,9), eo.ud_executed_qty3_n))
    + char(10)
|| '::FIELD::executed_price3::DATA::' ||
    convert(varchar, convert(decimal(21,9), ud_executed_price3_n))
    + char(10)
|| '::FIELD::exec_datetime3::DATA::' ||
    convert(char(10), eo.ud_exec_datetime3_d, 103) + ' '
    + convert(char(8), eo.ud_exec_datetime3_d, 20)
    + char(10)
|| '::FIELD::executed_qty4::DATA::' ||
    convert(varchar, convert(decimal(21,9), eo.ud_executed_qty4_n))
    + char(10)
|| '::FIELD::executed_price4::DATA::' ||
    convert(varchar, convert(decimal(21,9), ud_executed_price4_n))
    + char(10)
|| '::FIELD::exec_datetime4::DATA::' ||
    convert(char(10), eo.ud_exec_datetime4_d, 103) + ' '
    + convert(char(8), eo.ud_exec_datetime4_d, 20)
    + char(10)
|| '::FIELD::executed_qty5::DATA::' ||
    convert(varchar, convert(decimal(21,9), eo.ud_executed_qty5_n))
    + char(10)
|| '::FIELD::executed_price5::DATA::' ||
    convert(varchar, convert(decimal(21,9), ud_executed_price5_n))
    + char(10)
|| '::FIELD::exec_datetime5::DATA::' ||
    convert(char(10), eo.ud_exec_datetime5_d, 103) + ' '
    + convert(char(8), eo.ud_exec_datetime5_d, 20)
    + char(10)
|| '::FIELD::executed_qty6::DATA::' ||
    convert(varchar, convert(decimal(21,9), eo.ud_executed_qty6_n))
    + char(10)
|| '::FIELD::executed_price6::DATA::' ||
    convert(varchar, convert(decimal(21,9), ud_executed_price6_n))
    + char(10)
|| '::FIELD::exec_datetime6::DATA::' ||
    convert(char(10), eo.ud_exec_datetime6_d, 103) + ' '
    + convert(char(8), eo.ud_exec_datetime6_d, 20)
    + char(10)
|| '::FIELD::executed_qty7::DATA::' ||
    convert(varchar, convert(decimal(21,9), eo.ud_executed_qty7_n))
    + char(10)
|| '::FIELD::executed_price7::DATA::' ||
    convert(varchar, convert(decimal(21,9), ud_executed_price7_n))
    + char(10)
|| '::FIELD::exec_datetime7::DATA::' ||
    convert(char(10), eo.ud_exec_datetime7_d, 103) + ' '
    + convert(char(8), eo.ud_exec_datetime7_d, 20)
    + char(10)
|| '::FIELD::executed_qty8::DATA::' ||
    convert(varchar, convert(decimal(21,9), eo.ud_executed_qty8_n))
    + char(10)
|| '::FIELD::executed_price8::DATA::' ||
    convert(varchar, convert(decimal(21,9), ud_executed_price8_n))
    + char(10)
|| '::FIELD::exec_datetime8::DATA::' ||
    convert(char(10), eo.ud_exec_datetime8_d, 103) + ' '
    + convert(char(8), eo.ud_exec_datetime8_d, 20)
    + char(10)
|| '::FIELD::executed_qty9::DATA::' ||
    convert(varchar, convert(decimal(21,9), eo.ud_executed_qty9_n))
    + char(10)
|| '::FIELD::executed_price9::DATA::' ||
    convert(varchar, convert(decimal(21,9), ud_executed_price9_n))
    + char(10)
|| '::FIELD::exec_datetime9::DATA::' ||
    convert(char(10), eo.ud_exec_datetime9_d, 103) + ' '
    + convert(char(8), eo.ud_exec_datetime9_d, 20)
    + char(10)
|| '::FIELD::executed_qty10::DATA::' ||
    convert(varchar, convert(decimal(21,9), eo.ud_executed_qty10_n))
    + char(10)
|| '::FIELD::executed_price10::DATA::' ||
    convert(varchar, convert(decimal(21,9), ud_executed_price10_n))
    + char(10)
|| '::FIELD::exec_datetime10::DATA::' ||
    convert(char(10), eo.ud_exec_datetime10_d, 103) + ' '
    + convert(char(8), eo.ud_exec_datetime10_d, 20)
    + char(10)

-- Case management
|| '::FIELD::ITR_clarif_reason::DATA::' ||
    ( select cc.reason_c
      from   ext_operation o, case_link cl, case_management cm, type cmt, case_clarification cc
      where  o.id = cl.object_id 
      and    cl.entity_dict_id = (select dict_id from dict_entity where sqlname_c = "ext_operation")
      and    cl.case_id = cm.id and cm.sub_nat_e=3 and cm.nature_e=2 and cm.status_e=1 and cm.session_id!=NULL
      and    cmt.id = cm.type_id and cmt.code = "ITR"
      and    cc.case_id = cm.id
      and    o.code = eo.code )
    + char(10)

-- Other details
|| '::FIELD::account::DATA::' ||
    acc.code
    + char(10)
|| '::FIELD::accr_amount::DATA::' ||
    convert(varchar, eo.accr_amount_m)
    + char(10)
|| '::FIELD::comm_party_type::DATA::' ||
    ( select t.code from type t
      where  t.id = eo.comm_party_type_id )
    + char(10)
|| '::FIELD::communication_type::DATA::' ||
    ( select t.name from type t
      where  t.id = eo.communication_type_id )
    + char(10)
|| '::FIELD::contact_datetime::DATA::' ||
    convert(char(10), eo.communication_d, 103) + ' '
    + convert(char(8), eo.communication_d, 20)
    + char(10)
|| '::FIELD::creation_datetime::DATA::' ||
    convert(char(10), eo.creation_time_d, 103) + ' '
    + convert(char(8), eo.creation_time_d, 20)
    + char(10)
|| '::FIELD::deposit::DATA::' ||
    d.name
    + char(10)
|| '::FIELD::internal_remark1::DATA::' ||
    eo.ud_internal_remark1_t
    + char(10)
|| '::FIELD::last_modif_datetime::DATA::' ||
    convert(char(10), eo.last_modif_d, 103) + ' '
    + convert(char(8), eo.last_modif_d, 20)
    + char(10)
|| '::FIELD::market::DATA::' ||
    mkt.name
    + char(10)
|| '::FIELD::op_currency::DATA::' ||
    ( select cur.denom from currency cur
      where  cur.id = eo.op_currency_id )
    + char(10)
|| '::FIELD::quantity::DATA::' ||
    convert(varchar, convert(decimal(21,9), eo.quantity_n))
    + char(10)
|| '::FIELD::remark_1::DATA::' ||
    eo.remark_1_c
    + char(10)
|| '::FIELD::ytm::DATA::' ||
    convert(varchar, convert(decimal(21,9), eo.ud_ytm_n))
    + char(10)

from   ext_order_vw eo, portfolio p, instrument i, instrument acc, deposit d, third_party mkt, manager m, manager rm
where  eo.portfolio_id = p.id
and    eo.instr_id = i.id
and    eo.account_id = acc.id
and    eo.deposit_id *= d.id
and    eo.market_third_id *= mkt.id
and    eo.manager_id *= m.id
and    p.admin_mgr_id *= rm.id
and    eo.code = "$OPECODE"
go

EOT
let totalret+=$?

if [[ ! -s $DATAFILE ]]; then
  oly2ta_log_fct "Alert" "ERROR" " Alert data file $DATAFILE empty for order $OPECODE"
  totalret=255
else
  # Check that order status has not changed in the meantime between trigger and query
  qry_status=$(nawk 'BEGIN{FS="::"} /::FIELD::status_e::/ {print $5}' $DATAFILE)

  if [[ "$qry_status" != "$STATUS" && "$STATUS" == @(30|35|40|75) ]]; then
    oly2ta_log_fct "Alert" "ERROR" " Order status has changed from $STATUS to $qry_status, aborting alert"
    totalret=255
  else
    oly2ta_log_fct "Alert" "INFO" "  Build mail content for $OPECODE $ALERT_TYPE"
    ${OLY2TA_SCRIPT}/Oly2TA_Alert_Layout.sh $DATAFILE $ALERT_TYPE > $BODYFILE 2>&1
    let totalret+=$?

    if [[ ! -s $BODYFILE ]]; then
      oly2ta_log_fct "Alert" "ERROR" " Mail body file $BODYFILE empty for order $OPECODE"
      totalret=255
    else
      oly2ta_log_fct "Alert" "INFO" "  Send alert mail for $OPECODE $ALERT_TYPE"
      ${OLY2TA_SCRIPT}/Oly2TA_Send_Mail.sh $BODYFILE $ALERT_TYPE
      let totalret+=$?
    fi

  fi
fi

#
# Exit
#
oly2ta_log_fct "Alert" "INFO" "End of alert processing on $OPECODE"

retrc=$(cat $DATAFILE | grep "Msg")
if [[ $totalret -eq 0 && "$retrc" == "" && $DEBUG -eq 0 ]];then
  rm -f $DATAFILE $BODYFILE
fi

# Feedback return code to WTX map
echo $totalret

exit $totalret

