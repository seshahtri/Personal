--Drill through from Top Roles by Percent of Hours Billed --> Top Vendors by Spend-- 

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
EXEC AS user = ''admin''
select pa.RollupPracticeAreaName as [GB Client],
ed.CurrencyCode as [Currency Code], 
Sum(invs.GrossFeeAmountForRates*ed.ExchangeRate) as [Total Spend] 
from V_InvoiceTimekeeperSummary invs
join ExchangeRateDim ed on ed.ExchangeRateDate = invs.ExchangeRateDate
INNER JOIN BusinessUnitAndAllDescendants B on b.childbusinessunitid=invs.BusinessUnitId
inner join 
(SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''-1'', ''|'',-1,0)) ba on ba.RollupBusinessUnitId=b.BusinessUnitId
INNER JOIN PracticeAreaAndAllDescendants P on P.ChildPracticeAreaId=invs.PracticeAreaId
INNER JOIN 
(
SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',-1,1)) pa on pa.RollupPracticeAreaId=p.PracticeAreaId -- Pass the drilldown PracticeAreaid by replacing (''-1'', ''|'',42406,1)  for self drilldown 

WHERE invs.InvoiceStatus IN ('''+@InvoiceStatus+''')
AND invs.PaymentDate BETWEEN  '''+@pDateStart+''' AND '''+@pDateEnd+'''
AND ed.CurrencyCode = '''+@CurrencyCode+'''
--AND invs.RoleId = 30647 -- Pass the drilldown RoleId
--AND invs.VendorId = 70237 -- Pass the drilldown VendorID
AND invs.RoleId = ^ParamOne^
AND invs.VendorId = ^ParamTwo^
Group by	pa.RollupPracticeAreaName,ed.CurrencyCode
ORDER BY [Total Spend] desc
'
print(@SQL)
exec(@SQL);
