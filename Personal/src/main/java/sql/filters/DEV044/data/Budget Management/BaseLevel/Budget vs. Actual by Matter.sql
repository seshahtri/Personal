--use DEV044_IOD_DataMart;

DECLARE @CurrencyCode varchar (50);
DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @DateField varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @InvoiceStatus varchar (MAX);
DECLARE @MatterName varchar (1000);
DECLARE @MatterOwnerName varchar (1000);
DECLARE @MatterNumber varchar (1000);
DECLARE @MatterStatus varchar (1000);
DECLARE @PracticeAreaName varchar (1000);
DECLARE @PracticeAreaId varchar(1000);
DECLARE @BusinessUnitName varchar (1000);
DECLARE @BusinessUnitId varchar(100);
DECLARE @MatterDynamicField1 varchar (1000);
DECLARE @MatterDynamicField2 varchar (1000);
DECLARE @MatterVendorDynamicField1 varchar (1000);
DECLARE @MatterVendorDynamicField2 varchar (1000);


SET @pDateStart=^StartDate^;
SET @pDateEnd=^EndDate^;
SET @InvoiceStatus=^InvoiceStatus^;
SET @CurrencyCode=^Currency^;
SET @DateField=^InvoiceDate^;
SET @MatterName=^MatterName^;
SET @MatterNumber=^MatterNumber^;
SET @MatterStatus=^MatterStatus^;
SET @MatterOwnerName=^MatterOwner^;;
SET @PracticeAreaName=^PracticeArea^;
SET @BusinessUnitName=^BusinessUnit^;
SET @MatterDynamicField1= ^DFMatterDynamicField1^;
SET @MatterDynamicField2= ^DFMatterDynamicField2^;
SET @MatterVendorDynamicField1=^DFMatterVendorDynamicField1^;
SET @MatterVendorDynamicField2=^DFMatterVendorDynamicField2^;



--SET @CurrencyCode ='USD';
--SET @pDateStart='2017-01-01';
--SET @pDateEnd ='2017-12-31';
SET @InvoiceStatus ='Paid'''',''''Processed';
--SET @MatterName='-1';
--SET @MatterStatus='-1';
--SET @PracticeAreaName ='-1';
--SET @BusinessUnitName='-1';
--SET @MatterDF01='-1';
--SET @MatterDF02='-1';
--SET @MatterNumber='-1';
--SET @MatterOwnerName='-1'
--SET @MatterName='Matter 3686999';
--SET @MatterStatus='Closed';
--SET @PracticeAreaName ='Employment and Labor';
--SET @BusinessUnitName='International';
--SET @MatterNumber='1155280';
--SET @MatterOwnerName='Halpert, Jim'
--SET @MatterDF01='Unspecified';
--SET @MatterDF02='Unspecified';

SET @PracticeAreaId = ISNULL((SELECT TOP 1 p.PracticeAreaId FROM PracticeAreaDim p WHERE p.PracticeAreaName = @PracticeAreaName),-1)
SET @BusinessUnitId = ISNULL((SELECT TOP 1 b.BusinessUnitId FROM BusinessUnitDim b where b.BusinessUnitName = @BusinessUnitName),-1)

SET @SQL='
exec as user = ''admin''
SELECT [Matter Name],[Currency Code],[Spend],[Total Budget],
case when [Percent of Budget Consumed] <0 then 0 else [Percent of Budget Consumed] end as [Percent of Budget Consumed],
case when [Percent of Budget Remaining] <0 then 0 
when  [Percent of Budget Consumed]=0.0 then 100 
else [Percent of Budget Remaining] 
end as [Percent of Budget Remaining],
[Budget Remaining]
from(

SELECT

MB.MatterName AS [Matter Name],
ER.CurrencyCode AS [Currency Code],
SUM((CASE WHEN (NOT (INVS.[Name] IS NULL)) THEN (INV.Amount * ER.ExchangeRate) ELSE NULL END)) AS [Spend],
MIN((MB.BudgetAmount * ER1.ExchangeRate)) AS [Total Budget],

CAST(ROUND(ISNULL((( SUM((CASE WHEN (NOT (INVS.[Name] IS NULL)) THEN (INV.Amount * ER.ExchangeRate) ELSE NULL END)) )
/ (MIN((MB.BudgetAmount * ER1.ExchangeRate)))),0), 3) AS DECIMAL(10,3)) *100 AS ''Percent of Budget Consumed'',


CAST(ROUND(ISNULL( (1- ( SUM((CASE WHEN (NOT (INVS.[Name] IS NULL)) THEN (INV.Amount * ER.ExchangeRate) ELSE NULL END)) )
/ (MIN((MB.BudgetAmount * ER1.ExchangeRate)))),100), 3) AS DECIMAL(10,3)) *100 as ''Percent of Budget Remaining'',

ISNULL((MIN((MB.BudgetAmount * ER1.ExchangeRate)))-( SUM((CASE WHEN (NOT (INVS.Name IS NULL)) THEN (INV.Amount * ER.ExchangeRate) ELSE NULL END))),
   MIN((MB.BudgetAmount * ER1.ExchangeRate))) as ''Budget Remaining''

FROM
V_MatterBudgetDetails MB

INNER JOIN BusinessUnitAndAllDescendants bud ON MB.BusinessUnitId = bud.ChildBusinessUnitId
INNER JOIN (
SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM fn_GetRollupBusinessUnitsWithSecurity ('''+ @BusinessUnitId +''', ''|'',-1,0)
) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId

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
INNER JOIN PracticeAreaAndAllDescendants pad ON MB.PracticeAreaId = pad.ChildPracticeAreaId
INNER JOIN (
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM fn_GetRollupPracticeAreasWithSecurity2 (''' + @PracticeAreaId +''', ''|'',-1,0)
) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId

WHERE 1 = 1
and inv.InvoiceDate between '''+@pDateStart+''' and '''+@pDateEnd+'''

AND (ISNULL('''+@MatterName +''', ''-1'') = ''-1'' OR mb.MatterName='''+ @MatterName +''')
AND (ISNULL(''' + @MatterOwnerName + ''', ''-1'') = ''-1'' OR mb.MatterOwnerName=''' + @MatterOwnerName + ''')
AND (ISNULL('''+@MatterNumber +''', ''-1'') = ''-1'' OR mb.MatterNumber='''+ @MatterNumber +''')


AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR
CASE WHEN mb.MatterCloseDate IS NULL THEN ''Open''
WHEN mb.MatterCloseDate > ''' + @pDateEnd + ''' THEN ''Open''
ELSE ''Closed'' END =''' + @MatterStatus + ''')

AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR MatterDF01=''' + @MatterDynamicField1 + ''')
AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR MatterDF02=''' + @MatterDynamicField2 + ''')

AND ((INV.MatterId IS NULL) OR (ER.CurrencyCode = '''+@CurrencyCode+'''))
AND ((ER1.CurrencyCode IS NULL)
OR (ER1.CurrencyCode = '''+@CurrencyCode+'''))
GROUP BY
ER.CurrencyCode,
MB.MatterName) as A
ORDER BY [Total Budget] DESC
'
print(@SQL)
exec(@SQL)