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
top 1
[WORK_AREA_PARENT_SOURCE_ID],
 [RollupPracticeAreaName] as PracticeArea
,app.[currency_code] as CurrencyCode
,sum(([Auto_Review_Exp_Appeal_Amount]+ [Auto_Review_Fee_Appeal_Amount] +
    [Reviewer_Exp_Appeal_Amount] + [Reviewer_Fee_Appeal_Amount] +
    [Vendor_Exp_Appeal_Amount] + [Vendor_Fee_Appeal_Amount])) as appealAmount
,adj.adjustmentAmount
,(sum(([Auto_Review_Exp_Appeal_Amount]+ [Auto_Review_Fee_Appeal_Amount] +
    [Reviewer_Exp_Appeal_Amount] + [Reviewer_Fee_Appeal_Amount] +
    [Vendor_Exp_Appeal_Amount] + [Vendor_Fee_Appeal_Amount]))/
	adj.adjustmentAmount) * 100 [Appeal %]

FROM LA_DATAMART.[dbo].[V_summary_invoice_line_item] app

	INNER JOIN dim_work_area_bridge PAD ON app.work_area_nk = PAD.work_area_child_source_id
	INNER JOIN ( SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
		FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',-1,1) ) PAS ON (PAD.work_area_parent_source_id = PAS.RollupPracticeAreaId)


	join (select 
		sum(-([auto_review_fee_adj_amount]+[auto_review_exp_adj_amount]+[reviewer_fee_adj_amount]+[Reviewer_Exp_Adj_Amount])) as adjustmentAmount
		,rolluppracticeareaid
		,currency_code
	FROM LA_DATAMART.[dbo].[V_summary_invoice_line_item] abj
		INNER JOIN dim_work_area_bridge PAD ON abj.work_area_nk = PAD.work_area_child_source_id
		INNER JOIN ( SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
			FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',-1,1) ) PAS ON (PAD.work_area_parent_source_id = PAS.RollupPracticeAreaId)

	WHERE
	review_status IN (''' + @ReviewStatus + ''')     
	AND (invoice_date >= ''' + @pDateStart + ''' AND invoice_date<= ''' + @pDateEnd + ''') 
	group by
	currency_code,
    rolluppracticeareaid 
	)
	
	adj ON adj.rolluppracticeareaid = PAS.rolluppracticeareaid
	and adj.currency_code = app.currency_code

WHERE
	review_status IN (''' + @ReviewStatus + ''')     
	AND (invoice_date >= ''' + @pDateStart + ''' AND invoice_date<= ''' + @pDateEnd + ''') 
group by
	WORK_AREA_PARENT_SOURCE_ID,
    app.currency_code
    ,[RollupPracticeAreaName]
	,adj.adjustmentAmount

 HAVING
 sum([auto_review_fee_adj_amount]+[auto_review_exp_adj_amount]+[reviewer_fee_adj_amount]+[Reviewer_Exp_Adj_Amount])<> 0 OR
 sum(-([auto_review_fee_adj_amount]+[auto_review_exp_adj_amount]+[reviewer_fee_adj_amount]+[Reviewer_Exp_Adj_Amount]+[Auto_Review_Exp_Appeal_Amount]+ [Auto_Review_Fee_Appeal_Amount] +
    [Reviewer_Exp_Appeal_Amount] + [Reviewer_Fee_Appeal_Amount] +
    [Vendor_Exp_Appeal_Amount] + [Vendor_Fee_Appeal_Amount])) <>0 

order by appealAmount desc' 

Print @SQL 
EXEC(@SQL)
