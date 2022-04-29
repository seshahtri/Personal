--use DEV044_IOD_DataMart;

DECLARE @CurrencyCode varchar (50);
DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @InvoiceStatus varchar (MAX);

--SET @pDateStart= ^StartDate^;
--SET @pDateEnd= ^EndDate^;
--SET @CurrencyCode= ^Currency^;
--SET @InvoiceStatus= ^InvoiceStatus^;

SET @CurrencyCode ='USD';
SET @pDateStart='1/1/2017';
SET @pDateEnd='12/31/2017';
SET @InvoiceStatus = 'Paid'',''Processed';

SET @SQL = '
SELECT 
  A.Year, 
  DateName(month,DateAdd(month, A.Month, 0) -1) Month, 
  isnull(NewMatters, 0) as [New Matters], 
  isnull(ClosedMatters, 0) as [Closed Matters], 
  ActiveMatters as [Active Matters] 
FROM 
  (
   SELECT 
      YEAR(MatterCloseDate) [Year], 
      MONTH(MatterCloseDate) AS [Month], 
      COUNT(DISTINCT matterID) ClosedMatters 
    FROM 
      MatterDIM 
    WHERE 
      MatterCloseDate > = '''+@pDateStart+''' -- Month Start Date
    GROUP BY 
      YEAR(MatterCloseDate), 
      MONTH(MatterCloseDate)

  ) AS O  
  left JOIN (
           SELECT 
      YEAR(MatterOpenDate) [Year], 
      MONTH(MatterOpenDate) AS [Month], 
      COUNT(DISTINCT matterID) NewMatters 
    FROM 
      MatterDIM M 
    WHERE 
      MatterOpenDate > = '''+@pDateStart+''' -- Month Start Date
    GROUP BY 
      YEAR(MatterOpenDate), 
      MONTH(MatterOpenDate)
  ) AS C ON  O.Month = C.Month 
  AND O.Year = C.Year 

  right JOIN (
    SELECT 
      count(distinct matterid) ActiveMatters, 
      t.YearId as Year, 
      t.monthID as Month 
    FROM 
      MatterDIM cross 
      join (
        SELECT 
          DISTINCT YearId, 
          month(MonthEndDateTime) monthID, 
          MonthEndDateTime 
        FROM 
          DateDim 
        WHERE 
          DayEndTime > = '''+@pDateStart+''' -- Month Start Date
          AND DayEndTime < '''+@pDateEnd+''' -- Month End Date
          ) t 
    WHERE 
      CAST (MatterOpenDate AS DATE) < = t.MonthEndDateTime  
      AND (
        CAST (MatterCloseDate AS DATE) >  t.MonthEndDateTime  OR MatterCloseDate IS NULL
      ) 
    group by 
      t.YearId, 
      t.monthID
  ) AS A ON O.Month = A.month 
  AND O.Year = A.Year 
ORDER BY 
  A.Year, Month desc
  '
  print(@SQL)
  exec(@SQL)
