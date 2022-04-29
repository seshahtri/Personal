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
    [fee_exp_bill_code_description] as codeDescription
    ,currency_code
    ,sum(-([auto_review_fee_adj_amount]+[auto_review_exp_adj_amount]+[reviewer_fee_adj_amount]+[Reviewer_Exp_Adj_Amount]+[Auto_Review_Exp_Appeal_Amount]+ [Auto_Review_Fee_Appeal_Amount] +
    [Reviewer_Exp_Appeal_Amount] + [Reviewer_Fee_Appeal_Amount] +
    [Vendor_Exp_Appeal_Amount] + [Vendor_Fee_Appeal_Amount])) as netAdjustmentAmount
FROM [V_summary_invoice_line_item]
WHERE
	review_status IN (''' + @ReviewStatus + ''')     
	AND (invoice_date >= ''' + @pDateStart + ''' AND invoice_date<= ''' + @pDateEnd + ''') 

group by
    [fee_exp_bill_code_description]
    ,currency_code

 HAVING
 sum([auto_review_fee_adj_amount]+[auto_review_exp_adj_amount]+[reviewer_fee_adj_amount]+[Reviewer_Exp_Adj_Amount]) is not null 
order by netAdjustmentAmount desc' 

Print @SQL 
EXEC(@SQL)