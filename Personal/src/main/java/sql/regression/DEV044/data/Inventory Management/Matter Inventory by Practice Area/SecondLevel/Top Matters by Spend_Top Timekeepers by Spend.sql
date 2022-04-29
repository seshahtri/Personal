

DECLARE @pDateStart varchar (50);
DECLARE @pDateEnd varchar (50);
DECLARE @InvoiceStatus nvarchar (1000);
DECLARE @CurrencyCode varchar (50);
DECLARE @SQL VARCHAR(4000);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;

--SET @pDateStart='1/1/2017';
--SET @pDateEnd='12/31/2017';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';

SET @SQL='

EXEC AS USER =''admin''

	SELECT 
		TimekeeperName as ''Timekeeper Name'',
		VendorparentName as ''Vendor Name'',
		RoleName  as ''Role Name'',
		e.currencycode as ''Currency Code'',
		sum(GrossFeeAmountForRates*ISNull(e.ExchangeRate,1)) as ''Fee'',
		SUM(HoursForRates) AS ''Hours'',
		count(distinct matterid) as ''Matters'',
		sum(GrossFeeAmountForRates*ISNull(e.ExchangeRate,1))/sum(hoursforrates) as ''Fee Rate''
	FROM V_InvoiceTimekeeperSummary T
	inner join PracticeAreaAndAllDescendants p on t.PracticeAreaId=p.ChildPracticeAreaId
	inner join 
	          (
	          SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
	          --FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (32470, ''|'',-1,0)
			  FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (^ParamOne^, ''|'',-1,0)
	          ) pa on pa.rolluppracticeareaid=p.practiceareaid
	inner join ExchangeRateDim e on e.exchangeRateDate=t.exchangeRatedate
	where --matterid=5595523
	matterid=^ParamTwo^
	and 
	(T.InvoiceDate >= ''' + @pDateStart + ''' AND T.InvoiceDate<= ''' + @pDateEnd + ''')
	and T.InvoiceStatus IN (''' + @InvoiceStatus + ''')
	AND E.CurrencyCode = ''' + @CurrencyCode + '''
	and timekeeperROLEid <> -1
	AND HOURS > 0
	AND FeeRate >0
	and hoursforrates>=0.01
	Group by timekeeperroleid,TimekeeperName ,VendorparentName,RoleName,e.currencycode 
	order by fee desc'

Print @SQL
EXEC(@SQL)

