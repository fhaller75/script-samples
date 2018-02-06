#!/usr/bin/ksh 
###########################################################################
#
# Outputs an alert body in a specific format, based on a data file and a
# predefined layout
#
# Parameters	:	datafile
#                       layout
#                       attachment (optional)
# Prerequisites	:	$OLY2TA_HOME must be defined
#
###########################################################################
#
# Major versions:
# 16/09/2015 - FHA/Umea : Creation
# 15/12/2017 - FHA/Umea : Prepare header to accept attachment for Mifid reports
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

if [[ $# -ne 2 ]]; then
  echo "\nUSAGE: $0 datafile layout"
  exit 255
fi

#
# Initialization
#
DATA_FILE=$1
LAYOUT=$2

. $OLY2TA_HOME/config/Oly2TA$OLY2TA_SITE.cfg
. $OLY2TA_SCRIPT/Oly2TA_Function.fct
. $AAAHOME/admin/scripts/initaaa.cfg

SHELLNAME=$(basename $0 .sh)
totalret=0

ENV=$(echo $AAAENV | tr 'a-z' 'A-Z')

# Debug mode: 0=OFF / 1=ON
DEBUG=${DEBUG:-0}

# Force locale for format_num, because TAP subscription overwrites LANG
LC_ALL=en_US
export LC_ALL

#
# Functions
#
call_layout() {
nawk -v layout=$1 \
     -v env=$ENV \
     -v pid=$$ \
'
BEGIN {
  FS="::";
}

# Filter blank lines
/^ *$/ { next; }

# Read data
{
  if ($2 == "FIELD") {
    fields[$3]=$5;
    previous=$2;
    prev_field=$3;
  }
  else if (previous=="FIELD") {
    fields[prev_field]=fields[prev_field] "<br>" $1;
  }
}

# Functions
function format_num(num, dec) {
  if (dec == 0) dec=6;               # nb of decimals defaults to 6
  fnum=sprintf("%'"'"'21."dec"f", num);
  if (fnum ~ /\./) {
    sub(/0*$/, "", fnum);            # rtrim zeros if non-integer
  }
  sub(/\.$/,"",fnum);                # remove . if integer
  sub(/^[ \t\r\n]+/, "", fnum);      # ltrim
  return fnum;
}

function print_header() {
  # Print mail header
  print "To:" mailto;
  print "Cc:" mailcc;
  print "Bcc:" mailbcc;
  print "Subject:" subject;
  print "Mime-Version: 1.0";
  print "Content-Type: multipart/mixed; boundary=\"::BOUNDARY::" pid "\"";
  print "--::BOUNDARY::" pid;
  print "Content-Type: text/html; charset=ISO-8859-1";
  print "Content-Disposition: inline"
}

function open_html_body() {
  # Start HTML code
  print "<html>";
  print "  <body>";
}

function test_env_disclaimer() {
  if (env != "PROD") {
    print "    <p style=\"font-size: 100%\; font-family: Consolas,Courier New,Courier,serif\; border: solid 1px red\; padding: 4px\; text-align: center\;\">";
    print "      <strong>DISCLAIMER : </strong>REPORT SENT BY TRIPLE'"'"'A <strong>" env "</strong> ENVIRONMENT<br>";
    print "      THE BELOW INFO ARE NOT REAL PRODUCTION DATA";
    print "    </p>";
  }
}

function noreply_disclaimer() {
  print "    <p style=\"font-size: 100%\; font-family: Consolas,Courier New,Courier,serif\; border: solid 1px red\; padding: 4px\; text-align: center\;\">";
  print "      <strong>DISCLAIMER : </strong>This email address is not monitored. Please, do not reply to this address.<br>";
  print "    </p>";
}

function empty_mgr_email_warning() {
  if (fields["mgr_email"] == "") {
    print "    <p style=\"font-size: 100%\; font-family: Consolas,Courier New,Courier,serif\; border: solid 1px red\; padding: 4px\; text-align: center\;\">";
    print "      <strong>WARNING : </strong>ORDER CREATOR EMAIL NOT FOUND<br>";
    print "      DIRECT MESSAGE COULD NOT BE SENT";
    print "    </p>";
  }
}

function print_table_header() {
    print "    <table style=\"font-size: 90%\; font-family: Arial,Helvetica,sans-serif\; margin: 0\; border-collapse: collapse\; border-spacing: 0\;\">";
    print "    " open_tr;
    print "      " open_th subject close_th;
    print "    " close_tr;
}

function print_tr(label, value, styling) {
  print "    " open_tr;
  print "      " open_td_grey label close_td;
  if (styling == "strong") {
    print "      " open_td_strong value close_td;
  }
  else {
    print "      " open_td value close_td;
  }
  print "    " close_tr;
}

function close_html_body() {
    print "    </table>";
    noreply_disclaimer();
    # Close HTML code
    print "  </body>";
    print "</html>";
}

END {
  # Prepare HTML styling strings
  open_th="<th colspan=\"2\" style=\"padding: 4px\">";
  close_th="</th>";
  open_td="<td style=\"border: 1px solid #e0e0e0\; padding: 0 4px\;\">";
  open_td_grey="<td style=\"background-color: #e0e0e0\; border-bottom: 1px solid #fff\; padding: 0 4px\; text-align: right\; vertical-align: middle\;\">";
  open_td_strong="<td style=\"border: 1px solid #e0e0e0\; padding: 0 4px\; font-weight: bold\;\">";
  close_td="</td>";
  open_tr="<tr>";
  close_tr="</tr>";
  
  ########################################
  # LAYOUT : Order delayed
  ########################################
  if (layout == "ORDER_DELAY") {

    # Build mail header fields
    if (env == "PROD"){
      mailto=fields["mgr_email"];
    }
    if (fields["rm_email"] != "" && fields["rm_email"] != fields["mgr_email"] && env == "PROD") {
      mailbcc=fields["rm_email"];
    }
    if (fields["mgr_email"] == "") {
      subject="WARNING: ";
    }
    subject=subject "ORDER DELAYED - " fields["nature"] " - " format_num(fields["order_original_qty"]) " " fields["instr_denom"] " at " fields["order_nat"];
    if (fields["order_limit_quote"] != "") {
      subject=subject " " format_num(fields["order_limit_quote"]);
    }
    subject=subject " - " fields["portfolio"];

    # Start printing mail content
    print_header();
    open_html_body();
    test_env_disclaimer();
    empty_mgr_email_warning();

    # HTML table
    print_table_header();
    print_tr("Triple'"'"'A Reference",       fields["code"]);
    print_tr("Status",                       fields["status"]);
    print_tr("Last Modification",            fields["last_modif_datetime"]);
    print_tr("Creation Timestamp",           fields["creation_datetime"]);
    print_tr("Created By",                   fields["mgr_denom"]);
    print_tr("Buy/Sell",                     fields["nature"]           , "strong");
    print_tr("Portfolio Code",               fields["portfolio"]);
    print_tr("Instrument Code",              fields["instr_code"]);
    print_tr("ISIN",                         fields["instr_isin"]);
    print_tr("Instrument Denom.",            fields["instr_denom"]);
    print_tr("Order Mode Type",              fields["order_mode_type"]);
    print_tr("Market",                       fields["market"]);
    print_tr("Order Type",                   fields["order_nat"]);
    if (fields["order_limit_quote"] != "") {
      print_tr("Limit Quote",                  format_num(fields["order_limit_quote"]));
      print_tr("Limit Date",                   fields["order_limit_date"]);
    }
    if (fields["comm_party_type"] == "BHI_DS_CLIENT") {
      print_tr("Client Contact Date and Time", fields["contact_datetime"]);
      if (fields["communication_type"] != "") {
        print_tr("Client Communication Channel", fields["communication_type"]);
      }
      if (fields["remark_1"] != "") {
        print_tr("Client Instruction",           fields["remark_1"]);
      }
    }

    close_html_body();
  }

  ########################################
  # LAYOUT : Order exec or exec modif
  ########################################
  else if (layout == "ORDER_EXEC" || layout == "ORDER_EXECMOD") {

    # Build mail header fields
    if (env == "PROD"){
      mailto=fields["mgr_email"];
    }
    if (fields["rm_email"] != "" && fields["rm_email"] != fields["mgr_email"] && env == "PROD") {
      mailbcc=fields["rm_email"];
    }
    if (fields["mgr_email"] == "") {
      subject="WARNING: ";
    }
    if (layout == "ORDER_EXECMOD") {
      subject=subject "MODIFICATION: "
    }
    subject=subject fields["status"];
    if (fields["avg_exec_price"] != "") {
      subject=subject " @" format_num(fields["avg_exec_price"], 5);
    }
    subject=subject " - " fields["nature"] \
            " - " format_num(fields["order_original_qty"]) " " fields["instr_denom"] " at " fields["order_nat"];
    if (fields["order_limit_quote"] != "") {
      subject=subject " " format_num(fields["order_limit_quote"]);
    }
    subject=subject " - " fields["portfolio"];

    # Build executions string
    for (i=1; i<=10; i++) {
      if (fields["executed_qty" i] != 0 && fields["executed_qty" i] != "") {    # Partial executions 1->10
        if (exec_str != "") {
          exec_str=exec_str "<br>\n";
        }
        exec_str=exec_str format_num(fields["executed_qty" i]) " at " format_num(fields["executed_price" i], 5) " on " fields["exec_datetime" i];
      }
    }
    if (fields["executed_qty0"] != 0 && fields["executed_qty0"] != "") {    # Final execution
      if (exec_str != "") {
        exec_str=exec_str "<br>\n";
      }
      exec_str=exec_str format_num(fields["executed_qty0"]) " at " format_num(fields["executed_price0"], 5) " on " fields["exec_datetime0"];
    }
  
    # Start printing mail content
    print_header();
    open_html_body();
    test_env_disclaimer();
    empty_mgr_email_warning();

    # HTML table
    print_table_header();
    print_tr("Triple'"'"'A Reference",       fields["code"]);
    print_tr("Olympic Reference",            fields["accounting_code"]);
    print_tr("Creation Timestamp",           fields["creation_datetime"]);
    print_tr("Created By",                   fields["mgr_denom"]);
    print_tr("Buy/Sell",                     fields["nature"]           , "strong");
    print_tr("Portfolio Code",               fields["portfolio"]);
    print_tr("Instrument Code",              fields["instr_code"]);
    print_tr("ISIN",                         fields["instr_isin"]);
    print_tr("Instrument Denom.",            fields["instr_denom"]);
    if (fields["ytm"] != "") {
      print_tr("YTM",                          format_num(fields["ytm"], 4) " %");
    }
    print_tr("Order Mode Type",              fields["order_mode_type"]);
    print_tr("Remaining Quantity",           format_num(fields["quantity"]));
    print_tr("Avg Execution Price",          format_num(fields["avg_exec_price"], 5) " " fields["price_unit"]);
    if (fields["accr_amount"] != "" && fields["accr_amount"] != 0) {
      print_tr("Accrued Interest",             format_num(fields["accr_amount"], 2) " " fields["op_currency"]);
    }
    print_tr("Execution(s)",                 exec_str);
    print_tr("Account",                      fields["account"]);
    print_tr("Deposit",                      fields["deposit"]);
    print_tr("Market",                       fields["market"]);
    print_tr("Order Type",                   fields["order_nat"]);
    if (fields["order_limit_quote"] != "") {
      print_tr("Limit Quote",                  format_num(fields["order_limit_quote"]));
      print_tr("Limit Date",                   fields["order_limit_date"]);
    }
    if (fields["comm_party_type"] == "BHI_DS_CLIENT") {
      print_tr("Client Contact Date and Time", fields["contact_datetime"]);
      if (fields["communication_type"] != "") {
        print_tr("Client Communication Channel", fields["communication_type"]);
      }
      if (fields["remark_1"] != "") {
        print_tr("Client Instruction",           fields["remark_1"]);
      }
    }
  
    close_html_body();
  }

  ########################################
  # LAYOUT : Order rejected
  ########################################
  else if (layout == "ORDER_REJECT") {

    # Build mail header fields
    if (env == "PROD"){
      mailto=fields["mgr_email"];
    }
    if (fields["rm_email"] != "" && fields["rm_email"] != fields["mgr_email"] && env == "PROD") {
      mailbcc=fields["rm_email"];
    }
    if (fields["mgr_email"] == "") {
      subject="WARNING: ";
    }
    subject=subject "ORDER REJECTED - " fields["nature"] " - " format_num(fields["order_original_qty"]) " " fields["instr_denom"] " at " fields["order_nat"];
    if (fields["order_limit_quote"] != "") {
      subject=subject " " format_num(fields["order_limit_quote"]);
    }
    subject=subject " - " fields["portfolio"];

    # Start printing mail content
    print_header();
    open_html_body();
    test_env_disclaimer();
    empty_mgr_email_warning();

    # HTML table
    print_table_header();
    print_tr("Triple'"'"'A Reference",       fields["code"]);
    print_tr("Rejection message",            fields["internal_remark1"] , "strong");
    print_tr("Creation Timestamp",           fields["creation_datetime"]);
    print_tr("Created By",                   fields["mgr_denom"]);
    print_tr("Buy/Sell",                     fields["nature"]           , "strong");
    print_tr("Portfolio Code",               fields["portfolio"]);
    print_tr("Instrument Code",              fields["instr_code"]);
    print_tr("ISIN",                         fields["instr_isin"]);
    print_tr("Instrument Denom.",            fields["instr_denom"]);
    print_tr("Order Mode Type",              fields["order_mode_type"]);
    print_tr("Market",                       fields["market"]);
    print_tr("Order Type",                   fields["order_nat"]);
    if (fields["order_limit_quote"] != "") {
      print_tr("Limit Quote",                  format_num(fields["order_limit_quote"]));
      print_tr("Limit Date",                   fields["order_limit_date"]);
    }
    if (fields["comm_party_type"] == "BHI_DS_CLIENT") {
      print_tr("Client Contact Date and Time", fields["contact_datetime"]);
      if (fields["communication_type"] != "") {
        print_tr("Client Communication Channel", fields["communication_type"]);
      }
      if (fields["remark_1"] != "") {
        print_tr("Client Instruction",           fields["remark_1"]);
      }
    }

    close_html_body();
  }

  ########################################
  # LAYOUT : Batch phase status notification
  ########################################
  else if (layout == "PHASE_STATUS") {

    # Build mail header fields
    subject=fields["level"] ": TOI batch Phase " fields["phase"] " " fields["status"];

    # Start printing mail content
    print_header();
    open_html_body();
    test_env_disclaimer();

    # HTML table
    print_table_header();
    print_tr("TOI Phase",                    fields["phase"]         , "strong");
    print_tr("Phase status",                 fields["status"]);
    print_tr("Status timestamp",             fields["alert_datetime"]);
    print_tr("TOI batch Business Date",      fields["business_date"]);
    print_tr("Last Oly flag timestamp",      fields["flag_datetime"]);

    close_html_body();
  }

  ########################################
  # LAYOUT : Order cancel or modif refused
  ########################################
  else if (layout == "ORD_CANCEL_REFUSED" || layout == "ORD_MODIF_REFUSED") {

    # Build mail header fields
    if (layout == "ORD_CANCEL_REFUSED") {
      subject="ORDER CANCELLATION REFUSED - "
    }
    else if (layout == "ORD_MODIF_REFUSED") {
      subject="ORDER MODIFICATION REFUSED - "
    }
    subject=subject fields["nature"] " - " format_num(fields["order_original_qty"]) " " fields["instr_denom"] " at " fields["order_nat"];

    # Start printing mail content
    print_header();
    open_html_body();
    test_env_disclaimer();

    # HTML table
    print_table_header();
    print_tr("Triple'"'"'A Reference",       fields["code"]);
    print_tr("Olympic Reference",            fields["accounting_code"]);
    print_tr("Status",                       fields["status"]           , "strong");
    print_tr("Last Modification",            fields["last_modif_datetime"]);
    print_tr("Creation Timestamp",           fields["creation_datetime"]);
    print_tr("Created By",                   fields["mgr_denom"]);
    print_tr("Buy/Sell",                     fields["nature"]           , "strong");
    print_tr("Portfolio Code",               fields["portfolio"]);
    print_tr("Instrument Code",              fields["instr_code"]);
    print_tr("ISIN",                         fields["instr_isin"]);
    print_tr("Instrument Denom.",            fields["instr_denom"]);
    print_tr("Order Mode Type",              fields["order_mode_type"]);
    print_tr("Market",                       fields["market"]);
    if (fields["order_limit_quote"] != "") {
      print_tr("Limit Quote",                  format_num(fields["order_limit_quote"]));
      print_tr("Limit Date",                   fields["order_limit_date"]);
    }
    if (fields["comm_party_type"] == "BHI_DS_CLIENT") {
      print_tr("Client Contact Date and Time", fields["contact_datetime"]);
      if (fields["communication_type"] != "") {
        print_tr("Client Communication Channel", fields["communication_type"]);
      }
      if (fields["remark_1"] != "") {
        print_tr("Client Instruction",           fields["remark_1"]);
      }
    }

    close_html_body();
  }

  ########################################
  # LAYOUT : Insider trading alert
  ########################################
  else if (layout == "ORD_ALERT_ITR") {

    # Build mail header fields
    subject="ITR - Potential Insider Trading Order - ";
    subject=subject fields["status"] " - " fields["nature"] " - " format_num(fields["order_original_qty"]) " " fields["instr_denom"] " at " fields["order_nat"];
    if (fields["order_limit_quote"] != "") {
      subject=subject " " format_num(fields["order_limit_quote"]);
    }
    subject=subject " - " fields["portfolio"];

    # Start printing mail content
    print_header();
    open_html_body();
    test_env_disclaimer();

    # HTML table
    print_table_header();
    print_tr("Triple'"'"'A Reference",       fields["code"]);
    print_tr("Olympic Reference",            fields["accounting_code"]);
    print_tr("Creation Timestamp",           fields["creation_datetime"]);
    print_tr("Created By",                   fields["mgr_denom"]);
    print_tr("Buy/Sell",                     fields["nature"]           , "strong");
    print_tr("Portfolio Code",               fields["portfolio"]);
    print_tr("Instrument Code",              fields["instr_code"]);
    print_tr("ISIN",                         fields["instr_isin"]);
    print_tr("Instrument Denom.",            fields["instr_denom"]);
    print_tr("Order Mode Type",              fields["order_mode_type"]);
    print_tr("Remaining Quantity",           format_num(fields["quantity"]));
    print_tr("Market",                       fields["market"]);
    print_tr("Order Type",                   fields["order_nat"]);
    if (fields["order_limit_quote"] != "") {
      print_tr("Limit Quote",                  format_num(fields["order_limit_quote"]));
      print_tr("Limit Date",                   fields["order_limit_date"]);
    }
    if (fields["comm_party_type"] == "BHI_DS_CLIENT") {
      print_tr("Client Contact Date and Time", fields["contact_datetime"]);
      if (fields["communication_type"] != "") {
        print_tr("Client Communication Channel", fields["communication_type"]);
      }
      if (fields["remark_1"] != "") {
        print_tr("Client Instruction",           fields["remark_1"]);
      }
    }
    print_tr("ITR Clarification Reason",     fields["ITR_clarif_reason"]);

    close_html_body();
  }

  ########################################
  # LAYOUT : Mifid suitabilty report
  ########################################
  else if (layout == "MIFID_REPORT") {

    # Build mail header fields
    if (env == "PROD"){
      mailto=fields["mgr_email"];
    }
    if (fields["rm_email"] != "" && fields["rm_email"] != fields["mgr_email"] && env == "PROD") {
      mailbcc=fields["rm_email"];
    }
    if (fields["mgr_email"] == "") {
      subject="WARNING: ";
    }

    # Build mail header fields
    subject=subject "Mifid Suitability report";
    subject=subject " - " fields["portfolio"];

    # Start printing mail content
    print_header();
    open_html_body();
    test_env_disclaimer();
    empty_mgr_email_warning();

    # HTML table
    print_table_header();
    print_tr("Portfolio Code",               fields["portfolio"]);
    print_tr("Input By",                     fields["mgr_denom"]);

    close_html_body();
  }

}
' $DATA_FILE
}

#
# Main
#
oly2ta_log_fct "Alert" "INFO" "  Start formatting with layout $LAYOUT"
if [[ ! -r $DATA_FILE ]]; then
  oly2ta_log_fct "Alert" "FATAL" " Data file $DATA_FILE cannot be read, aborting!"
  exit 255
fi

case $LAYOUT in
  ORDER_DELAY \
  | ORDER_EXEC \
  | ORDER_EXECMOD \
  | ORDER_REJECT \
  | PHASE_STATUS \
  | ORD_CANCEL_REFUSED \
  | ORD_MODIF_REFUSED \
  | ORD_ALERT_ITR \
  | MIFID_REPORT \
  )
    call_layout $LAYOUT
    let totalret+=$?
    ;;
  *)
    oly2ta_log_fct "Alert" "ERROR" " Unknown layout $LAYOUT, aborting!"
    echo "\nError: Unknown layout $LAYOUT"
    echo "Valid layouts:"
    echo "  MIFID_REPORT       : Mifid suitability report"
    echo "  ORD_ALERT_ITR      : Order insider trading alert"
    echo "  ORD_CANCEL_REFUSED : Order cancellation refused email"
    echo "  ORD_MODIF_REFUSED  : Order modidication refused email"
    echo "  ORDER_DELAY        : Order delayed email"
    echo "  ORDER_EXEC         : Order execution email"
    echo "  ORDER_EXECMOD      : Order execution modification email"
    echo "  ORDER_REJECT       : Order rejected email"
    echo "  PHASE_STATUS       : Phase status email"
    exit 255
    ;;
esac

#
# Exit
#
oly2ta_log_fct "Alert" "INFO" "  End of formatting process"

exit $totalret

