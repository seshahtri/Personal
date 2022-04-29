DECLARE @pDateStart varchar (50);
DECLARE @pDateEnd varchar (50);
DECLARE @InvoiceStatus nvarchar (1000);
DECLARE @CurrencyCode varchar (50);
DECLARE @SQL VARCHAR(4000);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;

--SET @pDateStart='03/01/2021';
--SET @pDateEnd='02/28/2022';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';

SET @SQL=' 

exec as user = ''admin''
select b.RollupBusinessUnitName as [Business Unit Name], ed.currencycode,sum(f.amount) as ''Total_Spend'',
(sum(f.amount)/(overall.Overallspend))*100 as ''% Of Total Spend'',
sum(f.NetFeeAmount) as Fees,
sum(f.NetExpAmount) as Expenses

from v_invoicetimekeepersummary f
JOIN Exchangeratedim ed on ed.ExchangeRateDate = f.ExchangeRateDate
JOIN BusinessUnitAndAllDescendants bu on bu.ChildBusinessUnitId=f.BusinessUnitId
JOIN (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
--FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (-1, ''|'',16666,1)) b on bu.BusinessUnitId=b.RollupBusinessUnitId --replace 0 with 1 and apply BU filter
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (-1, ''|'',^ParamTwo^,1)) b on bu.BusinessUnitId=b.RollupBusinessUnitId 
JOIN PracticeAreaAndAllDescendants pa on pa.childpracticeareaid=f.practiceareaid
JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',-1,0)) p on pa.practiceareaid=p.rolluppracticeareaid
inner join (
select sum(f.amount) Overallspend from v_invoicetimekeepersummary f
JOIN BusinessUnitAndAllDescendants bu on bu.ChildBusinessUnitId=f.BusinessUnitId
JOIN (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
--FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (-1, ''|'',16666,1)) b on bu.BusinessUnitId=b.RollupBusinessUnitId --replace 0 with 1 and apply BU filter
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (-1, ''|'',^ParamTwo^,1)) b on bu.BusinessUnitId=b.RollupBusinessUnitId
JOIN PracticeAreaAndAllDescendants pa on pa.childpracticeareaid=f.practiceareaid
JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',-1,0)) p on pa.practiceareaid=p.rolluppracticeareaid
JOIN Exchangeratedim ed on ed.ExchangeRateDate = f.ExchangeRateDate
where ed.CurrencyCode = ''' + @CurrencyCode + ''' 
and
f.InvoiceStatus IN (''' + @InvoiceStatus + ''') 
and f.PaymentDate between ''' + @pDateStart + ''' and ''' + @pDateEnd + '''
--AND VendorID = 70237
AND VendorID = ^ParamOne^
)overall on 1=1

where ed.CurrencyCode = ''' + @CurrencyCode + ''' 
and
f.InvoiceStatus IN (''' + @InvoiceStatus + ''') 
and f.PaymentDate between ''' + @pDateStart + ''' and ''' + @pDateEnd + '''
--AND VendorID = 70237
AND VendorID = ^ParamOne^
group by b.RollupBusinessUnitName, ed.currencycode,overall.Overallspend
order by total_spend desc
'

Print @SQL
EXEC(@SQL)