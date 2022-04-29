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
--SET @pDateStart='05/01/2021';
--SET @pDateEnd='04/30/2022';
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
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''-1'', ''|'',-1,0)
) [RollupBusinessUnitsWithSecurity] ON ([BusinessUnitAndAllDescendants].[BusinessUnitId] = [RollupBusinessUnitsWithSecurity].[RollupBusinessUnitId])
INNER JOIN [dbo].[PracticeAreaAndAllDescendants] [PracticeAreaAndAllDescendants] ON (md.[PracticeAreaId] = [PracticeAreaAndAllDescendants].[ChildPracticeAreaId])
INNER JOIN (
SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',-1,0)
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

--where md.MatterOwnerId = 1387774
where md.MatterOwnerId = ^ParamOne^

GROUP BY t.YearId,t.monthName3
--order by t.YearId asc, t.monthName3
order by t.YearId asc, case when t.monthName3 = ''January'' then 1
when t.monthName3 = ''February'' then 2
when t.monthName3 = ''March'' then 3
when t.monthName3 = ''April'' then 4
when t.monthName3 = ''May'' then 5
when t.monthName3 = ''June'' then 6
when t.monthName3 = ''July'' then 7
when t.monthName3 = ''August'' then 8
when t.monthName3 = ''September'' then 9
when t.monthName3 = ''October'' then 10
when t.monthName3 = ''November'' then 11
when t.monthName3 = ''December'' then 12
Else ''NUll'' END
'
print(@SQL)
exec(@SQL)