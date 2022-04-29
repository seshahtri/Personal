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
execute as user = ''admin''

select PhaseCode as [Phase Code],
datepart(year, ifbc.InvoiceDate)  AS Year , 
datename(month, ifbc.InvoiceDate) AS Month,
ed.CurrencyCode as [Currency Code], 
Sum(ifbc.GrossFeeAmountForRates*ISNULL(ed.ExchangeRate,1)) as ''Fees''
from V_InvoiceFeeBillCodeSummary ifbc
join ExchangeRateDim ed on ed.ExchangeRateDate = ifbc.ExchangeRateDate
INNER JOIN BusinessUnitAndAllDescendants B on b.childbusinessunitid=ifbc.BusinessUnitId
inner join 
(SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''-1'', ''|'',-1,0)) ba on ba.RollupBusinessUnitId=b.BusinessUnitId
INNER JOIN PracticeAreaAndAllDescendants P on P.ChildPracticeAreaId=ifbc.PracticeAreaId
INNER JOIN 
(
SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',-1,1)) pa on pa.RollupPracticeAreaId=p.PracticeAreaId

WHERE ifbc.InvoiceStatus IN ('''+@InvoiceStatus+''')
AND ifbc.InvoiceDate BETWEEN  '''+@pDateStart+''' AND '''+@pDateEnd+'''
AND ed.CurrencyCode = '''+@CurrencyCode+'''
AND ifbc.Category =''Fee''
AND hours > 0.01
AND PhaseCode is NOT NULL
AND TimekeeperRoleId IS NOT NULL
and ifbc.VendorID = ^ParamOne^ 
--and ifbc.VendorID = 1047
and ifbc.matterid = ^ParamTwo^ 
--and ifbc.matterid = 5535880
Group by	PhaseCode,datepart(year, ifbc.InvoiceDate), datename(month, ifbc.InvoiceDate), ed.CurrencyCode
ORDER BY PhaseCode,Year, CASE  WHEN  datename(month, ifbc.InvoiceDate) = ''January'' THEN ''0''
							   WHEN  datename(month, ifbc.InvoiceDate) = ''February'' THEN ''1'' 
							   WHEN  datename(month, ifbc.InvoiceDate) = ''March'' THEN ''2''
							   WHEN  datename(month, ifbc.InvoiceDate) = ''April'' THEN ''3'' 
							   WHEN  datename(month, ifbc.InvoiceDate) = ''May'' THEN ''4''
							   WHEN  datename(month, ifbc.InvoiceDate) = ''June'' THEN ''5'' 
							   WHEN  datename(month, ifbc.InvoiceDate) = ''July'' THEN ''6''
							   WHEN  datename(month, ifbc.InvoiceDate) = ''August'' THEN ''7'' 
							   WHEN  datename(month, ifbc.InvoiceDate) = ''September'' THEN ''8''
							   WHEN  datename(month, ifbc.InvoiceDate) = ''October'' THEN ''9'' 
							   WHEN  datename(month, ifbc.InvoiceDate) = ''November'' THEN ''10''
							   WHEN  datename(month, ifbc.InvoiceDate) = ''December'' THEN ''11''  END
'
print(@SQL)
exec(@SQL)