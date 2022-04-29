--use C00348_IOD_DataMart;

DECLARE @CurrencyCode  varchar (50);
DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @InvoiceStatus varchar (MAX);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;

--SET @pDateStart='03/1/2021';
--SET @pDateEnd='02/28/2022';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';

SET @SQL = '

exec as user = ''admin''


select 

RoleName as [Role Name],e.CurrencyCode as [Currency Code],datepart(year,PaymentDate) as [Year],
sum(GrossFeeAmountForRates*ISNull(e.ExchangeRate,1))/sum(hoursforrates) as [Fee Rate],
Count(Distinct (case when (GrossFeeAmountForRates*ISNull(e.ExchangeRate,1))>0 then TimekeeperId else null end)) as [Number of Timekeepers]


from V_InvoiceTimekeeperSummary  t
Inner join BusinessUnitAndAllDescendants b on t.BusinessUnitId=b.ChildBusinessUnitId
inner join 
(
SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''-1'', ''|'',-1,0)
)bu on bu.rollupbusinessunitId=b.businessunitId

inner join PracticeAreaAndAllDescendants p on t.PracticeAreaId=p.ChildPracticeAreaId
inner join 
(
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',-1,0)
) pa on pa.rolluppracticeareaid=p.practiceareaid
inner join ExchangeRateDim e on e.exchangeRateDate=t.exchangeRatedate
where 

PaymentDate>=dateadd(year,-2,'''+@pDateStart+''') and PaymentDate<=dateadd(SECOND,-1,dateadd(day,0,'''+@pDateEnd+'''))

and InvoiceStatus in ('''+@InvoiceStatus+''')
and E.currencycode='''+@CurrencyCode+'''


and timekeeperid is not null

and hours>=0.001
group by t.roleid,RoleName ,e.CurrencyCode,datepart(year,PaymentDate)
order by datepart(year,PaymentDate) desc
,roleid asc

'
print (@SQL)
EXEC(@SQL)

