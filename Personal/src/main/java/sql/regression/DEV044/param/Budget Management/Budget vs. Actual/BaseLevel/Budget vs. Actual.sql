--use DEV044_IOD_DataMart;

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
SET @InvoiceStatus ='Paid'',''Processed';


SET @SQL = '
exec as user = ''admin''

SELECT top 1 mb.BudgetPeriodId,
mb.BudgetPeriodName as [Budget Period Name],
mb.CurrencyCode as [Currency Code],
CAST(amt.Amount AS FLOAT) as [Spend],
CAST(SUM(mb.MatterBudgetAmount) AS FLOAT) as [Total Budget],
CAST (amt.Amount/ SUM(mb.MatterBudgetAmount) AS FLOAT)*100 as ''Percent of Budget Consumed'',
CASE WHEN (amt.Amount/ CAST(SUM(mb.MatterBudgetAmount) AS FLOAT)) > 0 THEN CAST(1-(amt.Amount/ SUM(mb.MatterBudgetAmount)) AS FLOAT)*100 ELSE 0 END AS ''Percent of Budget Remaining'',
CAST(SUM(mb.MatterBudgetAmount) - amt.Amount AS FLOAT) AS ''Budget Remaining''
FROM (
SELECT
mbi.BudgetPeriodId,
mbi.BudgetPeriodName,
mbi.CurrencyCode,
MIN(mbi.BudgetAmount) AS MatterBudgetAmount
FROM [dbo].[V_MatterBudgetInfo] mbi
WHERE ((CASE WHEN (mbi.IsLOM <> 0) THEN (CASE WHEN (((mbi.MatterOpenDate <= convert (Datetime ,'''+@pDateEnd+''')) AND (ISNULL(mbi.MatterCloseDate, (CASE
WHEN 0 = ISDATE(convert (Datetime ,''9999-12-31'' )) THEN NULL

ELSE DATEADD(day, DATEDIFF(day, 0, convert (Datetime ,''9999-12-31'' )), 0) END)) > convert (Datetime ,'''+@pDateEnd+''') )) OR ((mbi.MatterOpenDate <= convert (Datetime ,'''+@pDateEnd+''')) AND (DATEDIFF(month,ISNULL(mbi.MatterCloseDate, (CASE
WHEN 0 = ISDATE(convert (Datetime ,''9999-12-31'' )) THEN NULL
ELSE DATEADD(day, DATEDIFF(day, 0, convert (Datetime ,''9999-12-31'' )), 0) END)),convert (Datetime ,'''+@pDateEnd+''')) <= 12))) THEN 1 WHEN NOT (((mbi.MatterOpenDate <= convert (Datetime ,'''+@pDateEnd+''')) AND (ISNULL(mbi.MatterCloseDate, (CASE
WHEN 0 = ISDATE(convert (Datetime ,''9999-12-31'' )) THEN NULL
ELSE DATEADD(day, DATEDIFF(day, 0, convert (Datetime ,''9999-12-31'' )), 0) END)) > convert (Datetime ,'''+@pDateEnd+'''))) OR ((mbi.MatterOpenDate <= convert (Datetime ,'''+@pDateEnd+''')) AND (DATEDIFF(month,ISNULL(mbi.MatterCloseDate, (CASE
WHEN 0 = ISDATE(convert (Datetime ,''9999-12-31'' )) THEN NULL
ELSE DATEADD(day, DATEDIFF(day, 0, convert (Datetime ,''9999-12-31'' )), 0) END)),convert (Datetime ,'''+@pDateEnd+''')) <= 12))) THEN 0 ELSE NULL END) ELSE 1 END) <> 0) AND ((CASE WHEN (((mbi.BudgetPeriodStartDate >= convert (Datetime ,'''+@pDateEnd+'''))
AND (mbi.BudgetPeriodEndDate <= DATEADD(second,-1,DATEADD(day,1,convert (Datetime ,'''+@pDateEnd+'''))))) OR ((mbi.BudgetPeriodStartDate <= convert (Datetime ,'''+@pDateStart+'''))
AND (DATEADD(second,-1,DATEADD(day,1,convert (Datetime ,'''+@pDateEnd+'''))) <= mbi.BudgetPeriodEndDate)) OR ((mbi.BudgetPeriodStartDate <= convert (Datetime ,'''+@pDateStart+''')) AND (mbi.BudgetPeriodEndDate >= convert (Datetime ,'''+@pDateStart+'''))) OR ((mbi.BudgetPeriodStartDate >= convert (Datetime ,'''+@pDateStart+'''))
AND (mbi.BudgetPeriodStartDate <= DATEADD(second,-1,DATEADD(day,1,convert (Datetime ,'''+@pDateEnd+''')))) AND (mbi.BudgetPeriodEndDate >= DATEADD(second,-1,DATEADD(day,1,convert (Datetime ,'''+@pDateEnd+''')))))) THEN 1 ELSE 0 END) = 1)
AND mbi.CurrencyCode = '''+@CurrencyCode+'''
GROUP BY
mbi.BudgetPeriodId,
mbi.BudgetPeriodName,
mbi.CurrencyCode,
mbi.MatterId
) mb
JOIN (
SELECT
ili.BudgetPeriodId,
CAST(SUM (ili.Amount) AS FLOAT) Amount
FROM V_InvoiceLineItemSpendFactWithCurrency ili
LEFT JOIN V_MatterBudgetWithSecurity mb on mb.budgetperiodid=ili.budgetperiodid and mb.MatterId=ili.MatterId
WHERE
ili.InvoiceStatus IN ('''+@InvoiceStatus+''')
AND ili.InvoiceDate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
AND ili.CurrencyCode='''+@CurrencyCode+'''
AND mb.CurrencyCode='''+@CurrencyCode+'''
AND mb.BudgetPeriodId IS NOT NULL
GROUP BY
ili.BudgetPeriodId
) amt ON amt.BudgetPeriodId=mb.BudgetPeriodId
GROUP BY
mb.BudgetPeriodId,
mb.BudgetPeriodName,
mb.CurrencyCode,
amt.Amount
'
print(@SQL)
exec(@SQL)