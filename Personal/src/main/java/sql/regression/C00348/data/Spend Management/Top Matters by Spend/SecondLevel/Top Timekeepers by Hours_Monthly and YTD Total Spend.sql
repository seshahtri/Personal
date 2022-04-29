--USE Q5_C00348_IOD_DataMart

--Monthly and YTD Total Spend    

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
--SET @CurrencyCode='USD';

SET @SQL='   
	SELECT   
		YEAR (ili.PaymentDate) as ''Year'',   
		DateName(month, DateAdd(month, MONTH(ili.PaymentDate), -1)) as ''Month'',   
		MIN(ex.CurrencyCode) as ''Currency Code'',   
		Amt.Spend,   
		Amt.Hours  as ''Hours'',   
		SUM (Amt.Spend) OVER (ORDER BY YEAR (ili.PaymentDate),
		MONTH(ili.PaymentDate)) AS ''YTD Spend'',   
		SUM (Amt.Hours) OVER (ORDER BY YEAR (ili.PaymentDate),MONTH(ili.PaymentDate)) AS ''YTD Hours''  
		--FROM V_InvoiceSummary ili  
		FROM V_InvoiceTimekeeperSummary ili   
		INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId   
		INNER JOIN (SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel    
					FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',-1,0)) pa 
					ON pad.PracticeAreaId = pa.RollupPracticeAreaId   
		INNER JOIN BusinessUnitAndAllDescendants bud ON ili.BusinessUnitId = bud.ChildBusinessUnitId   
		INNER JOIN (SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel    
					FROM fn_GetRollupBusinessUnitsWithSecurity (-1, ''|'',-1,0)) bu 
					ON bud.BusinessUnitId = bu.RollupBusinessUnitId   
		INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate   
		JOIN (SELECT YEAR (ili.PaymentDate) as ''Year'',     
			  MONTH(ili.PaymentDate) as ''Month'',     
			  SUM(ili.GrossFeeAmountForRates) * ISNULL(ExchangeRate, 1) as ''Spend'',     
		      SUM(ili.Hours) as ''Hours''    
		FROM V_InvoiceTimekeeperSummary ili     
		INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId     
		INNER JOIN (SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel 
					FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',-1,0)) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId     
		INNER JOIN BusinessUnitAndAllDescendants bud ON ili.BusinessUnitId = bud.ChildBusinessUnitId     
		INNER JOIN (SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel      
					FROM fn_GetRollupBusinessUnitsWithSecurity (-1, ''|'',-1,0)) bu 
					ON bud.BusinessUnitId = bu.RollupBusinessUnitId     
		INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate    
		WHERE ili.InvoiceStatus IN (''' + @InvoiceStatus + ''') 
		AND (ili.PaymentDate >= ''' + @pDateStart + ''' AND ili.PaymentDate<= ''' + @pDateEnd + ''')  
		AND ((ex.CurrencyCode = ''' + @CurrencyCode + ''') OR (ex.CurrencyId IS NULL)) 
		AND MatterId = ^ParamOne^     
		AND TimekeeperId = ^ParamTwo^  
		GROUP BY  YEAR (ili.PaymentDate), MONTH(ili.PaymentDate), exchangeRate) as Amt
		on Amt.Year=YEAR (ili.PaymentDate)  and Amt.Month=MONTH(ili.PaymentDate)  
		WHERE   ili.InvoiceStatus IN (''' + @InvoiceStatus + ''')  
		AND  (ili.PaymentDate >= ''' + @pDateStart + ''' AND ili.PaymentDate<= ''' + @pDateEnd + ''')
		AND ((ex.CurrencyCode = ''' + @CurrencyCode + ''') OR (ex.CurrencyId IS NULL))    
		AND MatterId = ^ParamOne^   
		AND TimekeeperId = ^ParamTwo^  
		GROUP BY YEAR (ili.PaymentDate), DateName(month, DateAdd(month, MONTH(ili.PaymentDate),-1)),   
		MONTH(ili.PaymentDate),   
		Amt.Spend,   
		Amt.Hours  
		ORDER BY YEAR (ili.PaymentDate), MONTH(ili.PaymentDate)'

Print @SQL
EXEC(@SQL)
