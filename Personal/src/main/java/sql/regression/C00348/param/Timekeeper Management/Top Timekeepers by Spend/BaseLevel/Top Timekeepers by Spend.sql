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
--SET @pDateStart='5/1/2021';
--SET @pDateEnd='4/30/2022';
--SET @InvoiceStatus = 'Paid'',''Processed';


SET @SQL = '
exec as user=''admin''
SELECT 
TOP 1
TimekeeperId as ''Timekeeperid'',
TimekeeperName as ''Timekeeper Name'',
VendorparentName as ''Vendor Name'',
RoleName  as ''Role Name'',
e.currencycode as ''Currency Code'',
sum(GrossFeeAmountForRates*ISNull(e.ExchangeRate,1)) as ''Fee'',
SUM(HoursForRates) AS ''Hours'',
count(distinct matterid) as ''Matters'',
sum(GrossFeeAmountForRates*ISNull(e.ExchangeRate,1))/sum(hoursforrates) as ''Fee Rate''
FROM V_InvoiceTimekeeperSummary T
Inner join BusinessUnitAndAllDescendants b on t.BusinessUnitId=b.ChildBusinessUnitId
inner join 
(
SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (-1, ''|'',-1,0)
)bu on bu.rollupbusinessunitId=b.businessunitId
inner join PracticeAreaAndAllDescendants p on t.PracticeAreaId=p.ChildPracticeAreaId
inner join 
(
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',-1,0)
) pa on pa.rolluppracticeareaid=p.practiceareaid
inner join ExchangeRateDim e on e.exchangeRateDate=t.exchangeRatedate
where
PaymentDate >= '''+@pDateStart+''' AND PaymentDate<= '''+@pDateEnd+'''
and InvoiceStatus in ('''+@InvoiceStatus+''')
and E.CurrencyCode='''+@CurrencyCode+'''
and timekeeperROLEid <> -1

AND HOURS > 0
AND FeeRate >0
and hoursforrates>=0.01
Group by Timekeeperid, TimekeeperName, VendorparentName, RoleName, e.currencycode 
order by fee desc
'
print(@SQL);
exec(@SQL);