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

SELECT t.YearId as [Year],
t.MonthName3 AS [Month],
COUNT((CASE WHEN ((md.MatterOpenDate <= t.MonthEndDateTime)
AND (md.MatterOpenDate >= t.MonthStartDateTime))
THEN (md.[MatterId])
ELSE CAST(NULL AS BIGINT) END)) AS [New Matter],--New Matter

COUNT((CASE WHEN ((md.MatterCloseDate <= t.MonthEndDateTime)
AND (md.MatterCloseDate >= t.MonthStartDateTime))
THEN (md.MatterId)
ELSE CAST(NULL AS BIGINT) END)) AS [Closed Matter], -- Closed Matter

COUNT((CASE WHEN ((md.MatterOpenDate <= t.MonthEndDateTime) AND ((md.MatterCloseDate >= t.MonthEndDateTime) OR (md.MatterCloseDate IS NULL))) THEN (md.[MatterId])
ELSE CAST(NULL AS BIGINT) END)) AS [Active Matter] --Active Matter
FROM matterdim md
INNER JOIN [dbo].[BusinessUnitAndAllDescendants] [BusinessUnitAndAllDescendants] ON (md.[BusinessUnitId] = [BusinessUnitAndAllDescendants].[ChildBusinessUnitId])
INNER JOIN (
SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
--FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''16573'', ''|'',-1,1)
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (^ParamOne^, ''|'',-1,1)
) [RollupBusinessUnitsWithSecurity] ON ([BusinessUnitAndAllDescendants].[BusinessUnitId] = [RollupBusinessUnitsWithSecurity].[RollupBusinessUnitId])
INNER JOIN [dbo].[PracticeAreaAndAllDescendants] [PracticeAreaAndAllDescendants] ON (md.[PracticeAreaId] = [PracticeAreaAndAllDescendants].[ChildPracticeAreaId])
INNER JOIN (
SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
--FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',42406,1)
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',^ParamTwo^,1)
) [RollupPracticeAreasWithSecurity] ON ([PracticeAreaAndAllDescendants].[PracticeAreaId] = [RollupPracticeAreasWithSecurity].[RollupPracticeAreaId])

CROSS JOIN (
SELECT DISTINCT YearId,
month(MonthEndDateTime) monthID,
MonthName3,
MonthStartDateTime,
MonthEndDateTime
FROM DateDim
WHERE DayEndTime >= '''+@pDateStart+''' -- Month Start Date
AND DayEndTime < '''+@pDateEnd+''' -- Month End Date
) t
GROUP BY t.YearId,t.monthName3
order by t.YearId asc, t.monthName3
'
print(@SQL)
exec(@SQL)