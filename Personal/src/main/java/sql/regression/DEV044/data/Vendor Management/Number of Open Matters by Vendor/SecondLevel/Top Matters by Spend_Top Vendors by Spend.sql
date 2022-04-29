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
 --SET @pDateStart='01/01/2017';
 --SET @pDateEnd ='12/31/2017';
 --SET @InvoiceStatus ='Paid'',''Processed';

SET @SQL = '
execute as user=''admin''
SELECT
MIN(ili.VendorName) as ''Vendor Name'',
MIN(ex.CurrencyCode) as ''Currency Code'',
SUM((ili.Amount) * ISNULL(ex.ExchangeRate, 1)) as ''Spend'',
SUM(ili.Units) as ''Units'',
SUM(ili.Units) as ''Hours''
FROM V_InvoiceSummary ili
INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId
INNER JOIN (
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',-1,0)

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
AND (ili.InvoiceDate >= '''+@pDateStart+''' AND ili.InvoiceDate<= '''+@pDateEnd+''')
--and ili.vendorid=53616
and ili.vendorid=^ParamOne^
--and ili.matterid = 3686999
and ili.matterid = ^ParamTwo^
GROUP BY
ili.VendorId,
    ili.VendorType,
    ili.MetroAreaName,
    ili.City,
    ili.StateProvCode
ORDER BY
SUM((ili.Amount) * ISNULL(ex.ExchangeRate, 1)) desc
'
print(@SQL)
EXEC(@SQL)


