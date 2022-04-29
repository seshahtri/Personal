--use Q5_C00348_IOD_DATAMART

DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @CurrencyCode  varchar (50);
DECLARE @InvoiceStatus varchar (MAX);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @CurrencyCode= ^Currency^;
SET @InvoiceStatus= ^InvoiceStatus^;

--SET @InvoiceStatus ='Paid'',''Processed';
--SET @pDateStart='1/1/2021'; 
--SET @pDateEnd='12/31/2021';
--SET @CurrencyCode ='USD';

SET @SQL='
EXEC AS USER = ''admin''
SELECT 
	RollupBusinessUnitName as [Business Unit],
	ed.CurrencyCode as [Currency Code],
	CAST(SUM(amt.Amount) AS FLOAT) as [Spend],
	CAST(SUM(vb.BudgetAmount) AS FLOAT) as [Total Budget],
	CAST(SUM(amt.Amount)/SUM(vb.BudgetAmount) AS FLOAT) *100 as  [Percent of Budget Consumed],
	CASE WHEN CAST(1-((SUM(amt.Amount)/SUM(vb.BudgetAmount)))AS FLOAT) >0 THEN CAST(1-((SUM(amt.Amount)/SUM(vb.BudgetAmount)))AS FLOAT) ELSE 0 END *100 as [Percent of Budget Remaining],
	CAST((SUM(vb.BudgetAmount) - SUM(amt.Amount)) AS FLOAT) AS [Budget Remaining]
FROM V_VendorBudgetDetails vb
join ExchangeRateDim ed on ed.ExchangeRateDate = vb.BudgetExchangeRateDate
  JOIN businessunitandalldescendants BUD 
         ON VB.businessunitid = BUD.childbusinessunitid 
       JOIN 
              (SELECT rollupbusinessunitid, 
                    rollupbusinessunitname, 
                    rollupbusinessunitpath, 
                    rollupbusinessunitdisplaypath, 
                    rollupbusinessunitlevel 
             FROM   [dbo].[Fn_getrollupbusinessunitswithsecurity] (''-1'', ''|'', -1 
                    , 1)) 
              BUS 
         ON BUD.businessunitid = BUS.rollupbusinessunitid 
         JOIN practiceareaandalldescendants PAD 
                 ON VB.practiceareaid = PAD.childpracticeareaid 
               JOIN (SELECT rolluppracticeareaid, 
                            rolluppracticeareaname, 
                            rolluppracticeareapath, 
                            rolluppracticeareadisplaypath, 
                            rolluppracticearealevel 
                     FROM   Fn_getrolluppracticeareaswithsecurity (''-1'', ''|'', -1 
                            , 1)) 
                    PASEC 
                 ON PAD.practiceareaid = PASEC.rolluppracticeareaid 
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
				AND ili.CurrencyCode=''' + @CurrencyCode + '''
				AND vb.BudgetPeriodId IS NOT NULL
				AND vb.VendorId = ^ParamOne^ --44228
				GROUP BY
				ili.BudgetPeriodId,
				ili.MatterId,
				ili.VendorId
		) amt ON amt.BudgetPeriodId=vb.BudgetPeriodId AND amt.MatterId=vb.MatterId AND amt.VendorId=vb.VendorId
	JOIN V_Vendor v on vb.VendorId=v.VendorId
WHERE 
		ed.CurrencyCode=''' + @CurrencyCode + ''' 
		AND vb.VendorId = ^ParamOne^ --44228
		AND (
			(vb.BudgetPeriodStartDate >= cast('''+@pDateStart+'''as date) AND vb.BudgetPeriodEndDate <= cast('''+@pDateEnd+'''as date)) 
			OR (vb.BudgetPeriodStartDate <= cast('''+@pDateStart+'''as date) AND vb.BudgetPeriodEndDate >= cast('''+@pDateEnd+'''as date))
			OR (vb.BudgetPeriodStartDate <= cast('''+@pDateStart+'''as date) AND vb.BudgetPeriodEndDate >= cast('''+@pDateStart+'''as date)) 
			OR (vb.BudgetPeriodStartDate >= cast('''+@pDateStart+'''as date) AND vb.BudgetPeriodStartDate <= cast('''+@pDateEnd+'''as date) AND vb.BudgetPeriodEndDate >= cast('''+@pDateEnd+'''as date)) 
		)
	AND
	 ((CASE WHEN (vb.[IsLOM] <> 0) 
THEN (CASE WHEN (((vb.[MatterOpenDate] <= {d ''2019-12-31''}) 
AND (ISNULL(vb.[MatterCloseDate], (CASE
    WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
    ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)) > cast('''+@pDateEnd+'''as date))) OR ((vb.[MatterOpenDate] <= cast('''+@pDateEnd+'''as date)) AND (DATEDIFF(month,ISNULL(vb.[MatterCloseDate], (CASE
    WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
    ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)),cast('''+@pDateEnd+'''as date)) <= 12))) THEN 1 WHEN NOT (((vb.[MatterOpenDate] <= cast('''+@pDateEnd+'''as date)) AND (ISNULL(vb.[MatterCloseDate], (CASE
    WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
    ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)) > cast('''+@pDateEnd+'''as date))) OR ((vb.[MatterOpenDate] <= cast('''+@pDateEnd+'''as date)) AND (DATEDIFF(month,ISNULL(vb.[MatterCloseDate], (CASE
    WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
    ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)),cast('''+@pDateEnd+'''as date)) <= 12))) THEN 0 ELSE NULL END) ELSE 1 END) <> 0)
GROUP BY
rollupbusinessunitid,
	RollupBusinessUnitName,
	ed.CurrencyCode
ORDER BY SUM(amt.Amount) DESC'

print(@SQL)
exec(@SQL)