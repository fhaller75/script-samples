MERCSRC.MAP                                            l   (  h  �  �      `                                 User_Quant_FCT       User_Status_FCT       ORD_TA2Alert_Modif       ORD_TA2Alert_Modif_FCT             Out     Out     Out     Status  
    VLDECQ      Parameters      Parameters  	    quantity_n      Parameters      order_alert      Ext_operation       Ext_operation       Lookup_AAAEnum      Lookup_AAAEnum      User_Tools_Function.        	       % * 0 6 < B   File alert_log    Record alert_log      Text_In Tools Data    Text_out Tools Data   File Subext_operation     Nb_integer Tools Data     File Values Parameters    File EnumValDirect Data   SubRec Subext_operation   RecStatus Values Parameters  $ LBQORD Column OLYFAAADAY_FDBIOB Data     - quantity_n number_t datatype Subext_operation          % , 3 : B M   %LOOKUP%      %WORK_G%     
 ../maplog/    %PARAMETERS%      ..\maps_G\tototrace   ../log/Oly2TA_Alert.log   ../tmp/Oly2TA_SecBS_input.txt     ..\TypeTrees\lookups\Enum.mtt     ..\TypeTrees\Olympic\FDBIOB.mtt    ..\TAImport\triplea_data_buysell       ..\TypeTrees\Tools\alert_log.mtt     & ..\TypeTrees\Parameters\Parameters.mtt   ) ..\TypeTrees\TripleA\Subext_operation.mtt    * ..\TypeTrees\Tools\User_Tools_Function.mtt          ' 0 9 C M X d    User_Tools_Function.  =NONE   Y  OutR = quantity_n * TEXTTONUMBER ( LEFT ( "1000000000" , TEXTTONUMBER ( VLDECQ ) + 1 ))    a  Record:order_alert J =ORD_TA2Alert_Modif_FCT(SubRec:Ext_operation, Parameters, Lookup_AAAEnum)     �  Out� =EITHER(	LOOKUP(	Status_Value Row:Status:Parameters, 
											TRIMRIGHT(TRIMLEFT(Status_Label Row:Status:Parameters)) = TRIMRIGHT(TRIMLEFT(Status))),
		FAIL( "Status " + TEXT(Status) + " not found in parameters list" ))  � Logline Field:Out �=FROMDATETIME ( CURRENTDATE(), "{CCYYMMDD}" )
   + "." + FROMDATETIME ( CURRENTTIME(), "{HH24MMSS}" ) + " : "
   + IF ( LEAVENUM(EXIT (               "%SCRIPTS%/Oly2TA_Alert_Order_Status.sh", /* Arg 1 script name */
                                    code code_t datatype:NewValues:Ext_operation + " "   /* Arg 2 script arguments */
                                    + NUMBERTOTEXT(status_e enum_t datatype:NewValues:Ext_operation) + " "
                                    + "MODIF",
                                    " "  /* Arg 3 not used */
                     	)) = "0" & LASTERRORCODE () = "",
            "ORD_TA2Alert_Modif : INFO : Order alert done: " + code code_t datatype:NewValues:Ext_operation,
            "ORD_TA2Alert_Modif : ERROR : Order alert in error: " + code code_t datatype:NewValues:Ext_operation + " | " 
            		+ TEXT ( LASTERRORMSG () ) + " " + TEXT ( LASTERRORCODE () ) 
            )       	 ! ; v              "                  <       	 
            
                   w                   ʎQW                   icU              	     ���S          
         t5UW       +    Y                :                              7 -   (                                                &   N                                               &    D         )                                     C    e                       q                            D         	                                          e                                                
    e                                                 ;   N                                                 N   Y                                                    e                                                 C   1                                                1 4   Y         	                                      = &   N         	                                      ! -   (         	                                                  �            �    
  @  �	 	      C]�(                           �    
  @  �          �]�(                              �    
  @  �          �A�(                              �    
  @  �          �A�(                              �        @  ��           �A�(                        �    
  @  �          �A�(                              �        @  ��           �A�(    �A�(    " "      LBKCMC Column:Out =" "      LBLTVA Column:Out =" "      LBMDLQ Column:Out =" "      LBORDE Column:Out =" "      LBPMGE Column:Out =" "      LBPMMO Column:Out =" "      LBPMRA Column:Out =" "      LBPMRU Column:Out =" "      LBPTEL Column:Out =" "      LBPYEM Column:Out =" "      LBREM2 Column:Out =" "      LBREM3 Column:Out =" "      LBSENS Column:Out =" "      LBSFRS Column:Out =" "      LBSMRG Column:Out =" "      LBSTA2 Column:Out ="2"      LBSTAR Column:Out =" "      LBSTAT Column:Out ="2"      LBSTMG Column:Out =" "      LBSTVA Column:Out =" "      LBTGRE Column:Out =" "      LBTRDT Column:Out ="0"      LBTYPD Column:Out =" "      LBUTID Column:Out =" "      LBUTIH Column:Out =" "      LSDATT Column:Out =" "      LSHRET Column:Out =" "      LSOPET Column:Out =" "      LBCEX1 Column:Out  =0       LBQMAX Column:Out  =0       LBCOMMNT Column:Out =0      LBCOMPCT Column:Out =0      LBPCTPOS Column:Out =0      LBRABBNQ Column:Out =0      LBRABREM Column:Out =0      IBFIL2 Column:Out ="B "     LBDTTJ Column:Out ="00"     LBDTTM Column:Out ="00"     LBDTVJ Column:Out ="00"     LBDTVM Column:Out ="00"     LBUTIO Column:Out ="  "     FILLER1 Column:Out =" "     LBCPSNO Column:Out =" "     LBFIL21 Column:Out =" "     LBBLCMONT Column:Out =0     LBCRSDECL Column:Out =0     LBMNTKEST Column:Out =0     LSCOLIMTR Column:Out =0     IBORIG Column:Out ="AAA"    LBMTRA Column:Out  =" "     LBREM4 Column:Out  =" "     LBRGRP Column:Out  =" "     LBBLCQTE Column:Out =" "    LBCOMCOD Column:Out =" "    LBDATORD Column:Out =" "    LBDTABNQ Column:Out =" "    LBDTACPT Column:Out =" "    LBEXEOPE Column:Out =" "    LBFACRAC Column:Out =" "    LBHEUORD Column:Out =" "    LBIMMANJ Column:Out =" "    LBNATORD Column:Out =" "    LBNUMDR1 Column:Out =" "    LBNUMDR2 Column:Out =" "    LBPREDEP Column:Out =" "    LBPREDOS Column:Out =" "    LBPREVAL Column:Out =" "    LBPROFTB Column:Out =" "    LBREFEPU Column:Out =" "    LBREFREP Column:Out =" "    LBSEQDEP Column:Out =" "    LBSEQDOS Column:Out =" "    LBSEQVAL Column:Out =" "    LBSOLCLI Column:Out =" "    LBSRCORD Column:Out =" "    LBTRAISI Column:Out =" "    LSDATOSA Column:Out =" "    LSDATREC Column:Out =" "    LSDATVAL Column:Out =" "    LSHEUREC Column:Out =" "    LSREFGLO Column:Out =" "    LBTAUXKS Column:Out  =0     LBCRSCHANG Column:Out =0    LBMNTARRON Column:Out =0    LBDTTA Column:Out ="0000"       LBDTVA Column:Out ="0000"       LBDTRJ Column:Out  ="00"        LBDTRM Column:Out  ="00"        LBCODARRO Column:Out =" "       LBCODCOMM Column:Out =" "       LBCODREGR Column:Out =" "       LBCONTEXE Column:Out =" "       LBCTRNUM1 Column:Out =" "       LBCTRNUM2 Column:Out =" "       LBDATEXEF Column:Out =" "       LBDATIMMA Column:Out =" "       LBDATORDT Column:Out =" "       LBDATREST Column:Out =" "       LBDTABNQE Column:Out =" "       LBDTACPTE Column:Out =" "       LBDTATITE Column:Out =" "       LBFACGENR Column:Out =" "       LBFACMONN Column:Out =" "       LBFACRUBR Column:Out =" "       LBFILLER4 Column:Out =" "       LBFLUXCEN Column:Out =" "       LBFLUXGEN Column:Out =" "       LBFORDET2 Column:Out =" "       LBFORDETC Column:Out =" "       LBFORMDET Column:Out =" "       LBFORMTIT Column:Out =" "       LBFRONTUP Column:Out =" "       LBHEUORDT Column:Out =" "       LBIMMATRI Column:Out =" "       LBINITIAL Column:Out =" "       LBKCOMPTA Column:Out =" "       LBNMVADR1 Column:Out =" "       LBNMVADR2 Column:Out =" "       LBNUMDEP1 Column:Out =" "       LBNUMDEP2 Column:Out =" "       LBOPERTRA Column:Out =" "       LBPLACLIQ Column:Out =" "       LBREFLIEE Column:Out =" "       LBREFRELI Column:Out =" "       LBREGROUP Column:Out =" "       LBREMTRAD Column:Out =" "       LBREQUETE Column:Out =" "       LBRESTNBJ Column:Out =" "       LBROUTAGE Column:Out =" "       LBSOUFRSB Column:Out =" "       LBSTATVIR Column:Out =" "       LBTYPORDR Column:Out =" "       LBVIRTTRA Column:Out =" "       LSDONORDR Column:Out =" "       LBCOURSEX Column:Out  =0        LBEXEDSY Column:Out  =" "       LBEXETSY Column:Out  =" "       LBTRADSY Column:Out  =" "       LBTRAOPE Column:Out  =" "       LBTRATSY Column:Out  =" "       User_Tools_Function. =NONE      LBBLCCRGEN Column:Out =" "      LBBLCCRMON Column:Out =" "      LBBLCCRRAC Column:Out =" "      LBBLCCRRUB Column:Out =" "      LBBLCDBGEN Column:Out =" "      LBBLCDBMON Column:Out =" "      LBBLCDBRAC Column:Out =" "      LBBLCDBRUB Column:Out =" "      LBBLCRACVA Column:Out =" "      LBBLCRUBVA Column:Out =" "      LBCERTIFEX Column:Out =" "      LBCERTIFOB Column:Out =" "      LBCERTINEC Column:Out =" "      LBCERTINEX Column:Out =" "      LBCFRAISET Column:Out =" "      LBCODDOSSI Column:Out =" "      LBCODEKEST Column:Out =" "      LBCODMODCA Column:Out =" "      LBCODPAYDO Column:Out =" "      LBCODTYPKS Column:Out =" "      LBCOURTETR Column:Out =" "      LBCOURTSUI Column:Out =" "      LBDATCOMPT Column:Out =" "      LBDATEPRIX Column:Out =" "      LBDOMSOUMI Column:Out =" "      LBDOSSASSU Column:Out =" "      LBDTATITD1 Column:Out =" "      LBDTATITD2 Column:Out =" "      LBKESTCALC Column:Out =" "      LBOPRASSUJ Column:Out =" "      LBPAYDOMSO Column:Out =" "      LBREFBROK1 Column:Out =" "      LBREFBROK2 Column:Out =" "      LBREFBROK3 Column:Out =" "      LBREFBROK4 Column:Out =" "      LBREINVEST Column:Out =" "      LBTYPSTRAT Column:Out =" "      LBVALASSUJ Column:Out =" "      LSREPORT01 Column:Out =" "      LSREPORT02 Column:Out =" "      LSREPORT03 Column:Out =" "      LSREPORT04 Column:Out =" "      LSREPORT05 Column:Out =" "      LSREPORT06 Column:Out =" "      LSREPORT07 Column:Out =" "      LSREPORT08 Column:Out =" "      LSREPORT09 Column:Out =" "      LSREPORT10 Column:Out =" "      LSREPORT11 Column:Out =" "      LSREPORT12 Column:Out =" "      LSREPORT13 Column:Out =" "      LSREPORT14 Column:Out =" "      LSREPORT15 Column:Out =" "      LBDTRA Column:Out  ="0000"      LBFORDET1 Column:Out  =" "      LBORDR Column:Out
 ="0000000"     LBREGRP Column:Out
 ="0000000"     '  LBCNTP Column:Out =LBSAIH Column:Out  '  LBCTRL Column:Out =LBLOPR Column:Out  '  LBSAIP Column:Out =LBLOPR Column:Out  :  LBREFA Column:Out% =code code_t datatype:.:ext_operation   :  LBREXT Column:Out% =code code_t datatype:.:ext_operation   @  LBDTSY Column:Out+ =DATETOTEXT(CURRENTDATETIME ( "{DDMMYY}" ))     H  LBVALR Column:Out3 =LEFT ( instr code_t datatype:.:ext_operation , 7 )     M  LBTIME Column:Out8 =SUBSTITUTE ( TIMETOTEXT ( CURRENTTIME () ) , ":" , "" )    X  LBCORD Column:OutC =EITHER ( limit_quote_n number_t datatype:.:ext_operation * 1 , 0 )     X  LBSTPL Column:OutC =IF(	order_nat_e enum_t datatype:.:ext_operation = 3,
	"X",
	" ")     Y  OutR = quantity_n * TEXTTONUMBER ( LEFT ( "1000000000" , TEXTTONUMBER ( VLDECQ ) + 1 ))    Z  LBVALS Column:OutE =EITHER(MID ( instr code_t datatype:.:ext_operation , 9 , 3 ), "   ")   a  LBDEPS Column:OutL =EITHER( MID( deposit code_t datatype:NewValues:ext_operation, 8, 3), "000")    b 
 Row:FDBIOBT =ORD_TA2Oly_SecBS_FCT ( 	SubRec:Ext_operation,
				Lookup_AAAEnum ,
			Parameters)   g  LBMOYE Column:OutR =EITHER( ud_communication_type code_t datatype:NewValues:ext_operation, 
		"001")  v  LBOPRN Column:Outa =FILLLEFT(NUMBERTOTEXT(LBLOPR Column:Out),"0",7)
/*20090406 LFA Value is text
LBLOPR Column:Out   �  LBCOPE Column:Out� =EITHER(
IF ( type code_t datatype:.:ext_operation = "NULL" , "   " , MID ( type code_t datatype:.:ext_operation , 5 , 3 )),
"   ")   �  LBLSEQ Column:Out� =IF ( LEFT ( code code_t datatype:.:ext_operation, 3) =  "SEC", TEXTTONUMBER (RIGHT (code code_t datatype:.:ext_operation, 5)), 0   )   �  LBPLBE Column:Out� =IF ( market_third code_t datatype:.:ext_operation = "NULL" ,"000" , RIGHT ( "000" + market_third code_t datatype:.:ext_operation , 3 ))    �  LBPLBO Column:Out� =IF ( market_third code_t datatype:.:ext_operation = "NULL" ,"000" , RIGHT ( "000" + market_third code_t datatype:.:ext_operation , 3 ))    �  LBNMCR Column:Out� =IF( op_currency code_t datatype:NewValues:ext_operation = "1", 
	756,
	EITHER( TEXTTONUMBER( op_currency code_t datatype:NewValues:ext_operation), 0))   �  LBREFE Column:Out � =" "

/*=IF( parent_oper_nat_e enum_t datatype:NewValues:ext_operation = 3, 
	TRIMRIGHT( TRIMLEFT( accounting_code code_t datatype:NewValues:ext_operation)),
	" ")*/      �  LBDORA Column:Out� =IF( operation_d datetime_t datatype:.:ext_operation = NONE, "0000",
LEFT ( DATETOTEXT ( NUMBERTODATE ( DATETONUMBER ( operation_d datetime_t datatype:.:ext_operation ))) , 4 ))  �  LBDTOA Column:Out� =IF( operation_d datetime_t datatype:.:ext_operation = NONE, "0000",
LEFT ( DATETOTEXT ( NUMBERTODATE ( DATETONUMBER ( operation_d datetime_t datatype:.:ext_operation ))) , 4 ))  �  LBDORM Column:Out� =IF( operation_d datetime_t datatype:.:ext_operation = NONE, "00",
MID ( DATETOTEXT ( NUMBERTODATE ( DATETONUMBER ( operation_d datetime_t datatype:.:ext_operation ))) , 5 , 2 ))     �  LBDTOM Column:Out� =IF( operation_d datetime_t datatype:.:ext_operation = NONE, "00",
MID ( DATETOTEXT ( NUMBERTODATE ( DATETONUMBER ( operation_d datetime_t datatype:.:ext_operation ))) , 5 , 2 ))     �  LBSTBL Column:Out� =" "

/* EDB 20090515
=IF(	ud_transmission_d datetime_t datatype:.:ext_operation = NONE,
	IF ( 	market_third code_t datatype:.:ext_operation = "NULL" ,
		"A",
		"B"), 
	"T")    �  LBDVLA Column:Out� =IF( order_limit_d datetime_t datatype:.:ext_operation =NONE, "0000",
LEFT ( DATETOTEXT ( NUMBERTODATE ( DATETONUMBER ( order_limit_d datetime_t datatype:.:ext_operation ))) , 4 ))   �  LBDVLJ Column:Out� =IF( order_limit_d datetime_t datatype:.:ext_operation = NONE, "00",
MID ( DATETOTEXT ( NUMBERTODATE ( DATETONUMBER ( order_limit_d datetime_t datatype:.:ext_operation ))) , 7 , 2 ))     �  LBDVLM Column:Out� =IF( order_limit_d datetime_t datatype:.:ext_operation = NONE, "00",
MID ( DATETOTEXT ( NUMBERTODATE ( DATETONUMBER ( order_limit_d datetime_t datatype:.:ext_operation ))) , 5 , 2 ))     �  LBDORJ Column:Out � =IF( operation_d datetime_t datatype:.:ext_operation = NONE, "00",
		MID ( DATETOTEXT ( NUMBERTODATE ( DATETONUMBER ( operation_d datetime_t datatype:.:ext_operation ))) , 7 , 2 ))      �  LBREM1 Column:Out � =IF(	remark_2_c info_t datatype:.:ext_operation = "NULL" | remark_2_c info_t datatype:.:ext_operation = NONE,
		" ",
		TRIMRIGHT(TRIMLEFT(remark_2_c info_t datatype:.:ext_operation)))      �  LBDTOJ Column:Out� =IF( operation_d datetime_t datatype:.:ext_operation = NONE, "00",
MID ( DATETOTEXT ( NUMBERTODATE ( DATETONUMBER ( operation_d datetime_t datatype:.:ext_operation ))) , 7 , 2 ))
/*LBDVLA Column:Out*/  �  LBCLIR Column:Out� =IF( 	TRIMLEFT( portfolio code_t datatype:.:ext_operation, INF_Portfolio_Code Row:Rec01:Parameters) = "NULL",
	" ",
	LEFT ( TRIMLEFT( portfolio code_t datatype:.:ext_operation, INF_Portfolio_Code Row:Rec01:Parameters) , 7))   �  LBCLIS Column:Out � ="000"

/*=IF( ud_household_ptf code_t datatype:NewValues:ext_operation = "000" | ud_household_ptf code_t datatype:NewValues:ext_operation = NONE, 
	"000",
	MID( ud_household_ptf code_t datatype:NewValues:ext_operation, 9, 3))       LBCRAC Column:Out � =IF ( 	intermed_third code_t datatype:.:ext_operation = "NULL" | intermed_third code_t datatype:.:ext_operation = NONE,
	"0000000" ,
	TRIMLEFT( intermed_third code_t datatype:.:ext_operation, INF_Deposit_Code Row:Rec01:Parameters))       LBCONS Column:Out=FILLLEFT(NUMBERTOTEXT(LBLOPR Column:Out),"0",7)
/*20090406 LFA Value is text
LBLOPR Column:Out
/*
=IF(	manager code_t datatype:.:ext_operation = "NULL",
	" ",
	TRIMLEFT(INF_Manager_Code Row:Rec01:Parameters,manager code_t datatype:.:ext_operation  ))
*/   : IBCDGC Column:Out $=IF(	status_e enum_t datatype:.:ext_operation =  
		EITHER(	LOOKUP(	Status_Value Row:Status:RecStatus:Parameters, 
					Status_Label Row:Status:RecStatus:Parameters = "Cancellation To Send"),
			FAIL( "Status " + "Cancellation To Send" + " not found in parameters list" )), 
	" ",
	"C")    b LBLID Column:Out M=IF(	status_e enum_t datatype:.:ext_operation = 
		EITHER(	LOOKUP(	Status_Value Row:Status:RecStatus:Parameters, 
					Status_Label Row:Status:RecStatus:Parameters = "Cancellation To Send"),
			FAIL( "Status " + " Cancellation To Send" + " not found in parameters list" )), 
	/* THEN status = ToCancel */ 	100,
	/* ELSE */			0)    d LBRAC Column:OutP=IF(	SIZE ( TRIMLEFT( account code_t datatype:.:ext_operation, INS_CashAccount_Code Row:Rec01:Parameters) ) < 8 ,
		LEFT ( TRIMLEFT( portfolio code_t datatype:.:ext_operation, INF_Portfolio_Code Row:Rec01:Parameters) , 7),
		MID ( TRIMLEFT( account code_t datatype:.:ext_operation, INS_CashAccount_Code Row:Rec01:Parameters) , 1, 7) )     d LBDEPR Column:Out N= IF(deposit code_t datatype:.:ext_operation = "NULL" | deposit code_t datatype:.:ext_operation = NONE | 
           TRIMLEFT(deposit code_t datatype:.:ext_operation,INF_Deposit_Code Row:Rec01:Parameters) = "NULL", 
	"0000000",
	LEFT ( TRIMLEFT(deposit code_t datatype:.:ext_operation,INF_Deposit_Code Row:Rec01:Parameters), 7)  )      z LBLREF Column:Out d= IF ( status_e enum_t datatype:.:ext_operation = 
	EITHER(	LOOKUP(Status_Value Row:Status:RecStatus:Parameters, Status_Label Row:Status:RecStatus:Parameters = "Cancellation To Send"),
							FAIL( "Status " + " Cancellation To Send" + " not found in parameters list" )
							),
			TEXTTONUMBER( accounting_code code_t datatype:.:ext_operation),
	0)    � IBREF Column:Out �=IF(	status_e enum_t datatype:.:ext_operation=
		EITHER(	LOOKUP(	Status_Value Row:Status:RecStatus:Parameters, 
						Status_Label Row:Status:RecStatus:Parameters = "Cancellation To Send"),
			FAIL( "Status " + "Cancellation To Send" + " not found in parameters list" )),
	MID ( source_code code_t datatype:.:ext_operation,4,16)+"A",
				MID ( code code_t datatype:.:ext_operation , 4 , 16 ))   � LBREMI Column:Out �=IF(	ud_trading_reference shortinfo_t datatype:.:ext_operation = "NULL" | ud_trading_reference shortinfo_t datatype:.:ext_operation = NONE,
		"",
		TRIMRIGHT(TRIMLEFT(ud_trading_reference shortinfo_t datatype:.:ext_operation)) + " ") +
IF(	remark_3_c info_t datatype:.:ext_operation = "NULL" | remark_3_c info_t datatype:.:ext_operation = NONE,
		" ",
		TRIMRIGHT(TRIMLEFT(remark_3_c info_t datatype:.:ext_operation)))    � LBQORD Column:Out�= User_Quant_FCT ( quantity_n number_t datatype:.:ext_operation ,
EITHER ( 
VALID(
     DBLOOKUP ( "SELECT VLDECQ From %OLYLIB%.FDBVAL Where VLVALR = '" + LEFT ( instr code_t datatype:.:ext_operation , 7 ) + "' AND VLVALS = '" +
      MID ( instr code_t datatype:.:ext_operation , 9 , 3 ) + "' " , "-DBTYPE DB2 -DS %SOURCE% -US %USER% -PW %PASSWORD% -TE FDBVAL.dbl " ) ,
     FAIL ( TEXT ( "Error in SELECT VLDECQ" ))),"0"))   � LBLOPR Column:Out�=IF( ud_operant_n number_t datatype:NewValues:ext_operation != 0 
		& ud_operant_n number_t datatype:NewValues:ext_operation != NONE, 
	ud_operant_n number_t datatype:NewValues:ext_operation, 
	TEXTTONUMBER( ORD_OlympicOperator Row:Rec01:Parameters))

/*20090403 LFA Value is Number
FILLLEFT( NUMBERTOTEXT( EITHER ( 
	ud_operant_n number_t datatype:.:ext_operation ,
		ORD_OlympicOperator Row:Rec01:Parameters)),
	"0", 7)  � IBACTI Column:Out �=IF(	status_e enum_t datatype:.:ext_operation=
		EITHER(	LOOKUP(	Status_Value Row:Status:RecStatus:Parameters, 
					Status_Label Row:Status:RecStatus:Parameters = "Cancellation To Send"),
			FAIL( "Status " + "Cancellation To Send" + " not found in parameters list" )),
	/* THEN status = ToCancel */			"A",
			IF( parent_oper_nat_e enum_t datatype:NewValues:ext_operation = 2,
	/* Group Order  */							"Z",
	/* ELSE status = ToBeTransmitted */		"T"))    ; LBGRE Column:Out'=IF( 	MEMBER(	ref_nat_e enum_t datatype:.:ext_operation, {7,8} ),
	IF(	SIZE ( TRIMLEFT( account2 code_t datatype:.:ext_operation, INS_CashAccount_Code Row:Rec01:Parameters) ) < 11 ,
		"001" ,
		MID ( TRIMLEFT( account2 code_t datatype:.:ext_operation, INS_CashAccount_Code Row:Rec01:Parameters)  , 9, 3) ),
	IF(	SIZE ( TRIMLEFT( account code_t datatype:.:ext_operation, INS_CashAccount_Code Row:Rec01:Parameters) ) < 11 ,
		"001" ,
		MID ( TRIMLEFT( account code_t datatype:.:ext_operation, INS_CashAccount_Code Row:Rec01:Parameters)  , 9, 3) ))  < LBRUB Column:Out(=IF( 	MEMBER(	ref_nat_e enum_t datatype:.:ext_operation, {7,8} ),
	IF(	SIZE ( TRIMLEFT( account2 code_t datatype:.:ext_operation, INS_CashAccount_Code Row:Rec01:Parameters) ) < 15 ,
		"000" ,
		MID ( TRIMLEFT( account2 code_t datatype:.:ext_operation, INS_CashAccount_Code Row:Rec01:Parameters) , 13, 3) ),
	IF(	SIZE ( TRIMLEFT( account code_t datatype:.:ext_operation, INS_CashAccount_Code Row:Rec01:Parameters) ) < 15 ,
		"000" ,
		MID ( TRIMLEFT( account code_t datatype:.:ext_operation, INS_CashAccount_Code Row:Rec01:Parameters)  , 13, 3) ))     � LBMON Column:Out�=IF( 	MEMBER(	ref_nat_e enum_t datatype:.:ext_operation, {7,8} ),
	IF(	SIZE ( TRIMLEFT( account2 code_t datatype:.:ext_operation, INS_CashAccount_Code Row:Rec01:Parameters) ) < 19 ,
		"000" ,
		MID ( TRIMLEFT( account2 code_t datatype:.:ext_operation, INS_CashAccount_Code Row:Rec01:Parameters), 17, 3) ),
	IF(	SIZE ( TRIMLEFT( account code_t datatype:.:ext_operation, INS_CashAccount_Code Row:Rec01:Parameters) ) < 19 ,
		MID ( TRIMLEFT( account code_t datatype:.:ext_operation, INS_CashAccount_Code Row:Rec01:Parameters) , 1, 3) ,
		MID ( TRIMLEFT( account code_t datatype:.:ext_operation, INS_CashAccount_Code Row:Rec01:Parameters) , 17, 3) ))      LBFILL Column:Out �=EITHER(
IF( target_m amount_t datatype:NewValues:ext_operation != 0 & target_m amount_t datatype:NewValues:ext_operation != NONE, 
	"          00000     Y0100000%0M"
	+	FILLRIGHT( "0", "0", 50)
	+ FILLLEFT( NUMBERTOTEXT( INT( EITHER(  target_m amount_t datatype:NewValues:ext_operation * 100, 0))), "0", 15)
	+ FILLLEFT( NUMBERTOTEXT( INT( EITHER(  target_m amount_t datatype:NewValues:ext_operation * 100, 0))), "0", 15) 
	+ FILLRIGHT( "0", "0", 262)	
	+ FILLLEFT( NUMBERTOTEXT( INT( EITHER(  target_m amount_t datatype:NewValues:ext_operation * 100, 0))), "0", 15) 
	
	+IF( 	MEMBER(	ref_nat_e enum_t datatype:.:ext_operation, {7,8} ),
	IF(	SIZE ( TRIMLEFT( account2 code_t datatype:.:ext_operation, INS_CashAccount_Code Row:Rec01:Parameters) ) < 19 ,
		"000" ,
		MID ( TRIMLEFT( account2 code_t datatype:.:ext_operation, INS_CashAccount_Code Row:Rec01:Parameters), 17, 3) ),
	IF(	SIZE ( TRIMLEFT( account code_t datatype:.:ext_operation, INS_CashAccount_Code Row:Rec01:Parameters) ) < 19 ,
		MID ( TRIMLEFT( account code_t datatype:.:ext_operation, INS_CashAccount_Code Row:Rec01:Parameters) , 1, 3) ,
		MID ( TRIMLEFT( account code_t datatype:.:ext_operation, INS_CashAccount_Code Row:Rec01:Parameters) , 17, 3) ))
	
	+ FILLRIGHT( "0", "0", 22)),
	" ")          # * 1 8 ? F M T [ b i p w ~ � � � � � � � � � � � � � � � � � � 
&-4;BIPW^elsz������������������'/7?GOW_gow����������������'/7?GOW_gow����������������'/7?GOW_gow����������������'/7?GOW_gow�������������� 	$-6?HQZclu~�������������� )2;DMV_hqz��������������
%.7@IR[dmv��������������			!	*	3	<	E	N	W	`	i	r	{	�	�	�	�	�	�	�	�	�	�	�	

.
F
^
v
�
�
�
�
�
$Lu���0c���3h��A��K��P�u�X�D�e  FDBIOB    Olympic  a -DT DB2 -UPDATE -T out_sec_bs.dbl  -SOURCE %SOURCE% -US %USER% -PW %PASSWORD% -TABLE %OLY2TA_IOB%                   �
�                �L�� ��%�h`�	Y�B
w
Q�
�
��E�f�v��d4i �/
`h��Pv� �
M���	����� �	��	�
x@pXH�1@H�08�8t�{9 �@ �G �j �C� � ��  2  0 q x � � ��\ + c U � �� .5JQX_fm '<�	��	� � � G
� ��  $ � � (�P�X� ��P����@0H8���� � �N � x����	���(�(
	����	h�	���{����p���������`������`�<�*��w����.7@���  H��P��@�3%��8��	��en/S��8��A��&J\�����p �(X�I[R�rxW��N`
��!vm0 hEd����i			"	+	4	=	F	O	X	a	j	s	|	�	� �����x�p��X� � 	 
            _
                  ��	T             `     ��U          ^  _  `     ���S           Y                 D                              *    2                                                   N                                                +   ;                e                         7    q                       q                        $    Y                                               0    )                                                    N                                                 #   ;                                                 ?   Y                                                    q                                                 4   ;                                                            �            �    
  @  �	 	      C]�(                           �    
  @  �          �]�(                              �    
  @  �          �A�(         ?   Y                                                    q                                                 4   ;                                                            �            �    
  @  �	 	      C]�(                           �    
  @  �          �]�(                              �    
  @  �          �A�(                        �            �    
  @  �	 	      C]�(                           �    
  @  �          �]�(                              �    
  @  �          �A�(        