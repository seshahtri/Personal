--use C00348_IOD_DataMart;

DECLARE @CurrencyCode varchar (50);
DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @InvoiceStatus varchar (MAX);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @CurrencyCode= ^Currency^;
SET @InvoiceStatus= ^InvoiceStatus^;

--SET @CurrencyCode ='USD';
--SET @pDateStart='3/1/2021';
--SET @pDateEnd='2/28/2022';
--SET @InvoiceStatus = 'Paid'',''Processed';


SET @SQL = '
exec as user = ''admin''
SELECT  
	MIN(ili.VendorName) as ''Vendor Name'',
	ili.VendorType as ''Vendor Type'',
	MIN(ili.MetroAreaName) as ''MetroAreaName'',
	MIN(ili.City) as ''City'',
	MIN(ili.StateProvCode) as ''State'',
	MIN(ex.CurrencyCode) as ''Currency Code'',
	--SUM(ili.Amount * ISNULL(ex.ExchangeRate, 1)) as ''Spend'',
	--SUM(ili.units) as ''Hours''
	SUM((ili.GrossFeeAmountForRates) * ISNULL(ex.ExchangeRate, 1)) as ''Spend'', --use with tk details
	SUM(ili.HoursForRates) as ''Hours'' --use with tk details
--FROM V_InvoiceSummary ili
FROM V_InvoiceTimekeeperSummary ili --use with tk details
	INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId
	INNER JOIN (
		SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
		FROM fn_GetRollupPracticeAreasWithSecurity2 (''-1'', ''|'',-1,0)
				) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
	INNER JOIN BusinessUnitAndAllDescendants bud ON ili.BusinessUnitId = bud.ChildBusinessUnitId
	INNER JOIN (
		SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
		FROM fn_GetRollupBusinessUnitsWithSecurity (''-1'', ''|'',-1,0)
				) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
	INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate
	
WHERE
	ili.InvoiceStatus IN ('''+@InvoiceStatus+''')
	AND ex.CurrencyCode = '''+@CurrencyCode+''' 
	--AND ili.matterdf01=''Corporate''
	--AND ili.MatterDF02=''Non-Litigation''
	--AND ili.VendorName=''AB Research Co.''
	--AND ili.VendorType=''Copy Service''
	--AND ili.practiceareaname=''Corporate trust services''
	--AND ili.businessunitname=''CSES''
	AND (ili.PaymentDate >= '''+@pDateStart+''' AND ili.PaymentDate<= '''+@pDateEnd+''')
	AND ili.RoleId = ^ParamOne^
	--AND ili.RoleId = 30647
	--AND InvoiceDate>=(select DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-11, 0) ) and InvoiceDate<= (SELECT CAST(eomonth(GETDATE()) AS datetime))
GROUP BY
	ili.VendorId,
	ili.VendorType
	
ORDER BY
	SUM(ili.Amount * ISNULL(ex.ExchangeRate, 1))  desc

'
print(@SQL);
exec(@SQL);