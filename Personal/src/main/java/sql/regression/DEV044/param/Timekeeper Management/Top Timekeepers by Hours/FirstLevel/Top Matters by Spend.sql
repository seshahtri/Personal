DECLARE @pDateStart varchar (50);
DECLARE @pDateEnd varchar (50);
DECLARE @InvoiceStatus nvarchar (1000);
DECLARE @CurrencyCode varchar (50);
DECLARE @SQL VARCHAR(4000);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;

--SET @pDateStart='1/1/2017';
--SET @pDateEnd='12/31/2017';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';

SET @SQL=' 
EXECUTE AS USER=''admin''
	SELECT  top 1 
	ili.MatterId,
		MIN(ili.MatterName) as ''Matter Name'',  
		MIN(ili.PracticeAreaName) as ''Practice Area'',  
		MIN(ili.MatterStatus) as ''Matter Status'',   
		MIN(ex.CurrencyCode) as ''Currency Code'',   
		SUM(ili.GrossFeeAmountForRates * ISNULL(ex.ExchangeRate, 1)) as ''Spend''  
		
	FROM V_InvoiceTimekeeperSummary ili   
		INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId   
		INNER JOIN (SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel    
					FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',-1,0)) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId   
		INNER JOIN BusinessUnitAndAllDescendants bud ON ili.BusinessUnitId = bud.ChildBusinessUnitId   
		INNER JOIN (SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel    
					FROM fn_GetRollupBusinessUnitsWithSecurity (-1, ''|'',-1,0)) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId   
		INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate 
	WHERE  ili.InvoiceStatus IN (''' + @InvoiceStatus + ''') 
		AND ex.CurrencyCode = ''' + @CurrencyCode + '''  
		AND (ili.InvoiceDate >= ''' + @pDateStart + ''' AND ili.InvoiceDate<= ''' + @pDateEnd + ''')
		AND ili.TimekeeperId = ^ParamOne^ 
		--AND ili.TimekeeperId = 912067
	GROUP BY ili.MatterId  
	ORDER BY SUM(ili.Amount * ISNULL(ex.ExchangeRate, 1)) desc'

Print @SQL
EXEC(@SQL)