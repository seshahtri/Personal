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
MIN(inv.VendorName) as ''Vendor Name'',
--ili.VendorType as ''Vendor Type'',
    --ili.MetroAreaName as ''Metro Area Name'',
    --ili.City,
    --ili.StateProvCode,
MIN(ex.CurrencyCode) as ''Currency Code'',
SUM((Inv.NetFeeAmount) * ISNULL(ex.ExchangeRate, 1)) as ''Spend'',
--SUM(ili.Units) as ''Units'',
SUM(inv.FeeUnits) as ''Hours''
FROM  V_InvoiceTimekeeperSummary Inv 
INNER JOIN PracticeAreaAndAllDescendants pad ON Inv.PracticeAreaId = pad.ChildPracticeAreaId
INNER JOIN (
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',-1,0)

) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
INNER JOIN BusinessUnitAndAllDescendants bud ON inv.BusinessUnitId = bud.ChildBusinessUnitId
INNER JOIN (
SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM fn_GetRollupBusinessUnitsWithSecurity (''-1'', ''|'',-1,0)
) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
INNER JOIN ExchangeRateDim ex ON inv.ExchangeRateDate = ex.ExchangeRateDate
WHERE 
inv.InvoiceStatus IN ('''+@InvoiceStatus+''')
AND ex.CurrencyCode = '''+@CurrencyCode+'''
AND (inv.InvoiceDate >= '''+@pDateStart+''' AND inv.InvoiceDate<= '''+@pDateEnd+''') and
--inv.TimekeeperId=912067 And inv.MatterId=1683928 
inv.TimekeeperId=^ParamOne^ And inv.MatterId=^ParamTwo^ 
GROUP BY
inv.VendorId,
    inv.VendorType,
    inv.MetroAreaName,
    inv.City,
    inv.StateProvCode
ORDER BY
SUM((inv.NetFeeAmount) * ISNULL(ex.ExchangeRate, 1)) desc
'
print(@SQL)
EXEC(@SQL)


