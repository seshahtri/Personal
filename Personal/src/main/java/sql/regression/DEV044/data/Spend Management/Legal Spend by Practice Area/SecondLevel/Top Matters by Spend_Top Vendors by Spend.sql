--use DEV044_IOD_DataMart

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
--SET @pDateStart='2017-01-01'; 
--SET @pDateEnd ='2017-12-31';
--SET @InvoiceStatus ='Paid'',''Processed';

SET @SQL = '
execute as user=''admin''
SELECT  

	MIN(ili.VendorName) as ''Vendor Name'',
	MIN(ex.CurrencyCode) as ''Currency Code'',
	SUM(ili.Amount * ISNULL(ex.ExchangeRate, 1)) as ''Spend'',
	SUM(ili.Units) as ''Units'',
	SUM(ili.Units) as ''Hours''
	--SUM((ili.GrossFeeAmountForRates) * ISNULL(ex.ExchangeRate, 1)) as ''Fees'', --use with tk details
	--SUM(ili.HoursForRates) as ''Hours'' --use with tk details
FROM V_InvoiceSummary ili
--FROM V_InvoiceTimekeeperSummary ili --use with tk details
	INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId
	INNER JOIN (
		SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
		FROM fn_GetRollupPracticeAreasWithSecurity2 (''-1'', ''|'',^ParamOne^,0)
		--FROM fn_GetRollupPracticeAreasWithSecurity2 (''-1'', ''|'',32475,0)
				) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
	INNER JOIN BusinessUnitAndAllDescendants bud ON ili.BusinessUnitId = bud.ChildBusinessUnitId
	INNER JOIN (
		SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
		FROM fn_GetRollupBusinessUnitsWithSecurity (''-1'', ''|'',-1,0)
				) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
	INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate
	
WHERE 
 ili.MatterID = ^ParamTwo^
--ili.MatterID = ''3686999''
	and ili.InvoiceStatus IN ('''+@InvoiceStatus+''')
	AND ex.CurrencyCode = '''+@CurrencyCode+''' 
	AND (ili.InvoiceDate >= '''+@pDateStart+''' AND ili.InvoiceDate<= '''+@pDateEnd+''')
	
GROUP BY
	ili.VendorId,
	ili.VendorType
	
ORDER BY
	SUM(ili.Amount * ISNULL(ex.ExchangeRate, 1))  desc

	'
	print(@SQL)
	EXEC(@SQL)
