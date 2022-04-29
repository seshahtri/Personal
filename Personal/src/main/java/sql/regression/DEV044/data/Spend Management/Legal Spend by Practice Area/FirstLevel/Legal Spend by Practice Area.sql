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
exec as user=''admin''
select pa.RollupPracticeAreaName as [Practice Area ],ed.CurrencyCode as [Currency Code], Sum(invs.Amount*ISNULL(ed.ExchangeRate,1)) as [Total Spend]
from V_InvoiceSummary invs
join ExchangeRateDim ed on ed.ExchangeRateDate = invs.ExchangeRateDate
INNER JOIN BusinessUnitAndAllDescendants B on b.childbusinessunitid=invs.BusinessUnitId
inner join 
(SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''-1'', ''|'',-1,0)) ba on ba.RollupBusinessUnitId=b.BusinessUnitId
INNER JOIN PracticeAreaAndAllDescendants P on P.ChildPracticeAreaId=invs.PracticeAreaId
INNER JOIN 
(
SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',^ParamOne^,1)) pa on pa.RollupPracticeAreaId=p.PracticeAreaId
--FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',32475,1)) pa on pa.RollupPracticeAreaId=p.PracticeAreaId
WHERE invs.InvoiceStatus IN ('''+@InvoiceStatus+''')
AND invs.InvoiceDate BETWEEN  '''+@pDateStart+''' AND '''+@pDateEnd+'''
AND ed.CurrencyCode = '''+@CurrencyCode+'''
Group by	pa.RollupPracticeAreaName,ed.CurrencyCode
ORDER BY [Total Spend] desc
'
Print(@SQL)
EXEC(@SQL)