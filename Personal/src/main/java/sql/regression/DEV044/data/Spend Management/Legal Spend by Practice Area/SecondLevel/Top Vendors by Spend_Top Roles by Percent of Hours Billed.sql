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
IF OBJECT_ID(''tempdb..#KpiDataTest'') IS NOT NULL DROP TABLE #KpiDataTest
	exec as user = ''admin''
	SELECT
	  RoleName as ''Role'',
	  currencycode as ''Currency Code'',
	  Fees as ''Net Fee Amount'',
	  (Units / SUM(Units) OVER (PARTITION BY 1)) * 100 [ % of Total Hours]
	  ,Hours
	  INTO #KpiDataTest
	  from
	(select
		  RoleId as ''RoleId'',
		  roleName as ''RoleName'',
		  sum(grossfeeamountforrates*isnull(exchangerate,1)) as ''Fees'',
		  SUM(FeeUnits) AS Units,
		  ed.CurrencyCode,
		  SUM(hoursforrates) as Hours from
	v_invoicetimekeepersummary its
	JOIN Exchangeratedim ed on ed.ExchangeRateDate = its.ExchangeRateDate
	 JOIN BusinessUnitAndAllDescendants bu on bu.ChildBusinessUnitId=its.BusinessUnitId
                    JOIN (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
                            FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''-1'', ''|'',-1,0)) b on bu.BusinessUnitId=b.RollupBusinessUnitId --replace 0 with 1 and apply BU filter
                    JOIN PracticeAreaAndAllDescendants pa on pa.childpracticeareaid=its.practiceareaid
                    JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
                            FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',^ParamOne^,1)) p on pa.practiceareaid=p.rolluppracticeareaid
							--FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',32475,1)) p on pa.practiceareaid=p.rolluppracticeareaid
	 WHERE
							its.InvoiceStatus IN ('''+@InvoiceStatus+''')
							AND ed.Currencycode = '''+@CurrencyCode+'''
							AND its.InvoiceDate between '''+@pDateStart+''' and '''+@pDateEnd+'''
							AND its.TimekeeperRoleId is NOT NULL
							AND its.HOURS > 0.01
							AND its.RoleName is NOT NULL
							and grossfeeamountforrates>0
							and vendorid = ^ParamTwo^
							--and vendorid = 53626
							Group by RoleId, RoleName, currencycode
							) s
select * from #KpiDataTest
order by Hours desc
'
print(@SQL)
EXEC(@SQL)

 