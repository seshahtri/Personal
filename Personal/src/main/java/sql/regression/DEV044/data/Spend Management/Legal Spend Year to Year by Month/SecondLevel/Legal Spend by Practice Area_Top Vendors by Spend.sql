--use DEV044_IOD_DataMart;

DECLARE @CurrencyCode  varchar (50);
DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @InvoiceStatus varchar (MAX);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @CurrencyCode= ^Currency^;
SET @InvoiceStatus= ^InvoiceStatus^;

--SET @CurrencyCode ='USD';
--SET @pDateStart='2017-01-01 00:00:00.00'; 
--SET @pDateEnd ='2017-12-31 23:59:59.99';
--SET @InvoiceStatus ='Paid'',''Processed';

SET @SQL = '

execute as user=''admin''

SELECT  
	
	MIN(ili.VendorName) as ''Vendor Name'',
	MIN(ex.CurrencyCode) as ''Currency Code'',
	SUM((ili.GrossFeeAmountForRates) * ISNULL(ex.ExchangeRate, 1)) as ''Spend'', 
	SUM(ili.HoursForRates) as ''Hours'' 
	FROM V_InvoiceTimekeeperSummary ili 
	join (SELECT RollupPracticeAreaId, RollupPracticeAreaName
	FROM [dbo].[fn_GetPracticeAreasWithChildrenWithRollupPracticeArea] (''-1'', ''|'',^ParamTwo^)) pa on pa.RollupPracticeAreaId=f.PracticeAreaId
	--FROM [dbo].[fn_GetPracticeAreasWithChildrenWithRollupPracticeArea] (''-1'', ''|'',32475)) pa on pa.RollupPracticeAreaId=ili.PracticeAreaId
	INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate
	
WHERE
	ili.InvoiceStatus IN ('''+@InvoiceStatus+''')
	AND ex.CurrencyCode = '''+@CurrencyCode+''' 
	AND (ili.InvoiceDate >= '''+@pDateStart+''' AND ili.InvoiceDate<= '''+@pDateEnd+''')
	
GROUP BY
	ili.VendorId,
	ili.VendorType
	
ORDER BY
	SUM((ili.GrossFeeAmountForRates) * ISNULL(ex.ExchangeRate, 1))  desc
'
	print(@SQL)
	EXEC(@SQL)
