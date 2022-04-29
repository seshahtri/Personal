DECLARE @pDateStart varchar (50);
DECLARE @pDateEnd varchar (50);
DECLARE @InvoiceStatus nvarchar (100);
DECLARE @CurrencyCode varchar (50);
DECLARE @SQL VARCHAR(4000); 

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^; 

--SET @pDateStart='05/01/2021';
--SET @pDateEnd='04/30/2022';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';

SET @SQL='
EXECUTE AS USER=''admin'' 
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
            )pa on pa.rolluppracticeareaid=p.practiceareaid
inner join ExchangeRateDim e on e.exchangeRateDate=t.exchangeRatedate
where
     (PaymentDate >= ''' + @pDateStart + ''' AND PaymentDate<= ''' + @pDateEnd + ''')
     and InvoiceStatus IN (''' + @InvoiceStatus + ''')
     and E.CurrencyCode= ''' + @CurrencyCode + '''
     and timekeeperROLEid <> -1
     and Vendorid = ^ParamOne^
     --and Vendorid = 70237
	 --AND ROLEID = 30648
	 AND ROLEID = ^ParamTwo^
     and HOURS > 0
     and FeeRate >0
     and hoursforrates>=0.01
     Group by timekeeperroleid,TimekeeperName ,VendorparentName,RoleName,e.currencycode 
     order by fee desc' 

Print @SQL
EXEC(@SQL)