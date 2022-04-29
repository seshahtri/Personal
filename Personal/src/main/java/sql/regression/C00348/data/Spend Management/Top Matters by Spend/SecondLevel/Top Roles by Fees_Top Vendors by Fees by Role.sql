--USE Q5_C00348_IOD_DataMart

EXECUTE AS USER='admin'  
   
DECLARE @pDateStart varchar (50);
DECLARE @pDateEnd varchar (50);
DECLARE @InvoiceStatus nvarchar (1000);
DECLARE @CurrencyCode varchar (50);
DECLARE @SQL VARCHAR(4000);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;

--SET @pDateStart='1/1/2018';
--SET @pDateEnd='12/31/2021';
--SET @InvoiceStatus = 'Paid'',''Processed';  

SET @SQL='
	SELECT      
	    --ili.VendorId,      
	    MIN(ili.VendorName) as ''Vendor Name'',     
	    ili.RoleName as ''Role Name'',      
	    MIN(ex.CurrencyCode) as ''Currency Code'',      
	    SUM((ili.GrossFeeAmountForRates) * ISNULL(ex.ExchangeRate, 1))/(CASE WHEN vs.VendorSpend=0 THEN NULL ELSE vs.VendorSpend END) * 100 as ''% of Total Fees'',      
	    SUM((ili.GrossFeeAmountForRates) * ISNULL(ex.ExchangeRate, 1)) as ''Fees'',      
	    SUM(ili.HoursForRates) as ''Hours'',      
	    SUM((ili.GrossFeeAmountForRates) * ISNULL(ex.ExchangeRate, 1))/SUM(CASE WHEN ili.HoursForRates=0 THEN NULL ELSE ili.HoursForRates END) as ''Avg. Rate''  
	FROM V_InvoiceTimekeeperSummary ili      
		INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate      
		JOIN (SELECT ili.VendorId, SUM((ili.GrossFeeAmountForRates) * ISNULL(ex.ExchangeRate, 1)) VendorSpend          
	FROM V_InvoiceTimekeeperSummary ili              
		INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate          
	WHERE  ili.InvoiceStatus IN (''' + @InvoiceStatus + ''')    
		AND ex.CurrencyCode = ''' + @CurrencyCode + '''        
		--AND ex.CurrencyId = 1               
		AND (ili.PaymentDate >= ''' + @pDateStart + ''' AND ili.PaymentDate<= ''' + @pDateEnd + ''')              
		AND ili.RoleName IS NOT NULL     
		and ili.MatterId = ^ParamOne^    
		And ili.RoleId = ^ParamTwo^        
	GROUP BY ili.VendorId) vs on vs.VendorId=ili.VendorId  
		WHERE ili.InvoiceStatus IN (''' + @InvoiceStatus + ''')      
		AND ex.CurrencyCode = ''' + @CurrencyCode + ''' 
		--AND ex.CurrencyId = 1       
		AND ((ili.PaymentDate >= ''' + @pDateStart + ''' AND ili.PaymentDate<= ''' + @pDateEnd + ''')        
		AND ili.RoleName IS NOT NULL   
		and ili.MatterId = ^ParamOne^ 
		And ili.RoleId = ^ParamTwo^)
	GROUP BY ili.VendorId, vs.VendorSpend, ili.RoleName  
	ORDER BY vs.VendorSpend desc,      
	CASE WHEN ili.RoleName=''Partner'' THEN 1          
	     WHEN ili.RoleName=''Associate'' THEN 2          
		 WHEN ili.RoleName=''Paralegal'' THEN 3          
		 ELSE 4      
	END'

Print @SQL
EXEC(@SQL)