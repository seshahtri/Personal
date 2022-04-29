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
select
	[vendor_name]
	,app.[currency_code]
	,sum(([Auto_Review_Exp_Appeal_Amount]+ [Auto_Review_Fee_Appeal_Amount] +
	[Reviewer_Exp_Appeal_Amount] + [Reviewer_Fee_Appeal_Amount] +
	[Vendor_Exp_Appeal_Amount] + [Vendor_Fee_Appeal_Amount])) as appealAmount
	,(sum(([Auto_Review_Exp_Appeal_Amount]+ [Auto_Review_Fee_Appeal_Amount] +
	[Reviewer_Exp_Appeal_Amount] + [Reviewer_Fee_Appeal_Amount] +
	[Vendor_Exp_Appeal_Amount] + [Vendor_Fee_Appeal_Amount]))/
	adj.adjustmentAmount) * 100 as ''Appeals %''
	,adj.adjustmentAmount
FROM v_summary_invoice_line_item app
 join (
 select
  currency_code,
	sum(-([auto_review_fee_adj_amount]+[auto_review_exp_adj_amount]+[reviewer_fee_adj_amount]+[Reviewer_Exp_Adj_Amount])) as adjustmentAmount
	,[vendor_NK]
	FROM v_summary_invoice_line_item adj
		INNER JOIN dim_work_area_bridge PAD ON adj.work_area_nk = PAD.work_area_child_source_id
		INNER JOIN ( SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
		FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',^ParamOne^,0) ) PAS ON (PAD.work_area_parent_source_id = PAS.RollupPracticeAreaId)

WHERE
	review_status IN (''' + @ReviewStatus + ''')     
	AND (invoice_date >= ''' + @pDateStart + ''' AND invoice_date<= ''' + @pDateEnd + ''') 
group by
vendor_NK,
currency_code
)
adj ON adj.[vendor_NK] = app.[vendor_NK]
and adj.currency_code = app.currency_code

INNER JOIN dim_work_area_bridge PAD ON app.work_area_nk = PAD.work_area_child_source_id
INNER JOIN ( SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',^ParamOne^,0) ) PAS ON (PAD.work_area_parent_source_id = PAS.RollupPracticeAreaId)


WHERE
	review_status IN (''' + @ReviewStatus + ''')     
	AND (invoice_date >= ''' + @pDateStart + ''' AND invoice_date<= ''' + @pDateEnd + ''') 
group by
app.currency_code
,currency_symbol
,vendor_name
,app.vendor_NK
,adj.adjustmentAmount
 HAVING
sum([auto_review_fee_adj_amount]+[auto_review_exp_adj_amount]+[reviewer_fee_adj_amount]+[Reviewer_Exp_Adj_Amount])<> 0 OR
sum(-([auto_review_fee_adj_amount]+[auto_review_exp_adj_amount]+[reviewer_fee_adj_amount]+[Reviewer_Exp_Adj_Amount]+[Auto_Review_Exp_Appeal_Amount]+ [Auto_Review_Fee_Appeal_Amount] +
[Reviewer_Exp_Appeal_Amount] + [Reviewer_Fee_Appeal_Amount] +
[Vendor_Exp_Appeal_Amount] + [Vendor_Fee_Appeal_Amount])) <>0
order by appealAmount desc' 

Print @SQL 
EXEC(@SQL)




