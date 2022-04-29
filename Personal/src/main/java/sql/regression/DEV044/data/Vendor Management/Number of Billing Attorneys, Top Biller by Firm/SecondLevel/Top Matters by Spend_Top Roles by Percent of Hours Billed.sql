

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
        --its.roleid,
        RoleName as ''Role'',
        currencycode as ''Currency Code'',
        sum(grossfeeamountforrates*isnull(exchangerate,1))  as ''Net Fee Amount'',
        (a.Units / SUM(a.units)  OVER (PARTITION BY 1))*100 as ''% of Total Hours''
        ,SUM(hoursforrates) as ''Hours''
  FROM
    v_invoicetimekeepersummary its
    JOIN Exchangeratedim ed on ed.ExchangeRateDate = its.ExchangeRateDate
    JOIN BusinessUnitAndAllDescendants bu on bu.ChildBusinessUnitId=its.BusinessUnitId
    JOIN (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
            FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (-1, ''|'',-1,0)) b
			--FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (^ParamOne^, ''|'',-1,0)) b
			on bu.BusinessUnitId=b.RollupBusinessUnitId --replace 0 with 1 and apply BU filter
    JOIN PracticeAreaAndAllDescendants pa on pa.childpracticeareaid=its.practiceareaid
    JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
            FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',-1,1)) p
			on pa.practiceareaid=p.rolluppracticeareaid
    JOIN
            (Select
                  RoleId as ''RoleId'',
                  SUM(FeeUnits) AS Units
            FROM
            v_invoicetimekeepersummary its
            JOIN Exchangeratedim ed on ed.ExchangeRateDate = its.ExchangeRateDate
            JOIN BusinessUnitAndAllDescendants bu on bu.ChildBusinessUnitId=its.BusinessUnitId
            JOIN (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
                    FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (-1, ''|'',-1,0)) b
				   --FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (^ParamOne^, ''|'',-1,0)) b
					on bu.BusinessUnitId=b.RollupBusinessUnitId --replace 0 with 1 and apply BU filter
            JOIN PracticeAreaAndAllDescendants pa on pa.childpracticeareaid=its.practiceareaid
            JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
                    FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',-1,1)) p 
					on pa.practiceareaid=p.rolluppracticeareaid
            WHERE 
                its.InvoiceStatus IN (''' + @InvoiceStatus + ''')
                AND ed.Currencycode = ''' + @CurrencyCode + '''
                AND (its.InvoiceDate between ''' + @pDateStart + ''' and ''' + @pDateEnd + ''')
                AND its.TimekeeperRoleId is NOT NULL
                AND its.HOURS > 0.01
                AND its.RoleName is NOT NULL
                and grossfeeamountforrates>0
				--and matterid=3686999
		--and vendorid=1044
		and vendorid=^ParamOne^
		and matterid=^ParamTwo^
            Group by RoleId) a on a.roleid=its.roleid
          
    WHERE 
        its.InvoiceStatus IN (''' + @InvoiceStatus + ''')
        AND ed.Currencycode = ''' + @CurrencyCode + '''
        AND (its.InvoiceDate between ''' + @pDateStart + ''' and ''' + @pDateEnd + ''')
        AND its.TimekeeperRoleId is NOT NULL
        AND its.HOURS > 0.01
        AND its.RoleName is NOT NULL
        and grossfeeamountforrates>0
	    --and matterid=3686999
		--and vendorid=1044
		and vendorid=^ParamOne^
		and matterid=^ParamTwo^
    Group by its.RoleId, RoleName, currencycode, a.Units
    order by
      Hours desc'

Print @SQL
EXEC(@SQL)