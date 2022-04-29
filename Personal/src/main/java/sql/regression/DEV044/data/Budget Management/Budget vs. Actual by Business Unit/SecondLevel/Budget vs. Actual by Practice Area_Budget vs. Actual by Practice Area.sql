--use Dev044_IOD_DATAMART;

DECLARE @CurrencyCode varchar (50);
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
exec as user = ''admin''

SELECT 
	 --MB.BusinessUnitName AS [Business Unit],
	 RollupPracticeAreaName as [Practice Area],
  MIN(ER1.[CurrencyCode]) AS [Currency Code],
  SUM((CASE WHEN (NOT (INVS.[Name] IS NULL)) THEN (INV.amount * ER.ExchangeRate) ELSE NULL END)) AS [Spend],
  SUM((CASE ISNULL(INV.[budgetrnk], 1) WHEN 1 THEN (MB.BudgetAmount * ER1.ExchangeRate) ELSE 0 END)) AS [Total Budget],

     SUM((CASE WHEN (NOT (INVS.[Name] IS NULL)) THEN (INV.amount * ER.ExchangeRate) ELSE NULL END)) /
  SUM((CASE ISNULL(INV.[budgetrnk], 1) WHEN 1 THEN (MB.BudgetAmount * ER1.ExchangeRate) ELSE 0 END)) *100  AS [Percent of Budget Consumed],

  ABS(SUM((CASE WHEN (NOT (INVS.[Name] IS NULL)) THEN (INV.amount * ER.ExchangeRate) ELSE NULL END)) 
   -  SUM((CASE ISNULL(INV.budgetrnk, 1) WHEN 1 THEN (MB.BudgetAmount * ER1.ExchangeRate) ELSE 0 END))) 
 / NULLIF( SUM((CASE ISNULL(INV.budgetrnk, 1) WHEN 1 THEN (MB.BudgetAmount * ER1.ExchangeRate) ELSE 0 END)),0) *100  as [Percent of Budget Remaining],

 ABS(SUM((CASE WHEN (NOT (INVS.[Name] IS NULL)) THEN (INV.amount * ER.ExchangeRate) ELSE NULL END)) 
  -  SUM((CASE ISNULL(INV.budgetrnk, 1) WHEN 1 THEN (MB.BudgetAmount * ER1.ExchangeRate) ELSE 0 END)))    AS [Budget Remaining] 
 
FROM 

	V_MatterBudgetDetails MB
JOIN BusinessUnitAndAllDescendants BAD ON MB.BusinessUnitId = BAD.ChildBusinessUnitId
JOIN (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
-- FROM fn_GetRollupBusinessUnitsWithSecurity (''14883'', ''|'',-1,1)) BUS
  FROM fn_GetRollupBusinessUnitsWithSecurity (''^ParamOne^'', ''|'',-1,1)) BUS
  ON BAD.BusinessUnitId = BUS.RollupBusinessUnitId
LEFT JOIN (
  SELECT invoicestatus, exchangeratedate,amount ,matterid,
     budgetperiodid , ROW_NUMBER() OVER(PARTITION BY matterid,budgetperiodid ORDER BY matterid,budgetperiodid) budgetrnk
    FROM InvoiceSummary
	where InvoiceDate between '''+@pDateStart+''' and '''+@pDateEnd+'''
) INV ON MB.MatterId = INV.matterid AND MB.BudgetPeriodId = INV.budgetperiodid
LEFT JOIN ExchangeRateDim ER ON INV.exchangeratedate = ER.ExchangeRateDate
LEFT JOIN (SELECT [Name] FROM fn_SplitQuotedStrings(''''''' + @InvoiceStatus + ''''''')
) INVS ON INV.invoicestatus = INVS.[Name]
LEFT JOIN ExchangeRateDim ER1 ON MB.BudgetExchangeRateDate = ER1.ExchangeRateDate
JOIN PracticeAreaAndAllDescendants PAD ON MB.PracticeAreaId = PAD.ChildPracticeAreaId
JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
  --FROM fn_GetRollupPracticeAreasWithSecurity2 (''32480'', ''|'',-1,0)) PAS
  FROM fn_GetRollupPracticeAreasWithSecurity2 (''^ParamTwo^'', ''|'',-1,0)) PAS
  ON PAD.PracticeAreaId = PAS.RollupPracticeAreaId

WHERE 1= 1

/*(((CASE WHEN (MB.IsLOM <> 0) THEN (CASE WHEN (((MB.MatterOpenDate <= (SELECT CAST(eomonth(GETDATE()) AS datetime))) 
AND (ISNULL(MB.MatterCloseDate, (CASE
	WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
	ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)) > (SELECT CAST(eomonth(GETDATE()) AS datetime)))) 
	OR ((MB.MatterOpenDate <= (SELECT CAST(eomonth(GETDATE()) AS datetime))) 
	AND (DATEDIFF(month,ISNULL(MB.MatterCloseDate, (CASE
	WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
	ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)),(SELECT CAST(eomonth(GETDATE()) AS datetime))) <= 12))) 
	THEN 1 WHEN NOT (((MB.MatterOpenDate <= (SELECT CAST(eomonth(GETDATE()) AS datetime))) 
	AND (ISNULL(MB.MatterCloseDate, (CASE
	WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
	ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)) > (SELECT CAST(eomonth(GETDATE()) AS datetime)))) 
	OR ((MB.MatterOpenDate <= (SELECT CAST(eomonth(GETDATE()) AS datetime))) 
	AND (DATEDIFF(month,ISNULL(MB.MatterCloseDate, (CASE
	WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
	ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)),(SELECT CAST(eomonth(GETDATE()) AS datetime))) <= 12))) 
	THEN 0 ELSE NULL END) ELSE 1 END) <> 0) AND ((CASE WHEN (((MB.BudgetPeriodStartDate >= (select DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-11, 0) )) 
	AND (MB.BudgetPeriodEndDate <= DATEADD(second,-1,DATEADD(day,1,CAST((SELECT CAST(eomonth(GETDATE()) AS datetime)) as datetime))))) 
	OR ((MB.BudgetPeriodStartDate <= (select DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-11, 0) )) 
	AND (DATEADD(second,-1,DATEADD(day,1,CAST((SELECT CAST(eomonth(GETDATE()) AS datetime)) as datetime))) <= MB.BudgetPeriodEndDate)) 
	OR ((MB.BudgetPeriodStartDate <= (select DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-11, 0) )) 
	AND (MB.BudgetPeriodEndDate >= (select DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-11, 0) ))) 
	OR ((MB.BudgetPeriodStartDate >= (select DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-11, 0) )) 
	AND (MB.BudgetPeriodStartDate <= DATEADD(second,-1,DATEADD(day,1,CAST((SELECT CAST(eomonth(GETDATE()) AS datetime)) as datetime)))) 
	AND (MB.BudgetPeriodEndDate >= DATEADD(second,-1,DATEADD(day,1,CAST((SELECT CAST(eomonth(GETDATE()) AS datetime)) as datetime)))))) THEN 1 ELSE 0 END) = 1) */
	AND ((INV.[matterid] IS NULL) 
	OR (ER.CurrencyCode = '''+@CurrencyCode+''')) 
	AND ((ER1.CurrencyCode IS NULL) 
	OR (ER1.CurrencyCode = '''+@CurrencyCode+'''))
GROUP BY 
	MB.BusinessUnitName,RollupPracticeAreaName
ORDER BY Spend DESC
'
print(@SQL)
exec(@SQL)