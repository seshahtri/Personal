--USE LA_DATAMART
--GO 

Exec as user='admin'

DECLARE @pDateStart varchar (50); 
DECLARE @pDateEnd varchar (50); 
DECLARE @ReviewStatus varchar (1000); 
DECLARE @CurrencyCode varchar (50); 
DECLARE @SQL VARCHAR(4000);  

--SET @pDateStart= ^StartDate^; 
--SET @pDateEnd= ^EndDate^; 
--SET @ReviewStatus= ^ReviewStatus^; 
--SET @CurrencyCode= ^Currency^;  

SET @pDateStart='01/01/2020'; 
SET @pDateEnd='05/31/2021'; 
SET @ReviewStatus = 'Complete'',''In LBA Review'; 
SET @CurrencyCode='-1'; 

SET @SQL=' 
Select 
	Role_name ,
	currency_code,
	-sum(([auto_review_fee_adj_amount]+[auto_review_exp_adj_amount]+[reviewer_fee_adj_amount]+[reviewer_exp_adj_amount])+
	([auto_review_exp_appeal_amount]+ [auto_review_fee_appeal_amount] +[reviewer_exp_appeal_amount] + [reviewer_fee_appeal_amount] +[vendor_exp_appeal_amount] + [vendor_fee_appeal_amount]))
	as ''Net Adjustment Amount'' ,

	-sum([auto_review_fee_adj_amount]+[auto_review_exp_adj_amount]+[reviewer_fee_adj_amount]+[reviewer_exp_adj_amount]) as ''Gross Adjustment Amount'' ,
	sum(gross_fee_amount+ gross_exp_amount+vendor_fee_adj_amount+vendor_exp_adj_amount ) AS ''FeesPlusExpense''

	from v_summary_invoice_line_item

	where 
		invoice_date BETWEEN ''' + @pDateStart + ''' AND ''' + @pDateEnd + '''
		and review_status IN (''' + @ReviewStatus + ''')
		and work_area_nk=^ParamOne^
		--and work_area_nk=''4''

	group by role_nk,role_name,currency_code

	having

	sum([auto_review_fee_adj_amount]+[auto_review_exp_adj_amount]+[reviewer_fee_adj_amount]+[reviewer_exp_adj_amount]) <>0 or 
	sum(-(([auto_review_fee_adj_amount]+[auto_review_exp_adj_amount]+[reviewer_fee_adj_amount]+[reviewer_exp_adj_amount])+
	([auto_review_exp_appeal_amount]+ [auto_review_fee_appeal_amount] +[reviewer_exp_appeal_amount] + [reviewer_fee_appeal_amount] +[vendor_exp_appeal_amount] + [vendor_fee_appeal_amount]))) <> 0
	
	order by ''Net Adjustment Amount'' desc, role_name' 

Print @SQL 
EXEC(@SQL)
 