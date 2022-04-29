--use Q5_C00348_IOD_DATAMART

DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @InvoiceStatus nvarchar (MAX);
DECLARE @CurrencyCode  varchar (50);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @CurrencyCode= ^Currency^;
--SET @InvoiceStatus= ^InvoiceStatus^;

--SET @pDateStart='1/1/2021'; 
--SET @pDateEnd='06/30/2021';
--SET @CurrencyCode ='USD';
SET @InvoiceStatus ='Paid'''',''''Processed';

Set @SQL='
execute as user=''admin''
SELECT  Top 1000 
  V_MatterBudgetDetails.MatterName AS [Matter Name],
  V_MatterBudgetDetails.MatterDF07 AS [Claim Number],
  V_MatterBudgetDetails.MatterOwnerName AS [Matter Owner Name],
  V_MatterBudgetDetails.MatterDF08 AS [GB Branch Name],
  V_MatterBudgetDetails.MatterDF09 AS  [GB Branch Number],
  ExchangeRateDim.CurrencyCode AS [Currency Code],
SUM((CASE WHEN (NOT (InvoiceStatus.Name IS NULL)) THEN (InvoiceSummary.Amount * ExchangeRateDim.ExchangeRate) ELSE CAST(NULL AS FLOAT) END)) AS Spend,
( MIN((V_MatterBudgetDetails.BudgetAmount * ExchangeRateDim1.ExchangeRate))) AS [Total Budget], 
isnull((( SUM((CASE WHEN (NOT (InvoiceStatus.Name IS NULL)) THEN (InvoiceSummary.Amount * ExchangeRateDim.ExchangeRate) ELSE CAST(NULL AS FLOAT) END)) )/   (MIN((V_MatterBudgetDetails.BudgetAmount * ExchangeRateDim1.ExchangeRate)))),0) * 100 as [Percent of Budget Consumed],
--CASE WHEN CAST(1-((SUM(amt.Amount)/SUM(vb.BudgetAmount)))  AS FLOAT) *100 >0 THEN CAST(1-((SUM(amt.Amount)/SUM(vb.BudgetAmount)))  AS FLOAT)* 100 ELSE 0  END as [Percent of Budget Remaining],
isnull( (1- ( SUM((CASE WHEN (NOT (InvoiceStatus.Name IS NULL))  THEN (InvoiceSummary.Amount * ExchangeRateDim.ExchangeRate) ELSE CAST(NULL AS FLOAT)  END)) )/   (MIN((V_MatterBudgetDetails.BudgetAmount * ExchangeRateDim1.ExchangeRate)))),1) * 100 as [Percent of Budget Remaining],
isnull((MIN((V_MatterBudgetDetails.BudgetAmount * ExchangeRateDim1.ExchangeRate)))-(  SUM((CASE WHEN (NOT (InvoiceStatus.Name IS NULL)) THEN (InvoiceSummary.Amount * ExchangeRateDim.ExchangeRate) ELSE CAST(NULL AS FLOAT) END))),
   MIN((V_MatterBudgetDetails.BudgetAmount * ExchangeRateDim1.ExchangeRate))) as [Budget Remaining]
FROM dbo.V_MatterBudgetDetails V_MatterBudgetDetails
  INNER JOIN (
    select  V_MatterBudgetAndSpend.matterid, sum(V_MatterBudgetAndSpend.budgetAmount) bAmount from dbo.MatterBudgetSummary V_MatterBudgetAndSpend
       where ((CASE WHEN (((V_MatterBudgetAndSpend.BudgetPeriodStartDate >= ''' + @pDateStart + ''') AND 
       (V_MatterBudgetAndSpend.BudgetPeriodEndDate <=  ''' + @pDateEnd + '''))) OR 
       ((V_MatterBudgetAndSpend.BudgetPeriodStartDate <= ''' + @pDateStart + ''') AND 
       (''' + @pDateEnd + ''' <= V_MatterBudgetAndSpend.BudgetPeriodEndDate)) OR 
       ((V_MatterBudgetAndSpend.BudgetPeriodStartDate <=  ''' + @pDateStart + ''') AND (V_MatterBudgetAndSpend.BudgetPeriodEndDate >=  ''' + @pDateStart + ''')) OR 
       ((V_MatterBudgetAndSpend.BudgetPeriodStartDate >= ''' + @pDateStart + ''') AND 
       (V_MatterBudgetAndSpend.BudgetPeriodStartDate <=  ''' + @pDateEnd + ''') AND 
       (V_MatterBudgetAndSpend.BudgetPeriodEndDate >= ''' + @pDateEnd + ''')) THEN 1 ELSE 0 END) = 1)       
       group by matterid
) MatterBudget ON (V_MatterBudgetDetails.MatterId = MatterBudget.matterid)
  LEFT JOIN dbo.InvoiceSummary InvoiceSummary ON ((V_MatterBudgetDetails.MatterId = InvoiceSummary.MatterId) AND (V_MatterBudgetDetails.BudgetPeriodId = InvoiceSummary.BudgetPeriodId))
  INNER JOIN dbo.BusinessUnitAndAllDescendants BusinessUnitAndAllDescendants ON (V_MatterBudgetDetails.BusinessUnitId = BusinessUnitAndAllDescendants.ChildBusinessUnitId)
  INNER JOIN (
  SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
  FROM dbo.fn_GetRollupBusinessUnitsWithSecurity (''-1'', ''|'',-1,0)
) RollupBusinessUnitsWithSecurity ON (BusinessUnitAndAllDescendants.BusinessUnitId = RollupBusinessUnitsWithSecurity.RollupBusinessUnitId)
  INNER JOIN dbo.PracticeAreaAndAllDescendants PracticeAreaAndAllDescendants ON (V_MatterBudgetDetails.PracticeAreaId = PracticeAreaAndAllDescendants.ChildPracticeAreaId)
  INNER JOIN (
  SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
  FROM dbo.fn_GetRollupPracticeAreasWithSecurity2 (''-1'', ''|'',^ParamOne^,0)
) RollupPracticeAreasWithSecurity ON (PracticeAreaAndAllDescendants.PracticeAreaId = RollupPracticeAreasWithSecurity.RollupPracticeAreaId)
  LEFT JOIN dbo.ExchangeRateDim ExchangeRateDim ON (InvoiceSummary.ExchangeRateDate = ExchangeRateDim.ExchangeRateDate)
  LEFT JOIN dbo.ExchangeRateDim ExchangeRateDim1 ON (V_MatterBudgetDetails.BudgetExchangeRateDate = ExchangeRateDim1.ExchangeRateDate)
  LEFT JOIN (
  SELECT Name FROM fn_SplitQuotedStrings(''''''' + @InvoiceStatus + ''''''')
) InvoiceStatus ON (InvoiceSummary.InvoiceStatus = InvoiceStatus.Name)

WHERE (((CASE WHEN (V_MatterBudgetDetails.IsLOM <> 0) THEN (CASE WHEN (((V_MatterBudgetDetails.MatterOpenDate <= ''' + @pDateEnd + ''') AND (ISNULL(V_MatterBudgetDetails.MatterCloseDate, (CASE
       WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
       ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)) > ''' + @pDateEnd + ''')) OR ((V_MatterBudgetDetails.MatterOpenDate <= ''' + @pDateEnd + ''') AND (DATEDIFF(month,ISNULL(V_MatterBudgetDetails.MatterCloseDate, (CASE
       WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
       ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)),''' + @pDateEnd + ''') <= 12))) THEN 1 WHEN NOT (((V_MatterBudgetDetails.MatterOpenDate <= ''' + @pDateEnd + ''') AND (ISNULL(V_MatterBudgetDetails.MatterCloseDate, (CASE
       WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
       ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)) > ''' + @pDateEnd + ''')) OR ((V_MatterBudgetDetails.MatterOpenDate <= ''' + @pDateEnd + ''') AND (DATEDIFF(month,ISNULL(V_MatterBudgetDetails.MatterCloseDate, (CASE
       WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
       ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)),''' + @pDateEnd + ''') <= 12))) THEN 0 ELSE NULL END) ELSE 1 END) <> 0) AND ((CASE WHEN (((V_MatterBudgetDetails.BudgetPeriodStartDate >= cast('''+@pDateStart+'''as date)) 
          AND (V_MatterBudgetDetails.BudgetPeriodEndDate <= DATEADD(second,-1,DATEADD(day,1,cast('''+@pDateEnd+'''as datetime))))) 
          OR ((V_MatterBudgetDetails.BudgetPeriodStartDate <= cast('''+@pDateStart+'''as date)) AND (DATEADD(second,-1,DATEADD(day,1,cast('''+@pDateEnd+'''as datetime))) <= V_MatterBudgetDetails.BudgetPeriodEndDate)) 
          OR ((V_MatterBudgetDetails.BudgetPeriodStartDate <= cast('''+@pDateStart+'''as date)) AND (V_MatterBudgetDetails.BudgetPeriodEndDate >= ''' + @pDateStart + ''')) OR ((V_MatterBudgetDetails.BudgetPeriodStartDate >= cast('''+@pDateStart+'''as date)) 
          AND (V_MatterBudgetDetails.BudgetPeriodStartDate <= DATEADD(second,-1,DATEADD(day,1,cast('''+@pDateEnd+'''as datetime)))) AND (V_MatterBudgetDetails.BudgetPeriodEndDate >= DATEADD(second,-1,DATEADD(day,1,cast('''+@pDateEnd+'''as datetime)))))) THEN 1 ELSE 0 END) = 1) 
         		 AND ((InvoiceSummary.MatterId IS NULL) OR (ExchangeRateDim.CurrencyCode = ''' + @CurrencyCode + ''')) AND ((ExchangeRateDim1.CurrencyCode IS NULL) OR (ExchangeRateDim1.CurrencyCode = ''' + @CurrencyCode + ''')))


GROUP BY V_MatterBudgetDetails.MatterDF07,
  V_MatterBudgetDetails.MatterDF08,
  V_MatterBudgetDetails.MatterDF09,
  ExchangeRateDim.CurrencyCode,
  V_MatterBudgetDetails.MatterId,
  V_MatterBudgetDetails.MatterName,
  V_MatterBudgetDetails.MatterOwnerName
  --order by SUM((CASE WHEN  (NOT (InvoiceStatus.Name IS NULL)) THEN (InvoiceSummary.Amount * ExchangeRateDim.ExchangeRate) ELSE CAST(NULL AS FLOAT) END)) desc
  order by [Total Budget] desc,V_MatterBudgetDetails.MatterName asc'
  Print (@SQL)
EXEC(@SQL)