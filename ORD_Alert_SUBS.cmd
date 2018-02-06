SET DECIMAL ,
SET DATAFORMAT DELIMITED
SET SEPARATOR ~
SET PREFIX DATA NONE
SET QUOTE NONE
SET DATEFORMAT DD-MM-YYYY:HH:II:SS

CMD INSUPD map
ATT code denom entity_dict_id.sqlname_c storage_c
ORD_Alert_Modif~Order Modification Alerts~ext_operation~/appl/toi/maps/ORD_TA2Alert_Modif.mmc~
ORD_Alert_Status~Order Status Alerts~ext_operation~/appl/toi/maps/ORD_TA2Alert_Status.mmc~

CMD INSUPD subscription
ATT code denom nature_e begin_d end_d entity_dict_id.sqlname_c action_e module_e format_id.code map_id.code min_oper_status_e max_oper_status_e update_status_c destination_c priority_n business_entity_selection_e request_status_e event_status_f event_init_status_e event_grouping_e
ORD_Alert_ExecMod~Order Execution Modification Alert~1~01-07-2014:00:00:00~~ext_operation~2~4~NULL~ORD_Alert_Modif~75~78~NULL~OLYMPIC~0.000000000~0~20~0~0~0~
ORD_Alert_Exec~Order Execution Alert~1~01-07-2014:00:00:00~~ext_operation~2~4~NULL~ORD_Alert_Status~75~78~NULL~OLYMPIC~0.000000000~0~20~0~0~0~
ORD_Alert_ITR~Order Potential Insider Trading Alert~1~01-07-2014:00:00:00~~ext_operation~4~2~NULL~ORD_Alert_Status~0~45~NULL~OLYMPIC~0.000000000~0~20~0~0~0~
ORD_Alert_Reject~Order Rejected Alert~1~01-07-2014:00:00:00~~ext_operation~2~4~NULL~ORD_Alert_Status~15~15~NULL~OLYMPIC~0.000000000~0~20~0~0~0~
ORD_Cancel_Refused~ORD_Cancel_Refused~1~01-01-2016:00:00:00~~ext_operation~2~2~NULL~ORD_Alert_Status~45~75~NULL~OLYMPIC~0.000000000~0~20~0~0~0~
ORD_Modif_Refused~ORD_Modif_Refused~1~01-01-2016:00:00:00~~ext_operation~2~2~NULL~ORD_Alert_Status~45~75~NULL~OLYMPIC~0.000000000~0~20~0~0~0~

CMD INSUPD script_definition subscription
ATT attribute.sqlname_c attribute.entity.sqlname_c object_id.code nature_e rank_n definition_c dim_entity.sqlname_c script_ent_ref.sqlname_c action_e
script_definition~subscription~ORD_Alert_Exec~0~0~(type_id.code IN ("SEC-ACT","SEC-VCT","SEC-SOU")\nOR type_id.code IN ("SEC-AOO","SEC-AOC","SEC-VOO","SEC-VOC")\nOR type_id.code IN ("SEC-AFO","SEC-AFC","SEC-VFO","SEC-VFC")\nOR (type_id.code IN ("SEC-SFI","SEC-VFI")  AND input_user_id.manager_id.external_f=1~subscription~subscription~0~
script_definition~subscription~ORD_Alert_Exec~0~1~))\nAND nature_e IN (1,2) AND portfolio_id.active_f=1 AND instr_id.active_f=1 AND status_e IN (75, 78)\nAND (parent_oper_nat_e IN (0,2) OR (parent_oper_nat_e=3 AND portfolio_id.service_type_e IN (0,2,3)) )\nAND ( ud_executed_qty0_n <> OLD().ud_executed_qty0_~subscription~subscription~0~
script_definition~subscription~ORD_Alert_Exec~0~2~n\nOR ud_executed_qty1_n <> OLD().ud_executed_qty1_n\nOR ud_executed_qty2_n <> OLD().ud_executed_qty2_n\nOR ud_executed_qty3_n <> OLD().ud_executed_qty3_n\nOR ud_executed_qty4_n <> OLD().ud_executed_qty4_n\nOR ud_executed_qty5_n <> OLD().ud_executed_qty5_n\nOR~subscription~subscription~0~
script_definition~subscription~ORD_Alert_Exec~0~3~ ud_executed_qty6_n <> OLD().ud_executed_qty6_n\nOR ud_executed_qty7_n <> OLD().ud_executed_qty7_n\nOR ud_executed_qty8_n <> OLD().ud_executed_qty8_n\nOR ud_executed_qty9_n <> OLD().ud_executed_qty9_n\nOR ud_executed_qty10_n <> OLD().ud_executed_qty10_n)~subscription~subscription~0~
script_definition~subscription~ORD_Alert_ExecMod~0~0~(type_id.code IN ("SEC-ACT","SEC-VCT","SEC-SOU")\nOR type_id.code IN ("SEC-AOO","SEC-AOC","SEC-VOO","SEC-VOC")\nOR type_id.code IN ("SEC-AFO","SEC-AFC","SEC-VFO","SEC-VFC")\nOR (type_id.code IN ("SEC-SFI","SEC-VFI")  AND input_user_id.manager_id.external_f=1~subscription~subscription~0~
script_definition~subscription~ORD_Alert_ExecMod~0~1~))\nAND nature_e IN (1,2) AND portfolio_id.active_f=1 AND instr_id.active_f=1 AND status_e IN (75, 78)\nAND (parent_oper_nat_e IN (0,2) OR (parent_oper_nat_e=3 AND portfolio_id.service_type_e IN (0,2,3)) )\nAND ( ( (OLD().ud_executed_price0_n!=NULL AND OLD()~subscription~subscription~0~
script_definition~subscription~ORD_Alert_ExecMod~0~2~.ud_executed_price0_n<>ud_executed_price0_n)\nOR (OLD().ud_executed_price1_n!=NULL AND OLD().ud_executed_price1_n<>ud_executed_price1_n)\nOR (OLD().ud_executed_price2_n!=NULL AND OLD().ud_executed_price2_n<>ud_executed_price2_n)\nOR (OLD().ud_executed_price3~subscription~subscription~0~
script_definition~subscription~ORD_Alert_ExecMod~0~3~_n!=NULL AND OLD().ud_executed_price3_n<>ud_executed_price3_n)\nOR (OLD().ud_executed_price4_n!=NULL AND OLD().ud_executed_price4_n<>ud_executed_price4_n)\nOR (OLD().ud_executed_price5_n!=NULL AND OLD().ud_executed_price5_n<>ud_executed_price5_n)\nOR (OLD().~subscription~subscription~0~
script_definition~subscription~ORD_Alert_ExecMod~0~4~ud_executed_price6_n!=NULL AND OLD().ud_executed_price6_n<>ud_executed_price6_n)\nOR (OLD().ud_executed_price7_n!=NULL AND OLD().ud_executed_price7_n<>ud_executed_price7_n)\nOR (OLD().ud_executed_price8_n!=NULL AND OLD().ud_executed_price8_n<>ud_executed_pr~subscription~subscription~0~
script_definition~subscription~ORD_Alert_ExecMod~0~5~ice8_n)\nOR (OLD().ud_executed_price9_n!=NULL AND OLD().ud_executed_price9_n<>ud_executed_price9_n)\nOR (OLD().ud_executed_price10_n!=NULL AND OLD().ud_executed_price10_n<>ud_executed_price10_n) )\nOR ( (OLD().ud_executed_qty0_n!=NULL AND OLD().ud_executed_q~subscription~subscription~0~
script_definition~subscription~ORD_Alert_ExecMod~0~6~ty0_n!=0 AND OLD().ud_executed_qty0_n<>ud_executed_qty0_n)\nOR (OLD().ud_executed_qty1_n!=NULL AND OLD().ud_executed_qty1_n!=0 AND OLD().ud_executed_qty1_n<>ud_executed_qty1_n)\nOR (OLD().ud_executed_qty2_n!=NULL AND OLD().ud_executed_qty2_n!=0 AND OLD().ud~subscription~subscription~0~
script_definition~subscription~ORD_Alert_ExecMod~0~7~_executed_qty2_n<>ud_executed_qty2_n)\nOR (OLD().ud_executed_qty3_n!=NULL AND OLD().ud_executed_qty3_n!=0 AND OLD().ud_executed_qty3_n<>ud_executed_qty3_n)\nOR (OLD().ud_executed_qty4_n!=NULL AND OLD().ud_executed_qty4_n!=0 AND OLD().ud_executed_qty4_n<>ud_~subscription~subscription~0~
script_definition~subscription~ORD_Alert_ExecMod~0~8~executed_qty4_n)\nOR (OLD().ud_executed_qty5_n!=NULL AND OLD().ud_executed_qty5_n!=0 AND OLD().ud_executed_qty5_n<>ud_executed_qty5_n)\nOR (OLD().ud_executed_qty6_n!=NULL AND OLD().ud_executed_qty6_n!=0 AND OLD().ud_executed_qty6_n<>ud_executed_qty6_n)\nOR (~subscription~subscription~0~
script_definition~subscription~ORD_Alert_ExecMod~0~9~OLD().ud_executed_qty7_n!=NULL AND OLD().ud_executed_qty7_n!=0 AND OLD().ud_executed_qty7_n<>ud_executed_qty7_n)\nOR (OLD().ud_executed_qty8_n!=NULL AND OLD().ud_executed_qty8_n!=0 AND OLD().ud_executed_qty8_n<>ud_executed_qty8_n)\nOR (OLD().ud_executed_qty~subscription~subscription~0~
script_definition~subscription~ORD_Alert_ExecMod~0~10~9_n!=NULL AND OLD().ud_executed_qty9_n!=0 AND OLD().ud_executed_qty9_n<>ud_executed_qty9_n)\nOR (OLD().ud_executed_qty10_n!=NULL AND OLD().ud_executed_qty10_n!=0 AND OLD().ud_executed_qty10_n<>ud_executed_qty10_n) ) )~subscription~subscription~0~
script_definition~subscription~ORD_Alert_ITR~0~0~nature_e IN (1,2) AND portfolio_id.active_f=1 AND instr_id.active_f=1 AND instr_id.IS_IN_LIST["BHI_OE_FILTER_ITR"] {only select order that are new, eg. to be treated with old status not to be treated and not to be blocked / and only select orders that a~subscription~subscription~0~
script_definition~subscription~ORD_Alert_ITR~0~1~re being cancelled before executed, e.g. to be treated, blocked, partially exec, - be aware that cancellation could be due to archiving.} AND ((status_e = 45 AND NOT(OLD().status_e IN (45,70))) OR (status_e=0 AND OLD().status_e IN (45,70) ))~subscription~subscription~0~
script_definition~subscription~ORD_Alert_Reject~0~0~LEFT(code,3)="AAA" AND status_e = 15 AND NOT(OLD().status_e IN (0,15))~subscription~subscription~0~

