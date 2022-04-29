--USE DEV044_IOD_DataMart;
DECLARE @CurrencyCode varchar (50);
DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @InvoiceStatus varchar (MAX);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @CurrencyCode= ^Currency^;
SET @InvoiceStatus= ^InvoiceStatus^;

--SET @CurrencyCode ='USD';
--SET @pDateStart='01/01/2017';
--SET @pDateEnd ='12/31/2017';
--SET @InvoiceStatus ='Paid'',''Processed';



SET @SQL = '
exec as user = ''admin''
SELECT
DISTINCT af.RollupPracticeAreaName as PracticeArea,
ils.AfaRuleTypes as ''AFA Types'', 
  sum(ils.AfaFeeAmount *-1) as ''AFA Adjustments'', 
  COUNT(distinct ils.matterid) as ''# Matter''

FROM
v_invoicelineitemspendfactwithcurrency ils
Right JOIN [dbo].[PracticeAreaAndAllDescendants] [PracticeAreaAndAllDescendants] ON ils.[PracticeAreaId] = [PracticeAreaAndAllDescendants].[ChildPracticeAreaId]
INNER JOIN (
SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
--FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',32477,1)
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',^ParamOne^,1)
) [RollupPracticeArea] ON ([PracticeAreaAndAllDescendants].[PracticeAreaId] = [RollupPracticeArea].[RollupPracticeAreaId])
-- RIGHT join practiceareadim p2 on  p2.level = ''2'' and [PracticeAreaAndAllDescendants].[path] like p2.[Path] + ''%''
RIGHT JOIN (
SELECT
RollupPracticeAreaName,[PracticeAreaAndAllDescendants].practiceareaid,
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
Right JOIN [dbo].[PracticeAreaAndAllDescendants] [PracticeAreaAndAllDescendants] ON ils.[PracticeAreaId] = [PracticeAreaAndAllDescendants].[ChildPracticeAreaId]
INNER JOIN (
SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
--FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',32477,1)
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',^ParamOne^,1)
) [RollupPracticeArea] ON ([PracticeAreaAndAllDescendants].[PracticeAreaId] = [RollupPracticeArea].[RollupPracticeAreaId])
-- inner join practiceareadim p2 on  p2.level = ''2'' and [PracticeAreaAndAllDescendants].[path] like p2.[Path] + ''%''
WHERE
ils.invoicestatus IN ('''+@InvoiceStatus+''')
AND ils.invoicestatusdate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
AND ils.currencycode = '''+@CurrencyCode+'''
AND ils.afaruletypes IS NOT NULL
AND ils.grossfeeamount IS NOT NULL

GROUP BY
RollupPracticeAreaName,[PracticeAreaAndAllDescendants].practiceareaid
) AS af ON 1=1 --af.practiceareaid = ils.practiceareaid
WHERE
ils.invoicestatus IN ('''+@InvoiceStatus+''')
AND ils.invoicestatusdate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
AND ils.currencycode = '''+@CurrencyCode+'''
AND ils.afaruletypes IS NOT NULL
AND ils.grossfeeamount IS NOT NULL


group by 
af.RollupPracticeAreaName,ils.AfaRuleTypes
ORDER BY
af.RollupPracticeAreaName,ils.AfaRuleTypes




'
PRINT(@SQL)
EXEC(@SQL)