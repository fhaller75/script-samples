#!/bin/ksh
###########################################################################
#
# Script to do a massive update of portfolio codes in TA with Oly suffix,
# as preparation for Mifid2 migration
#
# Parameters    :       None
#
# Prerequisites :       $OLY2TA_HOME must be defined
#
###########################################################################
#
# Author :  F.Haller/Umea
#
# Last updates
# 26/07/2017    : Creation (based on AA_Oly2TA_Daily_Clients_Refresh.sh)
#
###########################################################################

###################################################################
#  Declarion of Functions
###################################################################
#
# Function which gets the OLYMPIC-T'A import status
# Output result: Import status (RUNNING,SUSPEND,STOPPED,RESUME)
#
oly2ta_get_status() {
        cat $OLY2TA_HOME/.IMPORT_STATUS$OLY2TA_SITE
}
###################################################################


. $OLY2TA_HOME/config/Oly2TA$OLY2TA_SITE.cfg
. $OLY2TA_SCRIPT/Oly2TA_Function.fct

BUILD_PTF_LIST="NO"

PREFIX=`echo $OLY2TA_SITE | cut -c 2`
if [ "$PREFIX"  !=   "" ]
then
        PREFIX=${PREFIX}_
else
        PREFIX=""
fi

dt=`date +%Y%m%d`
CURRENTDATE="`oly2ta_getdate_fct`"

###################################################################
#  Run db2 query select TACLIENTS
###################################################################

db2 connect to $OLY2TA_DB2_SERVER user $OLY2TA_DB2_USER using $OLY2TA_DB2_PASSWD >/dev/null
if [ $? -eq 0 ]
then
        echo "db2 connection successfull."
else
        echo "Problem with db2 connection!! Please check credentials. "
        exit 255
fi

db2 +p -x "select '::DATA::', CLI.CLRACI, CLI.CLNOMC \
           from   ${OLY2TA_TACLIENTS} TACLI, ${OLY2TA_OLYLIB}FDBCLI CLI \
           where  TACLI.CLRACI = CLI.CLRACI
           order by CLI.CLRACI" \
>${OLY2TA_TMP}/taclients_$dt.dat 2>${OLY2TA_TMP}/taclients_$dt.err
if [ $? -eq 0 -o $? -eq 1 ]
then
        echo "Data fetched in ${OLY2TA_TMP}/taclients_$dt.dat file."
        rm -f ${OLY2TA_TMP}/taclients_$dt.err
else
        echo "Problem with select statement. Please check the log ${OLY2TA_TMP}/taclients_$dt.err for errors!"
        exit 255
fi

###################################################################
# Format output data to create the import file
###################################################################
cat <<-EOT > ${OLY2TA_TMP}/Mifid2_MBK_ptf_$dt.imp
SET DATEFORMAT DD-MM-YYYY
SET DATAFORMAT DELIMITED
SET SEPARATOR ;
SET THOUSAND ,
CMD MBK portfolio
ATT #code code name
EOT
awk '/::DATA::/ {print "DAT L"$2";L"$2"-000;"$3}' ${OLY2TA_TMP}/taclients_$dt.dat >>${OLY2TA_TMP}/Mifid2_MBK_ptf_$dt.imp
ret=$?
if (( $ret != 0 )); then
  echo "Problem with import file formating. Please check the imp file ${OLY2TA_TMP}/Mifid2_MBK_ptf_$dt.imp"
  exit 255
fi

###################################################################
# Run import
###################################################################
# Put import in folder where import DAEMON is looking
mv ${OLY2TA_TMP}/Mifid2_MBK_ptf_$dt.imp $OLY2TA_IMPORT/${PREFIX}${CURRENTDATE}.Mifid2_MBK_ptf_$dt.imp
if [ "`oly2ta_get_status`" != "RUNNING" ]
then 
 	$OLY2TA_SCRIPT/Oly2TA_Import_File.sh ${PREFIX}${CURRENTDATE}.Mifid2_MBK_ptf_$dt.imp
	ret_code=$?
	if [ $ret_code != 0 ]
	then
		oly2ta_log_fct "Import" "ERROR" "Unable to import file: ${PREFIX}${CURRENTDATE}.Mifid2_MBK_ptf_$dt.imp"
	fi	
fi

###################################################################
# Rebuild List
##################################################################
if [ "$BUILD_PTF_LIST" = "YES" ]
then
	isql -U$AAAUSER -P$AAAUSERPWD -S$DSQUERY  << EOF
	use $AAAMAINDB
	go
	exec build_list_compo 'portfolio','${HC_LIST_PTF}',0,1,0,0,NULL,NULL
	go
	quit
EOF
	ret=$?
	if [ $ret != 0 ]
	then
		oly2ta_log_fct "Import" "ERROR" "Unable to build portfoliolist ${HC_LIST_PTF}"
		exit 255
	fi
fi

###################################################################
# Archive and Cleanup
##################################################################
# mv ${OLY2TA_OUTPUT}/Mifid2_MBK_ptf_$dt.out $OLY2TA_ARCHIVE/today/Mifid2_MBK_ptf_$dt.out
# compress -f $OLY2TA_ARCHIVE/today/Mifid2_MBK_ptf_$dt.out

rm -f ${OLY2TA_TMP}/taclients_$dt.dat

exit 0
