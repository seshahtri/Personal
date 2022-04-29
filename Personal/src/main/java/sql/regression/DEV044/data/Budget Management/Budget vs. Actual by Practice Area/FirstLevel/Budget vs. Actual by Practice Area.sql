
DECLARE @CurrencyCode  varchar (50);
DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @InvoiceStatus varchar (MAX);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @CurrencyCode= ^Currency^;
--SET @InvoiceStatus= ^InvoiceStatus^;

--SET @CurrencyCode ='USD';
--SET @pDateStart='1/1/2017'; 
--SET @pDateEnd='12/31/2017';
SET @InvoiceStatus ='Paid'''',''''Processed';

SET @SQL='
exec as user=''admin''
SELECT [RollupPracticeAreasWithSecurity].[RollupPracticeAreaName] AS [GB Client],  MAX([ExchangeRateDim1].[CurrencyCode]) AS [Currency Code],  
 round((SUM((CASE WHEN (NOT ([Invoice Status].[Name] IS NULL)) THEN ([InvoiceSummary].[amount] * [ExchangeRateDim].[ExchangeRate]) ELSE CAST(NULL AS FLOAT) END))),7) AS [Spend],  
 round(( SUM((CASE ISNULL([InvoiceSummary].[budgetrnk], 1) WHEN 1 THEN ([V_MatterBudgetDetails].[BudgetAmount] * [ExchangeRateDim1].[ExchangeRate]) ELSE 0 END))),7)AS [Budget Amount],  
  Round(( CAST(SUM((CASE WHEN (NOT ([Invoice Status].[Name] IS NULL)) THEN ([InvoiceSummary].[amount] * [ExchangeRateDim].[ExchangeRate]) ELSE CAST(NULL AS FLOAT) END))
/SUM((CASE ISNULL([InvoiceSummary].[budgetrnk], 1) WHEN 1 THEN ([V_MatterBudgetDetails].[BudgetAmount] * [ExchangeRateDim1].[ExchangeRate]) ELSE 0 END))
AS FLOAT) *100 ),2)as [Percent of Budget Consumed],
   Round(( CASE WHEN
CAST(1-((SUM((CASE WHEN (NOT ([Invoice Status].[Name] IS NULL)) THEN ([InvoiceSummary].[amount] * [ExchangeRateDim].[ExchangeRate]) ELSE CAST(NULL AS FLOAT) END))
/SUM((CASE ISNULL([InvoiceSummary].[budgetrnk], 1) WHEN 1 THEN ([V_MatterBudgetDetails].[BudgetAmount] * [ExchangeRateDim1].[ExchangeRate]) ELSE 0 END))))AS FLOAT) *100 >0 
THEN CAST(1-((SUM((CASE WHEN (NOT ([Invoice Status].[Name] IS NULL)) THEN ([InvoiceSummary].[amount] * [ExchangeRateDim].[ExchangeRate]) ELSE CAST(NULL AS FLOAT) END))
/SUM((CASE ISNULL([InvoiceSummary].[budgetrnk], 1) WHEN 1 THEN ([V_MatterBudgetDetails].[BudgetAmount] * [ExchangeRateDim1].[ExchangeRate]) ELSE 0 END))))AS FLOAT) *100
ELSE 0 END),1) as [Percent of Budget Remaining],

    round(( LEFT
     ( STR(CAST((SUM((CASE ISNULL([InvoiceSummary].[budgetrnk], 1) WHEN 1 THEN ([V_MatterBudgetDetails].[BudgetAmount] * [ExchangeRateDim1].[ExchangeRate]) ELSE 0 END)) - 
      SUM((CASE WHEN (NOT ([Invoice Status].[Name] IS NULL)) THEN ([InvoiceSummary].[amount] * [ExchangeRateDim].[ExchangeRate]) ELSE CAST(NULL AS FLOAT) END))
      ) AS FLOAT),22,22),22)),7) AS [Budget Remaining]



FROM [dbo].[V_MatterBudgetDetails] [V_MatterBudgetDetails]
  INNER JOIN [dbo].[BusinessUnitAndAllDescendants] [BusinessUnitAndAllDescendants] ON ([V_MatterBudgetDetails].[BusinessUnitId] = [BusinessUnitAndAllDescendants].[ChildBusinessUnitId])
  INNER JOIN (
  SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
  FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''-1'',''|'',-1,0)
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
  FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',^ParamOne^,1)
  --FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',''32475'',1)
) [RollupPracticeAreasWithSecurity] ON ([PracticeAreaAndAllDescendants].[PracticeAreaId] = [RollupPracticeAreasWithSecurity].[RollupPracticeAreaId])
WHERE (((CASE WHEN ([V_MatterBudgetDetails].[IsLOM] <> 0) THEN (CASE WHEN ((([V_MatterBudgetDetails].[MatterOpenDate] <= cast('''+@pDateEnd+'''as date)) AND (ISNULL([V_MatterBudgetDetails].[MatterCloseDate], (CASE
    WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
    ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)) > cast('''+@pDateEnd+''' as date))) OR (([V_MatterBudgetDetails].[MatterOpenDate] <= cast('''+@pDateEnd+'''as date)) AND (DATEDIFF(month,ISNULL([V_MatterBudgetDetails].[MatterCloseDate], (CASE
    WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
    ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)),cast('''+@pDateEnd+'''as date)) <= 12))) THEN 1 WHEN NOT ((([V_MatterBudgetDetails].[MatterOpenDate] <= cast('''+@pDateEnd+'''as date)) AND (ISNULL([V_MatterBudgetDetails].[MatterCloseDate], (CASE
    WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
    ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)) > cast('''+@pDateEnd+'''as date))) OR (([V_MatterBudgetDetails].[MatterOpenDate] <= cast('''+@pDateEnd+'''as date)) AND (DATEDIFF(month,ISNULL([V_MatterBudgetDetails].[MatterCloseDate], (CASE
    WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
    ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)),cast('''+@pDateEnd+'''as date)) <= 12))) THEN 0 ELSE NULL END) ELSE 1 END) <> 0) AND ((CASE WHEN ((([V_MatterBudgetDetails].[BudgetPeriodStartDate] >= cast('''+@pDateStart+'''as date)) AND ([V_MatterBudgetDetails].[BudgetPeriodEndDate] <= DATEADD(second,-1,DATEADD(day,1,CAST('''+@pDateEnd+''' as datetime))))) OR (([V_MatterBudgetDetails].[BudgetPeriodStartDate] <= '''+@pDateStart+''') AND (DATEADD(second,-1,DATEADD(day,1,CAST('''+@pDateEnd+''' as datetime))) <= [V_MatterBudgetDetails].[BudgetPeriodEndDate])) OR (([V_MatterBudgetDetails].[BudgetPeriodStartDate] <= '''+@pDateStart+''') AND ([V_MatterBudgetDetails].[BudgetPeriodEndDate] >= '''+@pDateStart+''')) OR (([V_MatterBudgetDetails].[BudgetPeriodStartDate] >= '''+@pDateStart+''') AND ([V_MatterBudgetDetails].[BudgetPeriodStartDate] <= DATEADD(second,-1,DATEADD(day,1,CAST('''+@pDateEnd+''' as datetime)))) AND ([V_MatterBudgetDetails].[BudgetPeriodEndDate] >= DATEADD(second,-1,DATEADD(day,1,CAST('''+@pDateEnd+''' as datetime)))))) THEN 1 ELSE 0 END) = 1) AND (([InvoiceSummary].[matterid] IS NULL) 
	OR ([ExchangeRateDim].[CurrencyCode] = ''' + @CurrencyCode + ''')) AND (([ExchangeRateDim1].[CurrencyCode] IS NULL) OR ([ExchangeRateDim1].[CurrencyCode] = ''' + @CurrencyCode + ''')))
GROUP BY 
  [RollupPracticeAreasWithSecurity].[RollupPracticeAreaName]
  order by [Budget Amount] desc'
Print (@SQL)
EXEC(@SQL)