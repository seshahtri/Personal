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
--SET @pDateStart='04/1/2021';
--SET @pDateEnd='03/31/2022';
--SET @InvoiceStatus = 'Paid'',''Processed';

SET @SQL = '
exec as user = ''admin''

SELECT DATEPART(year,CAST(t.TimePeriodStartDate as DATE)) as [Year],
[TimePeriodName] AS [Month],
COUNT((CASE WHEN ((md.MatterOpenDate <= t.TimePeriodEndDate)
AND (md.MatterOpenDate >= t.TimePeriodStartDate))
THEN (md.[MatterId])
ELSE CAST(NULL AS BIGINT) END)) AS [New Matter],--New Matter

COUNT((CASE WHEN ((md.MatterCloseDate <= t.TimePeriodEndDate)
AND (md.MatterCloseDate >= t.TimePeriodStartDate))
THEN (md.MatterId)
ELSE CAST(NULL AS BIGINT) END)) AS [Closed Matter], -- Closed Matter

COUNT((CASE WHEN ((md.MatterOpenDate <= t.TimePeriodEndDate) AND ((md.MatterCloseDate >= t.TimePeriodEndDate) OR (md.MatterCloseDate IS NULL))) THEN (md.[MatterId])
ELSE CAST(NULL AS BIGINT) END)) AS [Active Matter] --Active Matter
FROM V_MatterSummary md
INNER JOIN [dbo].[BusinessUnitAndAllDescendants] [BusinessUnitAndAllDescendants] ON (md.[BusinessUnitId] = [BusinessUnitAndAllDescendants].[ChildBusinessUnitId])
INNER JOIN (
SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
--FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''-1'', ''|'',''16574'',0)
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (^ParamOne^, ''|'',^ParamTwo^,1)
) [RollupBusinessUnitsWithSecurity] ON ([BusinessUnitAndAllDescendants].[BusinessUnitId] = [RollupBusinessUnitsWithSecurity].[RollupBusinessUnitId])
INNER JOIN [dbo].[PracticeAreaAndAllDescendants] [PracticeAreaAndAllDescendants] ON (md.[PracticeAreaId] = [PracticeAreaAndAllDescendants].[ChildPracticeAreaId])
INNER JOIN (
SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',-1,1)
) [RollupPracticeAreasWithSecurity] ON ([PracticeAreaAndAllDescendants].[PracticeAreaId] = [RollupPracticeAreasWithSecurity].[RollupPracticeAreaId])

CROSS JOIN (
SELECT
TimePeriodId,
TimePeriodName,
TimePeriodShortFullName,
TimePeriodLongFullName,
TimePeriodStartDate,
TimePeriodEndDate
FROM dbo.fn_TimePeriodList(''Month'','''+ @pDateStart+''', '''+ @pDateEnd +''')
) t
GROUP BY DATEPART(year,CAST(t.TimePeriodStartDate as DATE)),
TimePeriodName
--order by t.YearId asc, t.monthName3
'
print(@SQL)
exec(@SQL)