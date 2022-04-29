--USE LA_DATAMART
--GO 

Exec as user='admin'

DECLARE @pDateStart varchar (50); 
DECLARE @pDateEnd varchar (50); 
DECLARE @ReviewStatus varchar (1000); 
DECLARE @CurrencyCode varchar (50); 
DECLARE @SQL VARCHAR(4000);  

SET @pDateStart= ^StartDate^; 
SET @pDateEnd= ^EndDate^; 
SET @ReviewStatus= ^ReviewStatus^; 
SET @CurrencyCode= ^Currency^;  

--SET @pDateStart='01/01/2020'; 
--SET @pDateEnd='05/31/2021'; 
--SET @ReviewStatus = 'Complete'',''In LBA Review'; 
--SET @CurrencyCode='-1';   

SET @SQL=' 
Select
	matter_name as ''Matter Name'',
	matter_number as ''Matter Number'',
	currency_code as ''Currency Code'',

	-sum(([auto_review_fee_adj_amount]+[auto_review_exp_adj_amount]+[reviewer_fee_adj_amount]+[reviewer_exp_adj_amount])+
	([auto_review_exp_appeal_amount]+ [auto_review_fee_appeal_amount] +[reviewer_exp_appeal_amount] + [reviewer_fee_appeal_amount] +[vendor_exp_appeal_amount] + [vendor_fee_appeal_amount]))
	as ''Net Adjustment Amount'', 

	-sum([auto_review_fee_adj_amount]+[auto_review_exp_adj_amount]+[reviewer_fee_adj_amount]+[reviewer_exp_adj_amount]) as ''Gross Adjustment Amount'' ,

 sum(gross_fee_amount+ gross_exp_amount+vendor_fee_adj_amount+vendor_exp_adj_amount ) AS ''Fees Plus Expense''

 from v_summary_invoice_line_item as ili

 INNER JOIN dim_work_area_bridge PAD ON ili.work_area_nk = PAD.work_area_child_source_id
	INNER JOIN ( SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
               FROM [fn_GetRollupPracticeAreasWithSecurity2](-1,''|'',1,0) ) PAS ON (PAD.work_area_parent_source_id = PAS.RollupPracticeAreaId)

 where 
	review_status IN (''' + @ReviewStatus + ''')     
	AND (invoice_date >= ''' + @pDateStart + ''' AND invoice_date<= ''' + @pDateEnd + ''') 
	AND vendor_nk = ^ParamOne^

 group by matter_name,matter_number,currency_code,matter_nk
 
 having
  sum([auto_review_fee_adj_amount]+[auto_review_exp_adj_amount]+[reviewer_fee_adj_amount]+[reviewer_exp_adj_amount]) <>0
 or 
 sum(-(([auto_review_fee_adj_amount]+[auto_review_exp_adj_amount]+[reviewer_fee_adj_amount]+[reviewer_exp_adj_amount])
+
([auto_review_exp_appeal_amount]+ [auto_review_fee_appeal_amount] +[reviewer_exp_appeal_amount] + [reviewer_fee_appeal_amount] +[vendor_exp_appeal_amount] + [vendor_fee_appeal_amount]))) <> 0

 order by ''Net Adjustment Amount'' desc, matter_name' 

Print @SQL 
EXEC(@SQL)

