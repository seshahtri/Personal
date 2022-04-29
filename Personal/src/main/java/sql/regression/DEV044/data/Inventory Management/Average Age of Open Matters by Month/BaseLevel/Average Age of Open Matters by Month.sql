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

SET @SQL = '

exec as user=''admin''
SELECT DATEPART(year,convert(DATE,T.TimePeriodLongFullName)) Year,DATENAME(month,convert(DATE,T.TimePeriodLongFullName)) Month,
ROUND(AVG(CAST(DATEDIFF(DAY,MatterOpenDate,CASE WHEN ISNULL(MATTERCLOSEDATE,convert(DATETIME,''9999-12-31'')) > TimePeriodEndDate THEN TimePeriodEndDate ELSE MatterCloseDate END)AS FLOAT) ),2)  [Average Age],
COUNT(CASE WHEN CAST(DATEDIFF(DAY,MatterOpenDate,CASE WHEN ISNULL(MATTERCLOSEDATE,convert(DATETIME,''9999-12-31'')) > TimePeriodEndDate THEN TimePeriodEndDate ELSE MatterCloseDate END)AS FLOAT)  <=30 THEN MatterId END) [# of Matters Less than 30 Days],
COUNT(CASE WHEN (CAST(DATEDIFF(DAY,MatterOpenDate,CASE WHEN ISNULL(MATTERCLOSEDATE,convert(DATETIME,''9999-12-31'')) > TimePeriodEndDate THEN TimePeriodEndDate ELSE MatterCloseDate END)AS FLOAT)  >=31) AND
(CAST(DATEDIFF(DAY,MatterOpenDate,CASE WHEN ISNULL(MATTERCLOSEDATE,convert(DATETIME,''9999-12-31'')) > TimePeriodEndDate THEN TimePeriodEndDate ELSE MatterCloseDate END)AS FLOAT)  <=90)
THEN MatterId END) [# of Matters Between 31 and 90 days],
COUNT(CASE WHEN (CAST(DATEDIFF(DAY,MatterOpenDate,CASE WHEN ISNULL(MATTERCLOSEDATE,convert(DATETIME,''9999-12-31'')) > TimePeriodEndDate THEN TimePeriodEndDate ELSE MatterCloseDate END)AS FLOAT)  >=91) AND
(CAST(DATEDIFF(DAY,MatterOpenDate,CASE WHEN ISNULL(MATTERCLOSEDATE,convert(DATETIME,''9999-12-31'')) > TimePeriodEndDate THEN TimePeriodEndDate ELSE MatterCloseDate END)AS FLOAT)  <=180)
THEN MatterId END) [# of Matters Between 91 and 180 days],
COUNT(CASE WHEN (CAST(DATEDIFF(DAY,MatterOpenDate,CASE WHEN ISNULL(MATTERCLOSEDATE,convert(DATETIME,''9999-12-31'')) > TimePeriodEndDate THEN TimePeriodEndDate ELSE MatterCloseDate END)AS FLOAT)  >=181) AND
(CAST(DATEDIFF(DAY,MatterOpenDate,CASE WHEN ISNULL(MATTERCLOSEDATE,convert(DATETIME,''9999-12-31'')) > TimePeriodEndDate THEN TimePeriodEndDate ELSE MatterCloseDate END)AS FLOAT)  <=360)
THEN MatterId END) [# of Matters Between 181 and 360 days],
COUNT(CASE WHEN CAST(DATEDIFF(DAY,MatterOpenDate,CASE WHEN ISNULL(MATTERCLOSEDATE,convert(DATETIME,''9999-12-31'')) > TimePeriodEndDate THEN TimePeriodEndDate ELSE MatterCloseDate END)AS FLOAT)  >360 THEN MatterId END) [# of Matters > 360 days]
FROM V_MatterSummary V
INNER JOIN BusinessUnitAndAllDescendants B on b.childbusinessunitid=v.BusinessUnitId
inner join 
(SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''-1'', ''|'',-1,0)) ba on ba.RollupBusinessUnitId=b.BusinessUnitId
INNER JOIN PracticeAreaAndAllDescendants P on P.ChildPracticeAreaId=V.PracticeAreaId
INNER JOIN 
(
SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',-1,1)) pa on pa.RollupPracticeAreaId=p.PracticeAreaId
INNER JOIN 
(SELECT [TimePeriodId],
       [TimePeriodName],
       [TimePeriodShortFullName],
       [TimePeriodLongFullName],
       [TimePeriodStartDate],
       [TimePeriodEndDate],
       [TimePeriodType]

FROM dbo.[fn_TimePeriodList](''Month'', '''+@pDateStart+''','''+@pDateEnd+''')) T on 1=1 -- Date Range
WHERE CASE WHEN MatterOpenDate<=TimePeriodEndDate AND (MatterCloseDate IS NULL OR MatterCloseDate>TimePeriodStartDate) THEN 1 ELSE 0 END =1
GROUP BY  DATEPART(year,convert(DATE,T.TimePeriodLongFullName)),DATENAME(month,convert(DATE,T.TimePeriodLongFullName)),DATEPART(month,convert(DATE,T.TimePeriodLongFullName))
order by DATEPART(year,convert(DATE,T.TimePeriodLongFullName)),DATEPART(month,convert(DATE,T.TimePeriodLongFullName))
'
print(@SQL)
exec(@SQL)