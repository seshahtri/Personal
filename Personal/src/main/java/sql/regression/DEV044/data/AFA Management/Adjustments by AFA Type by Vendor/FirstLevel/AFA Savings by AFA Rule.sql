DECLARE @pDateStart varchar (50);
DECLARE @pDateEnd varchar (50);
DECLARE @InvoiceStatus nvarchar (1000);
DECLARE @CurrencyCode varchar (50);
DECLARE @SQL VARCHAR(4000);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;

--SET @pDateStart='1/1/2017';
--SET @pDateEnd='12/31/2017';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';


SET @SQL='
EXEC AS USER =''admin''
--AFA Savings by AFA Rule--
SELECT
DISTINCT ils.Afanames as [AFA Rule],ils.afaruletypes AS [AFA Type],
af.[Billed Fees],
af.[AFA Savings] *-1 as [AFA Savings],
(af.[Reviewer Adjustments])*-1 as [Reviewer Adjustments],
CAST(
(
af.allfeeadjustment - af.[AFA Savings] - af.[Reviewer Adjustments]
)*-1 AS FLOAT
) AS [Other Adjustments],
af.[Paid Fees],
CAST(
af.[AFA Savings] / NULLIF(af.[Billed Fees], 0)*-1 AS FLOAT
)*100 AS [ % AFA Saved],
CAST(
(af.[Billed Fees] - af.[Paid Fees])/ NULLIF(af.[Billed Fees], 0) AS FLOAT
) AS [ % Overall Saved],
af.[ # Matters]
FROM
v_invoicelineitemspendfactwithcurrency ils
JOIN (
SELECT
ils.Afanames,ils.afaruletypes,
sum(
CASE WHEN category = ''ADJUSTMENT'' THEN CAST(netfeeamount AS FLOAT) else 0 END
) AS allfeeadjustment,
CAST(
(
sum(ils.grossfeeamount)
) AS FLOAT
) AS [Billed Fees],
CAST(
(
sum(ils.afafeeamount)
) AS FLOAT
) AS [AFA Savings],
CAST(
(
sum(ils.reviewerfeeamount)
) AS FLOAT
) AS [Reviewer Adjustments],
CAST(
(
sum(ils.netfeeamount)
) AS FLOAT
) AS [Paid Fees],
count (DISTINCT matterid) AS [ # Matters]
FROM
v_invoicelineitemspendfactwithcurrency ils
WHERE
ils.invoicestatus IN ('''+@InvoiceStatus+''')
AND ils.invoicestatusdate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
AND ils.currencyid = 1
AND ils.afaruletypes IS NOT NULL
AND ils.grossfeeamount IS NOT NULL
--AND vendorid = 9000001
AND vendorid = ^ParamOne^
GROUP BY
ils.afaruletypes, ils.Afanames
) AS af ON af.Afanames = ils.Afanames
WHERE
ils.invoicestatus IN ('''+@InvoiceStatus+''')
AND ils.invoicestatusdate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
AND ils.currencyid = 1
AND ils.afaruletypes IS NOT NULL
--AND vendorid = 9000001
AND vendorid = ^ParamOne^
ORDER BY
[AFA Rule]




'



Print @SQL
EXEC(@SQL)