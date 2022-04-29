---use Q5_C00348_IOD_DataMart

DECLARE @CurrencyCode  varchar (50);
DECLARE @pDateStart varchar (MAX);
DECLARE @pDateEnd varchar (MAX);
DECLARE @InvoiceStatus nvarchar (MAX);
DECLARE @SQL VARCHAR(MAX);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
--SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;

--SET @CurrencyCode ='USD';
--SET @pDateStart='1/1/2021';
--SET @pDateEnd='08/31/2021';
SET @InvoiceStatus = 'Paid'',''Processed';

SET @SQL='
execute as user =''admin''
SELECT 
 v.VendorName as [Vendor Name],
vb.city as [City],
vb.StateProvCode as [State],
ed.CurrencyCode as [Currency Code],
LEFT( STR(CAST(SUM(amt.Amount) AS FLOAT),22,22),22) as [Spend],
LEFT( STR(CAST(SUM(vb.BudgetAmount) AS FLOAT),22,22),22) as [Total Budget],
(CAST(SUM(amt.Amount)/SUM(vb.BudgetAmount) AS FLOAT))*100 as [Percent of Budget Consumed],
(CASE WHEN CAST(1-((SUM(amt.Amount)/SUM(vb.BudgetAmount)))AS FLOAT) >0 THEN CAST(1-((SUM(amt.Amount)/SUM(vb.BudgetAmount)))AS FLOAT) ELSE 0 END )*100 as [Percent of Budget Remaining],
LEFT( STR(CAST((SUM(vb.BudgetAmount) - SUM(amt.Amount)) AS FLOAT),22,22),22) AS [Budget Remaining]
FROM V_VendorBudgetDetails vb
join ExchangeRateDim ed on ed.ExchangeRateDate = vb.BudgetExchangeRateDate
INNER JOIN [dbo].[BusinessUnitAndAllDescendants] [BusinessUnitAndAllDescendants] ON (vb.[BusinessUnitId] = [BusinessUnitAndAllDescendants].[ChildBusinessUnitId])
INNER JOIN (
SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
 -- FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''16548'',''|'',-1,0)
  FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (^ParamOne^,''|'',-1,0)
) [RollupBusinessUnitsWithSecurity] ON ([BusinessUnitAndAllDescendants].[BusinessUnitId] = [RollupBusinessUnitsWithSecurity].[RollupBusinessUnitId])
INNER JOIN [dbo].[PracticeAreaAndAllDescendants] [PracticeAreaAndAllDescendants] ON (vb.[PracticeAreaId] = [PracticeAreaAndAllDescendants].[ChildPracticeAreaId])
INNER JOIN (
SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
-- FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',''42406'',1)
 FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',^ParamTwo^,1)
) [RollupPracticeAreasWithSecurity] ON ([PracticeAreaAndAllDescendants].[PracticeAreaId] = [RollupPracticeAreasWithSecurity].[RollupPracticeAreaId])
LEFT JOIN (
SELECT
ili.BudgetPeriodId,
ili.MatterId,
ili.VendorId,
CAST(SUM (ili.Amount) AS FLOAT) Amount
FROM V_InvoiceLineItemSpendFactWithCurrency ili
LEFT JOIN V_VendorBudgetDetails vb on vb.budgetperiodid=ili.budgetperiodid and vb.MatterId=ili.MatterId AND vb.VendorId=ili.VendorId
WHERE
ili.InvoiceStatus IN (''' + @InvoiceStatus + ''')
--AND ili.InvoiceDate BETWEEN (select DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-11, 0) ) AND (SELECT CAST(eomonth(GETDATE()) AS datetime))
AND ili.CurrencyCode=''' + @CurrencyCode + '''
AND vb.BudgetPeriodId IS NOT NULL

GROUP BY
ili.BudgetPeriodId,
ili.MatterId,
ili.VendorId
) amt ON amt.BudgetPeriodId=vb.BudgetPeriodId AND amt.MatterId=vb.MatterId AND amt.VendorId=vb.VendorId
JOIN V_Vendor v on vb.VendorId=v.VendorId
WHERE
ed.CurrencyCode=''' + @CurrencyCode + '''
AND (
(vb.BudgetPeriodStartDate >= cast('''+@pDateStart+'''as date) AND vb.BudgetPeriodEndDate <= cast('''+@pDateEnd+'''as date))
OR (vb.BudgetPeriodStartDate <= cast('''+@pDateStart+'''as date) AND vb.BudgetPeriodEndDate >= cast('''+@pDateEnd+'''as date))
OR (vb.BudgetPeriodStartDate <= cast('''+@pDateStart+'''as date) AND vb.BudgetPeriodEndDate >= cast('''+@pDateEnd+'''as date))
OR (vb.BudgetPeriodStartDate >= cast('''+@pDateStart+'''as date) AND vb.BudgetPeriodStartDate <= cast('''+@pDateEnd+'''as date) AND vb.BudgetPeriodEndDate >= cast('''+@pDateEnd+'''as date))
)

AND
((CASE WHEN (vb.[IsLOM] <> 0)
THEN (CASE WHEN (((vb.[MatterOpenDate] <= (cast('''+@pDateEnd+'''as date)))
AND (ISNULL(vb.[MatterCloseDate], (CASE
WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)) > (cast('''+@pDateEnd+'''as date)))) OR ((vb.[MatterOpenDate] <= (cast('''+@pDateEnd+'''as date))) AND (DATEDIFF(month,ISNULL(vb.[MatterCloseDate], (CASE
WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)),(cast('''+@pDateEnd+'''as date))) <= 12))) THEN 1 WHEN NOT (((vb.[MatterOpenDate] <= (cast('''+@pDateEnd+'''as date))) AND (ISNULL(vb.[MatterCloseDate], (CASE
WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)) > (cast('''+@pDateEnd+'''as date)))) OR ((vb.[MatterOpenDate] <= (cast('''+@pDateEnd+'''as date))) AND (DATEDIFF(month,ISNULL(vb.[MatterCloseDate], (CASE
WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)),(cast('''+@pDateEnd+'''as date))) <= 12))) THEN 0 ELSE NULL END) ELSE 1 END) <> 0)
GROUP BY
v.VendorName,
ed.CurrencyCode,
vb.city,
vb.StateProvCode
ORDER BY SUM(amt.Amount) DESC
'
Print @SQL
EXEC(@SQL)