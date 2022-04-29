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
--SET @pDateStart='2017-01-01'; 
--SET @pDateEnd ='2017-12-31';
SET @InvoiceStatus ='Paid'''',''''Processed';

SET @SQL='
exec as user = ''admin''
SELECT TOP 1 Matterid,
[Matter Name],[Currency Code],[Total Budget],
case when [Percent of Budget Consumed] <0 then 0 else [Percent of Budget Consumed] end as [Percent of Budget Consumed],
case when [Percent of Budget Remaining] <0 then 0 
when  [Percent of Budget Consumed]=0.0 then 100 
else [Percent of Budget Remaining] 
end as [Percent of Budget Remaining],
[Budget Remaining]
from
(SELECT 
	MB.Matterid,
	MB.MatterName AS [Matter Name],
	ER.CurrencyCode AS [Currency Code],
	SUM((CASE WHEN (NOT (INVS.[Name] IS NULL)) THEN (INV.Amount * ER.ExchangeRate) ELSE NULL END)) AS [Spend],
	MIN((MB.BudgetAmount * ER1.ExchangeRate)) AS [Total Budget],

ISNULL((( SUM((CASE WHEN (NOT (INVS.[Name] IS NULL)) THEN (INV.Amount * ER.ExchangeRate) ELSE NULL END)) )
/ (MIN((MB.BudgetAmount * ER1.ExchangeRate))))*100,0)  AS ''Percent of Budget Consumed'',

ISNULL( (1- ( SUM((CASE WHEN (NOT (INVS.[Name] IS NULL)) THEN (INV.Amount * ER.ExchangeRate) ELSE NULL END)) )
/ (MIN((MB.BudgetAmount * ER1.ExchangeRate))))*100,100) as ''Percent of Budget Remaining'',

ISNULL((MIN((MB.BudgetAmount * ER1.ExchangeRate)))-( SUM((CASE WHEN (NOT (INVS.Name IS NULL)) THEN (INV.Amount * ER.ExchangeRate) ELSE NULL END))),
   MIN((MB.BudgetAmount * ER1.ExchangeRate))) as ''Budget Remaining''

FROM 
	V_MatterBudgetDetails MB
JOIN BusinessUnitAndAllDescendants BAD ON MB.BusinessUnitId = BAD.ChildBusinessUnitId
JOIN (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
  FROM fn_GetRollupBusinessUnitsWithSecurity (''-1'', ''|'',-1,0)) BUS ON BAD.BusinessUnitId = BUS.RollupBusinessUnitId
LEFT JOIN InvoiceSummary INV ON MB.MatterId = INV.MatterId AND MB.BudgetPeriodId = INV.BudgetPeriodId
LEFT JOIN ExchangeRateDim ER ON INV.ExchangeRateDate = ER.ExchangeRateDate
LEFT JOIN (SELECT [Name] FROM fn_SplitQuotedStrings(''''''' + @InvoiceStatus + ''''''')) INVS ON INV.InvoiceStatus = INVS.[Name]
LEFT JOIN ExchangeRateDim ER1 ON MB.BudgetExchangeRateDate = ER1.ExchangeRateDate
JOIN (SELECT MatterId, SUM(budgetAmount) bAmount 
FROM MatterBudgetSummary
WHERE 1=1
GROUP BY 
	MatterId
) MBA ON MB.MatterId = MBA.Matterid
JOIN PracticeAreaAndAllDescendants PAD ON MB.PracticeAreaId = PAD.ChildPracticeAreaId
JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
  FROM fn_GetRollupPracticeAreasWithSecurity2 (''-1'', ''|'',-1,0)) PAS ON PAD.PracticeAreaId = PAS.RollupPracticeAreaId

WHERE 1 = 1
--AND MB.budgetperiodid = 3
AND MB.budgetperiodid = ^ParamOne^
and inv.InvoiceDate between '''+@pDateStart+''' and '''+@pDateEnd+'''
	AND ((INV.MatterId IS NULL) OR (ER.CurrencyCode = '''+@CurrencyCode+''')) 
	AND ((ER1.CurrencyCode IS NULL) 
	OR (ER1.CurrencyCode = '''+@CurrencyCode+'''))
	GROUP BY 
	MB.Matterid,
	ER.CurrencyCode,
	MB.MatterName) A
ORDER BY [Total Budget] DESC
'
print(@SQL)
exec(@SQL)