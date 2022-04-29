--use DEV044_IOD_DataMart;

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
--SET @pDateStart='1/1/2017';
--SET @pDateEnd='12/31/2017';
--SET @InvoiceStatus = 'Paid'',''Processed';

SET @SQL='

EXEC AS USER = ''admin''

IF OBJECT_ID(''tempdb..#MatterStatusHistory'') IS NOT NULL DROP TABLE #MatterStatusHistory

  SELECT MatterId, ''Open'' MatterHistoryStatus, MatterOpenDate StartDate, ''3000-01-01 00:00:00.000'' EndDate
   INTO #MatterStatusHistory
  from MatterDim M
  WHERE MatterStatus = ''Open''
  
  UNION ALL
  
  SELECT MatterId, ''Open'', MatterOpenDate StartDate, MatterCloseDate EndDate
  from MatterDim M
  WHERE MatterStatus = ''Closed''
  
  UNION ALL
  
  SELECT MatterId, ''Closed'', MatterCloseDate  StartDate, ''3000-01-01 00:00:00.000'' EndDate
  from MatterDim M
  WHERE MatterStatus = ''Closed''


IF OBJECT_ID(''tempdb..#MatterCounts'') IS NOT NULL DROP TABLE #MatterCounts
SELECT 
SUM(CAST((CASE WHEN (mh.MatterHistoryStatus = ''Open'') THEN 1 WHEN NOT (mh.MatterHistoryStatus = ''Open'') THEN 0 ELSE NULL END) as BIGINT)) - SUM(CAST((CASE WHEN (mh.MatterHistoryStatus = ''Closed'') THEN 1 WHEN NOT (mh.MatterHistoryStatus = ''Closed'') THEN 0 ELSE NULL END) as BIGINT)) AS Delta,
SUM(CAST((CASE WHEN ((mh.MatterHistoryStatus = ''Open'') AND (mh.StartDate >= '''+@pDateStart+''')) THEN 1 WHEN NOT ((mh.MatterHistoryStatus = ''Open'') AND (mh.StartDate >= '''+@pDateStart+''')) THEN 0 ELSE NULL END) as BIGINT)) AS OpenMatters,
SUM(CAST((CASE WHEN ((mh.MatterHistoryStatus = ''Closed'') AND (mh.StartDate >= '''+@pDateStart+''')) THEN 1 WHEN NOT ((mh.MatterHistoryStatus = ''Closed'') AND (mh.StartDate >= '''+@pDateStart+''')) THEN 0 ELSE NULL END) as BIGINT)) AS ClosedMatters,
DATEPART(year,(CASE WHEN (mh.StartDate >= '''+@pDateStart+''') THEN mh.StartDate WHEN NOT (mh.StartDate >= '''+@pDateStart+''') THEN '''+@pDateStart+''' ELSE NULL END)) AS MHYear,
DATEPART(Month,(CASE WHEN (mh.StartDate >= '''+@pDateStart+''') THEN mh.StartDate WHEN NOT (mh.StartDate >= '''+@pDateStart+''') THEN '''+@pDateStart+''' ELSE NULL END)) AS MHMonth
, ''Calculation'' running
INTO #MatterCounts
FROM #MatterStatusHistory mh
INNER JOIN V_MatterInfo MI on mh.MatterId = MI.matterid
INNER JOIN PracticeAreaAndAllDescendants pad ON MI.PracticeAreaId= pad.ChildPracticeAreaId
INNER JOIN (
SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity] (''-1'',''|'',-1,0)   --32470
) pa ON pad.PracticeAreaId =pa.RollupPracticeAreaId
Where MatterOwnerId = ^ParamOne^
--Where MatterOwnerId = 742378
GROUP BY 
DATEPART(year,(CASE WHEN (mh.StartDate >= '''+@pDateStart+''') THEN mh.StartDate WHEN NOT (mh.StartDate >= '''+@pDateStart+''') THEN '''+@pDateStart+''' ELSE NULL END)),
DATEPART(Month,(CASE WHEN (mh.StartDate >= '''+@pDateStart+''') THEN mh.StartDate WHEN NOT (mh.StartDate >= '''+@pDateStart+''') THEN '''+@pDateStart+''' ELSE NULL END))

ORDER BY  mhyear

--GO

SELECT 
--mc.MHYear,
--mc.MHMonth,
case 
when mc.MHMonth = 1 then ''January ''+ cast(mc.MHYear as varchar)
when mc.MHMonth = 2 then ''Febuary ''+ cast(mc.MHYear as varchar)
when mc.MHMonth = 3 then ''March ''+ cast(mc.MHYear as varchar)
when mc.MHMonth = 4 then ''April ''+ cast(mc.MHYear as varchar)
when mc.MHMonth = 5 then ''May ''+ cast(mc.MHYear as varchar)
when mc.MHMonth = 6 then ''June ''+ cast(mc.MHYear as varchar)
when mc.MHMonth = 7 then ''July ''+ cast(mc.MHYear as varchar)
when mc.MHMonth = 8 then ''August ''+ cast(mc.MHYear as varchar)
when mc.MHMonth = 9 then ''September ''+ cast(mc.MHYear as varchar)
when mc.MHMonth = 10 then ''October ''+ cast(mc.MHYear as varchar)
when mc.MHMonth = 11 then ''November ''+ cast(mc.MHYear as varchar)
when mc.MHMonth = 12 then ''December ''+ cast(mc.MHYear as varchar)
end as Month,
mc.ClosedMatters as [Closed Matters],
mc.OpenMatters as [Open Matters],

SUM(mc.ClosedMatters) OVER (PARTITION BY running ORDER BY MHYear,MHMonth RANGE UNBOUNDED PRECEDING) as [Running Sum of Closed Matters], 
SUM(mc.OpenMatters) OVER (PARTITION BY running ORDER BY MHYear,MHMonth RANGE UNBOUNDED PRECEDING) as [Running Sum of Open Matters]
FROM #MatterCounts mc


ORDER BY 
mc.MHYear, mc.MHMonth desc
'
print(@SQL)
exec(@SQL
)