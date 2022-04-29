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

--SET @pDateStart='03/1/2021';
--SET @pDateEnd='02/28/2022';
--SET @InvoiceStatus = 'Paid'',''Processed';  
--SET @CurrencyCode='USD';

SET @SQL='

	
SELECT      
	    
	    MIN(ili.VendorName) as ''Vendor Name'',     
	    ili.RoleName as ''Role Name'',      
	    MIN(ex.CurrencyCode) as ''Currency Code'',      
	    SUM((ili.GrossFeeAmountForRates) * ISNULL(ex.ExchangeRate, 1))/(CASE WHEN vs.VendorSpend=0 THEN NULL ELSE vs.VendorSpend END) * 100 as ''% of Total Fees'',      
	    SUM((ili.GrossFeeAmountForRates) * ISNULL(ex.ExchangeRate, 1)) as ''Fees'',      
	    SUM(ili.HoursForRates) as ''Hours'',      
	    SUM((ili.GrossFeeAmountForRates) * ISNULL(ex.ExchangeRate, 1))/SUM(CASE WHEN ili.HoursForRates=0 THEN NULL ELSE ili.HoursForRates END) as ''Avg. Rate''  
	FROM V_InvoiceTimekeeperSummary ili      
		INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate      
		JOIN (
			SELECT ili.VendorId, SUM((ili.GrossFeeAmountForRates) * ISNULL(ex.ExchangeRate, 1)) VendorSpend          
			FROM V_InvoiceTimekeeperSummary ili              
			INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate          
			WHERE  ili.InvoiceStatus IN ('''+@InvoiceStatus+''')    
			AND ex.CurrencyCode = '''+@CurrencyCode+'''                  
			AND (ili.PaymentDate between '''+@pDateStart+''' AND  '''+@pDateEnd+''')              
			AND ili.RoleName IS NOT NULL      
			And Hours>0
			GROUP BY ili.VendorId
			) vs 
		on vs.VendorId=ili.VendorId  

		WHERE ili.InvoiceStatus IN   ('''+@InvoiceStatus+''')   
		AND ex.CurrencyCode = '''+@CurrencyCode+''' 
		AND (ili.PaymentDate between '''+@pDateStart+''' AND  '''+@pDateEnd+''')        
		AND ili.RoleName IS NOT NULL   
		And Hours>0
		
	GROUP BY ili.VendorId, vs.VendorSpend, ili.RoleName  
	ORDER BY vs.VendorSpend desc,      
	CASE WHEN ili.RoleName=''Partner'' THEN 1          
	     WHEN ili.RoleName=''Associate'' THEN 2          
		 WHEN ili.RoleName=''Paralegal'' THEN 3          
		 ELSE 4      
	END
'
Print @sql
Exec(@sql)