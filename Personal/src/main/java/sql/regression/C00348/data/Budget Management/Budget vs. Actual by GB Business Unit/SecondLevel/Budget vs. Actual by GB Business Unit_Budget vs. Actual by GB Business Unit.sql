--use Q5_C00348_IOD_DATAMART
exec as user='admin'

DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @InvoiceStatus varchar (MAX);
DECLARE @CurrencyCode  varchar (50);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
--SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;

--SET @pDateStart='1/1/2021'; 
--SET @pDateEnd='08/31/2021';
SET @InvoiceStatus ='Paid'''',''''Processed';
--SET @CurrencyCode ='USD';

SET @SQL='
exec as user=''admin''
 SELECT 
[RollupBusinessUnitsWithSecurity].RollupBusinessUnitName AS [Businessunitname],
  MAX([ExchangeRateDim1].[CurrencyCode]) AS [Currency Code],  
 round((SUM((CASE WHEN (NOT ([Invoice Status].[Name] IS NULL)) THEN ([InvoiceSummary].[amount] * [ExchangeRateDim].[ExchangeRate]) ELSE CAST(NULL AS FLOAT) END))),2) AS [Spend], 
 round(( SUM((CASE ISNULL([InvoiceSummary].[budgetrnk], 1) WHEN 1 THEN ([V_MatterBudgetDetails].[BudgetAmount] * [ExchangeRateDim1].[ExchangeRate]) ELSE 0 END))),2)AS [Budget Amount],  
  round((  CAST(SUM((CASE WHEN (NOT ([Invoice Status].[Name] IS NULL)) THEN ([InvoiceSummary].[amount] * [ExchangeRateDim].[ExchangeRate]) ELSE CAST(NULL AS FLOAT) END))
  /SUM((CASE ISNULL([InvoiceSummary].[budgetrnk], 1) WHEN 1 THEN ([V_MatterBudgetDetails].[BudgetAmount] * [ExchangeRateDim1].[ExchangeRate]) ELSE 0 END))
   AS FLOAT)*100),2) as [Percent of Budget Consumed],
round((   CASE WHEN
    CAST(1-((SUM((CASE WHEN (NOT ([Invoice Status].[Name] IS NULL)) THEN ([InvoiceSummary].[amount] * [ExchangeRateDim].[ExchangeRate]) ELSE CAST(NULL AS FLOAT) END))
	/SUM((CASE ISNULL([InvoiceSummary].[budgetrnk], 1) WHEN 1 THEN ([V_MatterBudgetDetails].[BudgetAmount] * [ExchangeRateDim1].[ExchangeRate]) ELSE 0 END))))AS FLOAT) >0 
	THEN CAST(1-((SUM((CASE WHEN (NOT ([Invoice Status].[Name] IS NULL)) THEN ([InvoiceSummary].[amount] * [ExchangeRateDim].[ExchangeRate]) ELSE CAST(NULL AS FLOAT) END))
	/SUM((CASE ISNULL([InvoiceSummary].[budgetrnk], 1) WHEN 1 THEN ([V_MatterBudgetDetails].[BudgetAmount] * [ExchangeRateDim1].[ExchangeRate]) ELSE 0 END))))AS FLOAT)
	 ELSE 0 END *100),2)as [Percent of Budget Remaining],
	round(( LEFT
	 ( STR(CAST((SUM((CASE ISNULL([InvoiceSummary].[budgetrnk], 1) WHEN 1 THEN ([V_MatterBudgetDetails].[BudgetAmount] * [ExchangeRateDim1].[ExchangeRate]) ELSE 0 END)) - 
	  SUM((CASE WHEN (NOT ([Invoice Status].[Name] IS NULL)) THEN ([InvoiceSummary].[amount] * [ExchangeRateDim].[ExchangeRate]) ELSE CAST(NULL AS FLOAT) END))
	  ) AS FLOAT),22,22),22)),2) AS [Budget Remaining]
FROM [dbo].[V_MatterBudgetDetails] [V_MatterBudgetDetails]
  INNER JOIN [dbo].[BusinessUnitAndAllDescendants] [BusinessUnitAndAllDescendants] ON ([V_MatterBudgetDetails].[BusinessUnitId] = [BusinessUnitAndAllDescendants].[ChildBusinessUnitId])
  INNER JOIN (
  SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
  -- FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''16548'',''|'',''16558'',1)
   FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (^ParamOne^, ''|'',^ParamTwo^,1)
  
) [RollupBusinessUnitsWithSecurity] ON ([BusinessUnitAndAllDescendants].[BusinessUnitId] = [RollupBusinessUnitsWithSecurity].[RollupBusinessUnitId])
  LEFT JOIN (
  select invoicestatus, exchangeratedate,amount ,matterid,
     budgetperiodid , ROW_NUMBER() over(partition by matterid,budgetperiodid order by matterid,budgetperiodid) budgetrnk
    from InvoiceSummary
) [InvoiceSummary] ON (([V_MatterBudgetDetails].[MatterId] = [InvoiceSummary].[matterid]) AND ([V_MatterBudgetDetails].[BudgetPeriodId] = [InvoiceSummary].[budgetperiodid]))
  LEFT JOIN [dbo].[ExchangeRateDim] [ExchangeRateDim] ON ([InvoiceSummary].[exchangeratedate] = [ExchangeRateDim].[ExchangeRateDate])
  LEFT JOIN (
  SELECT [Name] FROM fn_SplitQuotedStrings(''''''' + @InvoiceStatus + ''''''')
) [Invoice Status] ON ([InvoiceSummary].[invoicestatus] = [Invoice Status].[Name])
  LEFT JOIN [dbo].[ExchangeRateDim] [ExchangeRateDim1] ON ([V_MatterBudgetDetails].[BudgetExchangeRateDate] = [ExchangeRateDim1].[ExchangeRateDate])
  INNER JOIN [dbo].[PracticeAreaAndAllDescendants] [PracticeAreaAndAllDescendants] ON ([V_MatterBudgetDetails].[PracticeAreaId] = [PracticeAreaAndAllDescendants].[ChildPracticeAreaId])
  INNER JOIN (
  SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
  FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',-1,1)
) [RollupPracticeAreasWithSecurity] ON ([PracticeAreaAndAllDescendants].[PracticeAreaId] = [RollupPracticeAreasWithSecurity].[RollupPracticeAreaId])
WHERE (((CASE WHEN ([V_MatterBudgetDetails].[IsLOM] <> 0) THEN (CASE WHEN ((([V_MatterBudgetDetails].[MatterOpenDate] <= cast('''+@pDateEnd+'''as date)) AND (ISNULL([V_MatterBudgetDetails].[MatterCloseDate], (CASE
    WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
    ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)) > cast('''+@pDateEnd+'''as date))) OR (([V_MatterBudgetDetails].[MatterOpenDate] <= cast('''+@pDateEnd+'''as date)) AND (DATEDIFF(month,ISNULL([V_MatterBudgetDetails].[MatterCloseDate], (CASE
    WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
    ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)),cast('''+@pDateEnd+'''as date)) <= 12))) THEN 1 WHEN NOT ((([V_MatterBudgetDetails].[MatterOpenDate] <= cast('''+@pDateEnd+'''as date)) AND (ISNULL([V_MatterBudgetDetails].[MatterCloseDate], (CASE
    WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
    ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)) > cast('''+@pDateEnd+'''as date))) OR (([V_MatterBudgetDetails].[MatterOpenDate] <= cast('''+@pDateEnd+'''as date)) AND (DATEDIFF(month,ISNULL([V_MatterBudgetDetails].[MatterCloseDate], (CASE
    WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
    ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)),cast('''+@pDateEnd+'''as date)) <= 12))) THEN 0 ELSE NULL END) ELSE 1 END) <> 0) AND ((CASE WHEN ((([V_MatterBudgetDetails].[BudgetPeriodStartDate] >= cast('''+@pDateStart+'''as date)) AND ([V_MatterBudgetDetails].[BudgetPeriodEndDate] <= DATEADD(second,-1,DATEADD(day,1,CAST(cast('''+@pDateEnd+'''as date) as datetime))))) OR (([V_MatterBudgetDetails].[BudgetPeriodStartDate] <= cast('''+@pDateStart+'''as date)) AND (DATEADD(second,-1,DATEADD(day,1,CAST(cast('''+@pDateEnd+'''as date) as datetime))) <= [V_MatterBudgetDetails].[BudgetPeriodEndDate])) OR (([V_MatterBudgetDetails].[BudgetPeriodStartDate] <= cast('''+@pDateStart+'''as date)) AND ([V_MatterBudgetDetails].[BudgetPeriodEndDate] >= cast('''+@pDateStart+'''as date))) OR (([V_MatterBudgetDetails].[BudgetPeriodStartDate] >= cast('''+@pDateStart+'''as date)) AND ([V_MatterBudgetDetails].[BudgetPeriodStartDate] <= DATEADD(second,-1,DATEADD(day,1,CAST(cast('''+@pDateEnd+'''as date) as datetime)))) AND ([V_MatterBudgetDetails].[BudgetPeriodEndDate] >= DATEADD(second,-1,DATEADD(day,1,CAST(cast('''+@pDateEnd+'''as date) as datetime)))))) THEN 1 ELSE 0 END) = 1) AND (([InvoiceSummary].[matterid] IS NULL) 
	OR ([ExchangeRateDim].[CurrencyCode] = ''' + @CurrencyCode + ''')) AND (([ExchangeRateDim1].[CurrencyCode] IS NULL) OR ([ExchangeRateDim1].[CurrencyCode] = ''' + @CurrencyCode + ''')))
GROUP BY 
    [RollupBusinessUnitsWithSecurity].RollupBusinessUnitName
  order by [Spend] desc'
 -- Print (@SQL)
EXEC(@SQL)