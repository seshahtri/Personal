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
exec as user=''admin''
SELECT RollupBusinessUnitsWithSecurity.RollupBusinessUnitName AS [Business Unit Name],
ExchangeRateDim.CurrencyCode AS CurrencyCode,
--RollupBusinessUnitsWithSecurity.RollupBusinessUnitId AS RollupBusinessUnitId,
SUM((ITS.GrossFeeAmountForRates * ISNULL(ExchangeRateDim.ExchangeRate, 1))) AS [Total Spend],
case when SUM((ITS.NetExpAmount * ISNULL(ExchangeRateDim.ExchangeRate, 1))) >0 then SUM((ITS.NetFeeAmountForRates * ISNULL(ExchangeRateDim.ExchangeRate, 1))) / SUM((ITS.GrossFeeAmountForRates * ISNULL(ExchangeRateDim.ExchangeRate, 1))) else 100 end as [% of Total Spend],
SUM((ITS.NetFeeAmountForRates * ISNULL(ExchangeRateDim.ExchangeRate, 1))) AS Fees,
SUM((ITS.NetExpAmount * ISNULL(ExchangeRateDim.ExchangeRate, 1))) AS Expenses
FROM dbo.V_InvoiceTimekeeperSummary ITS
INNER JOIN dbo.PracticeAreaAndAllDescendants PracticeAreaAndAllDescendants ON (ITS.PracticeAreaId = PracticeAreaAndAllDescendants.ChildPracticeAreaId)
INNER JOIN (
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM dbo.fn_GetRollupPracticeAreasWithSecurity2 (''-1'', ''|'',-1,0)
) RollupPracticeAreasWithSecurity ON (PracticeAreaAndAllDescendants.PracticeAreaId = RollupPracticeAreasWithSecurity.RollupPracticeAreaId)
INNER JOIN dbo.BusinessUnitAndAllDescendants BusinessUnitAndAllDescendants ON (ITS.BusinessUnitId = BusinessUnitAndAllDescendants.ChildBusinessUnitId)
INNER JOIN (
SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM dbo.fn_GetRollupBusinessUnitsWithSecurity (''-1'', ''|'',-1,1)
) RollupBusinessUnitsWithSecurity ON (BusinessUnitAndAllDescendants.BusinessUnitId = RollupBusinessUnitsWithSecurity.RollupBusinessUnitId)
INNER JOIN dbo.ExchangeRateDim ExchangeRateDim ON (ITS.ExchangeRateDate = ExchangeRateDim.ExchangeRateDate)
WHERE
ITS.InvoiceStatus in ('''+@InvoiceStatus+''')
--AND ITS.RoleId = 30647
--AND ITS.VendorId = 70237
AND ITS.RoleId = ^ParamOne^
AND ITS.VendorId = ^ParamTwo^
AND ITS.PaymentDate between '''+@pDateStart+''' and '''+@pDateEnd+'''
AND ExchangeRateDim.CurrencyCode = '''+@CurrencyCode+'''
--AND RollupBusinessUnitsWithSecurity.BUCheck = 1
--AND RollupPracticeAreasWithSecurity.PACheck = 1
GROUP BY RollupBusinessUnitsWithSecurity.RollupBusinessUnitName,
ExchangeRateDim.CurrencyCode,
RollupBusinessUnitsWithSecurity.RollupBusinessUnitId
'
print(@SQL);
exec(@SQL);