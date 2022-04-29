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
 [RollupPracticeAreaName] as PracticeAreaName 	
,[currency_code]
,sum(-([auto_review_fee_adj_amount]+[auto_review_exp_adj_amount]+[reviewer_fee_adj_amount]+[Reviewer_Exp_Adj_Amount]+[Auto_Review_Exp_Appeal_Amount]+ [Auto_Review_Fee_Appeal_Amount] +
    [Reviewer_Exp_Appeal_Amount] + [Reviewer_Fee_Appeal_Amount] +
    [Vendor_Exp_Appeal_Amount] + [Vendor_Fee_Appeal_Amount])) as NetAdjustmentAmount
,-sum([auto_review_fee_adj_amount]+[auto_review_exp_adj_amount]+[reviewer_fee_adj_amount]+[Reviewer_Exp_Adj_Amount]) as GrossAdjustmentAmount
,sum([Gross_Fee_Amount]+[Gross_Exp_Amount]+[Vendor_Fee_Adj_Amount]+[Vendor_Exp_Adj_Amount]) as FeesPlusExpenses

FROM V_summary_invoice_line_item as ili

INNER JOIN dim_work_area_bridge PAD ON ili.work_area_nk = PAD.work_area_child_source_id
INNER JOIN ( SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
	FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',-1,1) ) PAS ON (PAD.work_area_parent_source_id = PAS.RollupPracticeAreaId)

WHERE
	review_status IN (''' + @ReviewStatus + ''')     
	AND (invoice_date >= ''' + @pDateStart + ''' AND invoice_date<= ''' + @pDateEnd + ''') 

group by
	[RollupPracticeAreaName],
    currency_code

 HAVING
 sum([auto_review_fee_adj_amount]+[auto_review_exp_adj_amount]+[reviewer_fee_adj_amount]+[Reviewer_Exp_Adj_Amount])<> 0 OR
 sum(-([auto_review_fee_adj_amount]+[auto_review_exp_adj_amount]+[reviewer_fee_adj_amount]+[Reviewer_Exp_Adj_Amount]+[Auto_Review_Exp_Appeal_Amount]+ [Auto_Review_Fee_Appeal_Amount] +
    [Reviewer_Exp_Appeal_Amount] + [Reviewer_Fee_Appeal_Amount] +
    [Vendor_Exp_Appeal_Amount] + [Vendor_Fee_Appeal_Amount])) <>0 

order by NetAdjustmentAmount desc' 

Print @SQL 
EXEC(@SQL)



