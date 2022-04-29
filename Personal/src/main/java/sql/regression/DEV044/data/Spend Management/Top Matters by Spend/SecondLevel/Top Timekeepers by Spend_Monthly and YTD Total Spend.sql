--USE Q5_C00348_IOD_DataMart

--Monthly and YTD Total Spend    

EXECUTE AS USER='admin'    

DECLARE @pDateStart varchar (50);
DECLARE @pDateEnd varchar (50);
DECLARE @InvoiceStatus nvarchar (1000);
DECLARE @CurrencyCode varchar (50);
DECLARE @SQL VARCHAR(4000);

--SET @pDateStart= ^StartDate^;
--SET @pDateEnd= ^EndDate^;
--SET @InvoiceStatus= ^InvoiceStatus^;
--SET @CurrencyCode= ^Currency^;

SET @pDateStart='1/1/2017';
SET @pDateEnd='12/31/2017';
SET @InvoiceStatus = 'Paid'',''Processed';
SET @CurrencyCode='USD';

SET @SQL='   
	SELECT   
	YEAR (ili.InvoiceDate) as ''Year'',   
	DateName(month, DateAdd(month, MONTH(ili.InvoiceDate), -1)) as ''Month'',   
	MIN(ex.CurrencyCode) as ''Currency Code'',   
	Amt.Spend,   
	Amt.Hours  as ''Hours'',   
	SUM (Amt.Spend) OVER (ORDER BY YEAR (ili.InvoiceDate),MONTH(ili.InvoiceDate)) AS ''YTD Spend'',   
	SUM (Amt.Hours) OVER (ORDER BY YEAR (ili.InvoiceDate),MONTH(ili.InvoiceDate)) AS ''YTD Hours''  
	--FROM V_InvoiceSummary ili  
	FROM V_InvoiceTimekeeperSummary ili   
	INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId   
	INNER JOIN (SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel    
				FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',-1,0)) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId   
	INNER JOIN BusinessUnitAndAllDescendants bud ON ili.BusinessUnitId = bud.ChildBusinessUnitId   
	INNER JOIN (SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel    
				FROM fn_GetRollupBusinessUnitsWithSecurity (-1, ''|'',-1,0)) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId   
	INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate   
	JOIN (SELECT YEAR(ili.InvoiceDate) as ''Year'',     
		  MONTH(ili.InvoiceDate) as ''Month'',     
		  SUM(ili.GrossFeeAmountForRates) * ISNULL(ExchangeRate, 1) as ''Spend'',     
		  SUM(ili.Hours) as ''Hours''    
		  FROM V_InvoiceTimekeeperSummary ili     
		  INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId     
		  INNER JOIN (SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel      
					  FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',-1,0)) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId     
	      INNER JOIN BusinessUnitAndAllDescendants bud ON ili.BusinessUnitId = bud.ChildBusinessUnitId     
	      INNER JOIN (SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath,RollupBusinessUnitLevel      
				      FROM fn_GetRollupBusinessUnitsWithSecurity (-1, ''|'',-1,0)) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId     
	      INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate    
	      WHERE ili.InvoiceStatus IN (''' + @InvoiceStatus + ''')    
	      AND (ili.InvoiceDate >= ''' + @pDateStart + ''' AND ili.InvoiceDate<= ''' + @pDateEnd + ''')   
	      AND ((ex.CurrencyCode = ''' + @CurrencyCode + ''') OR (ex.CurrencyId IS NULL))      
	      --AND ili.MatterId = ^ParamOne^  
		AND ili.MatterId = 3686999
		--AND ili.TimekeeperId = ^ParamTwo^ 
		AND ili.TimekeeperId = 911971   
	      GROUP BY YEAR(ili.InvoiceDate), MONTH(ili.InvoiceDate),exchangeRate) as Amt on Amt.Year=YEAR(ili.InvoiceDate)  and Amt.Month=MONTH(ili.InvoiceDate)  
	WHERE   ili.InvoiceStatus IN (''' + @InvoiceStatus + ''')     
	AND (ili.InvoiceDate >= ''' + @pDateStart + ''' AND ili.InvoiceDate<= ''' + @pDateEnd + ''')
	AND ((ex.CurrencyCode = ''' + @CurrencyCode + ''') OR (ex.CurrencyId IS NULL))   
	--AND ili.MatterId = ^ParamOne^  
	AND ili.MatterId = 3686999
	--AND ili.TimekeeperId = ^ParamTwo^ 
	AND ili.TimekeeperId = 911971  
	GROUP BY YEAR(ili.InvoiceDate), DateName(month, DateAdd(month, MONTH(ili.InvoiceDate), -1)), MONTH(ili.InvoiceDate), Amt.Spend, Amt.Hours 
	ORDER BY   YEAR(ili.InvoiceDate),   MONTH(ili.InvoiceDate)'

Print @SQL
EXEC(@SQL)