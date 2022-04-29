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
EXEC AS USER=''admin''
SELECT
ili.VendorName as ''Vendor Name'',
ili.RoleName as ''Role Name'',
ex.CurrencyCode as ''Currency Code'',
SUM((ili.GrossFeeAmountForRates) * ISNULL(ex.ExchangeRate, 1))/(CASE WHEN vs.VendorSpend=0 THEN NULL ELSE vs.VendorSpend END) * 100 as ''% of Total Fees'',
SUM((ili.GrossFeeAmountForRates) * ISNULL(ex.ExchangeRate, 1)) as ''Fees'',
SUM(ili.HoursForRates) as ''Hours'',
SUM((ili.GrossFeeAmountForRates) * ISNULL(ex.ExchangeRate, 1))/SUM(CASE WHEN ili.HoursForRates=0 THEN NULL ELSE ili.HoursForRates END) as ''Avg. Rate''
FROM V_InvoiceTimekeeperSummary ili
INNER JOIN [PracticeAreaAndAllDescendants] pa ON (ili.[PracticeAreaId] = pa.[ChildPracticeAreaId])
INNER JOIN (
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',-1,0)
) rpa ON (pa.[PracticeAreaId] = rpa.[RollupPracticeAreaId])
INNER JOIN [dbo].[BusinessUnitAndAllDescendants] ba ON (ili.[BusinessUnitId] = ba.[ChildBusinessUnitId])
INNER JOIN (
SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''-1'', ''|'',-1,0)
) rba ON (ba.[BusinessUnitId] = rba.[RollupBusinessUnitId]) INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate
JOIN (
SELECT ili.VendorId, SUM((ili.GrossFeeAmountForRates) * ISNULL(ex.ExchangeRate, 1)) VendorSpend
FROM V_InvoiceTimekeeperSummary ili
INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate
INNER JOIN [PracticeAreaAndAllDescendants] pa ON (ili.[PracticeAreaId] = pa.[ChildPracticeAreaId])
INNER JOIN (
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',-1,0)
) rpa ON (pa.[PracticeAreaId] = rpa.[RollupPracticeAreaId])
INNER JOIN [dbo].[BusinessUnitAndAllDescendants] ba ON (ili.[BusinessUnitId] = ba.[ChildBusinessUnitId])
INNER JOIN (
SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''-1'', ''|'',-1,0)
) rba ON (ba.[BusinessUnitId] = rba.[RollupBusinessUnitId]) WHERE ili.InvoiceStatus IN (''paid'',''processed'')
AND ex.CurrencyCode = '''+@CurrencyCode+'''
AND (ili.PaymentDate between '''+@pDateStart+''' AND '''+@pDateEnd+''')
AND ili.RoleName IS NOT NULL
--and ili.roleid = 30647
and ili.roleid = ^ParamOne^
GROUP BY ili.VendorId
Having (SUM((ili.GrossFeeAmountForRates * ISNULL(ex.ExchangeRate, 1))) >= 0.01)
) vs
on vs.VendorId=ili.VendorId
WHERE ili.InvoiceStatus IN ('''+@InvoiceStatus+''')
AND ex.CurrencyCode = '''+@CurrencyCode+'''
AND (ili.PaymentDate between '''+@pDateStart+''' AND '''+@pDateEnd+''')
AND ili.RoleName IS NOT NULL
--and ili.roleid = 30647
and ili.roleid = ^ParamOne^
--and ili.VendorName like ''%Clausen Miller P.C.---Chicago%''
GROUP BY ex.currencycode,ili.RoleName ,ili.VendorId, ili.VendorName ,vs.VendorSpend
Having (SUM((ili.GrossFeeAmountForRates * ISNULL(ex.ExchangeRate, 1))) >= 0.01)
ORDER BY vs.VendorSpend desc
'
print(@SQL);
exec(@SQL);

