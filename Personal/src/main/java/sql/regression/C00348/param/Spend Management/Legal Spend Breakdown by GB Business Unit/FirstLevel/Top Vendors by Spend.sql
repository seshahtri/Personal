--USE Q5_C00348_IOD_DataMart

EXEC AS USER ='admin'

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
		Top 1
		ili.VendorId,
	    MIN(ili.VendorName) as ''Vendor Name'',
	    ili.VendorType as ''Vendor Type'',
	    ili.MetroAreaName as ''Metro Area Name'',
	    ili.City,
	    ili.StateProvCode,
	    MIN(ex.CurrencyCode) as ''Currency Code'',
	    SUM((ili.Amount) * ISNULL(ex.ExchangeRate, 1)) as ''Fees'', --use with tk details
	    SUM(ili.Units) as ''Hours'' --use with tk details
	FROM V_InvoiceSummary ili
	--FROM V_InvoiceTimekeeperSummary ili --use with tk details
	    INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId
	    INNER JOIN (
	        SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
	        FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',-1,0)
	                ) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
	    INNER JOIN BusinessUnitAndAllDescendants bud ON ili.BusinessUnitId = bud.ChildBusinessUnitId
	    INNER JOIN (
	        SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
	        FROM fn_GetRollupBusinessUnitsWithSecurity (-1, ''|'',^ParamOne^,0)
	                ) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
	    INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate  
	WHERE
	    ili.InvoiceStatus IN (''' + @InvoiceStatus + ''')
		AND ex.CurrencyCode = ''' + @CurrencyCode + ''' 
	    AND (ili.PaymentDate >= ''' + @pDateStart + ''' AND ili.PaymentDate<= ''' + @pDateEnd + ''')
	GROUP BY
	    ili.VendorId,
	    ili.VendorType,
	    ili.MetroAreaName,
	    ili.City,
	    ili.StateProvCode
	ORDER BY
	    SUM(ili.GrossFeeAmountForRates * ISNULL(ex.ExchangeRate, 1))  desc'

Print @SQL
EXEC(@SQL)