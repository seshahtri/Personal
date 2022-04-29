--use DEV044_IOD_DataMart;

DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @CurrencyCode varchar (MAX);
DECLARE @InvoiceStatus varchar (MAX);
DECLARE @DateField varchar (MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @MatterName varchar (1000);
DECLARE @MatterStatus varchar (1000);
DECLARE @MatterOwnerName varchar (1000);
DECLARE @MatterNumber varchar (1000);
DECLARE @VendorName varchar (1000);
DECLARE @VendorType varchar (1000);
DECLARE @PracticeAreaName varchar (1000);
DECLARE @PracticeAreaId varchar(1000);
DECLARE @BusinessUnitName varchar (1000);
DECLARE @BusinessUnitId varchar(100);
DECLARE @MatterDynamicField1 varchar(100);
DECLARE @MatterDynamicField2 varchar(100);
DECLARE @MatterVendorDynamicField1 varchar(100);
DECLARE @MatterVendorDynamicField2 varchar(100);

SET @pDateStart=^StartDate^;
SET @pDateEnd=^EndDate^;
SET @InvoiceStatus=^InvoiceStatus^;
SET @CurrencyCode=^Currency^;
SET @DateField=^InvoiceDate^;
SET @MatterName=^MatterName^;
SET @MatterNumber=^MatterNumber^;
SET @MatterStatus=^MatterStatus^;
SET @MatterOwnerName=^MatterOwner^;;
SET @VendorName=^VendorName^;
SET @VendorType=^VendorType^;
SET @PracticeAreaName=^PracticeArea^;
SET @BusinessUnitName=^BusinessUnit^;
SET @MatterDynamicField1=^DFMatterDynamicField1^;
SET @MatterDynamicField2=^DFMatterDynamicField2^;
SET @MatterVendorDynamicField1=^DFMatterVendorDynamicField1^;
SET @MatterVendorDynamicField2=^DFMatterVendorDynamicField2^;


--SET @CurrencyCode ='USD';
--SET @pDateStart='1/1/2017';
--SET @pDateEnd='12/31/2017';
--SET @InvoiceStatus ='Paid'',''Processed';
--SET @MatterName='Matter 5452644';
--SET @MatterName='-1';
--SET @MatterStatus='-1';
--SET @MatterStatus='Open';
--SET @MatterOwnerName = '-1';
--SET @MatterOwnerName ='Katsopolis, Jesse';
--SET @VendorName='-1';
--SET @VendorType ='-1';
--SET @VendorName='Gagnon & Gagnon';
--SET @VendorType = 'Law Firm';
--SET @PracticeAreaName ='-1';
--SET @PracticeAreaName ='Employment and Labor';
--SET @BusinessUnitName='-1';
--SET @BusinessUnitName='International';
--SET @MatterNumber='-1';
--SET @MatterNumber='5452644';
--SET @MatterDynamicField1='-1';
--SET @MatterDynamicField2='-1';
--SET @MatterVendorDynamicField1='-1';
--SET @MatterVendorDynamicField2='-1';


SET @PracticeAreaId = ISNULL((SELECT TOP 1 p.PracticeAreaId FROM PracticeAreaDim p WHERE p.PracticeAreaName = @PracticeAreaName),-1)
SET @BusinessUnitId = ISNULL((SELECT TOP 1 b.BusinessUnitId FROM BusinessUnitDim b where b.BusinessUnitName = @BusinessUnitName),-1)

SET @SQL='
execute as user =''admin''
Select
v.VendorName as [Vendor Name],
--vb.city as [City],
--vb.StateProvCode as [State],
ed.CurrencyCode as [Currency Code],
CAST(SUM(amt.Amount) AS FLOAT) as [Spend],
CAST(SUM(vb.BudgetAmount) AS FLOAT) as [Total Budget],
CAST(SUM(amt.Amount)/SUM(vb.BudgetAmount) *100 AS FLOAT) as [Percent of Budget Consumed],
CASE WHEN CAST(1-((SUM(amt.Amount)/SUM(vb.BudgetAmount))) AS FLOAT) *100 >0 THEN CAST(1-((SUM(amt.Amount)/SUM(vb.BudgetAmount))) AS FLOAT)* 100 ELSE 100 END as [Percent of Budget Remaining],
CAST((SUM(vb.BudgetAmount) - SUM(amt.Amount)) AS FLOAT) AS [Budget Remaining]

FROM V_VendorBudgetDetails vb
join ExchangeRateDim ed on ed.ExchangeRateDate = vb.BudgetExchangeRateDate
INNER JOIN [dbo].[BusinessUnitAndAllDescendants] [BusinessUnitAndAllDescendants] ON (vb.[BusinessUnitId] = [BusinessUnitAndAllDescendants].[ChildBusinessUnitId])
INNER JOIN (
SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] ('''+ @BusinessUnitId +''', ''|'',-1,0)
) [RollupBusinessUnitsWithSecurity] ON ([BusinessUnitAndAllDescendants].[BusinessUnitId] = [RollupBusinessUnitsWithSecurity].[RollupBusinessUnitId])
INNER JOIN [dbo].[PracticeAreaAndAllDescendants] [PracticeAreaAndAllDescendants] ON (vb.[PracticeAreaId] = [PracticeAreaAndAllDescendants].[ChildPracticeAreaId])
INNER JOIN (
SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''' + @PracticeAreaId +''', ''|'',-1,0)
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
left join matterdim MD on vb.MatterId = MD.MatterId

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
THEN (CASE WHEN (((vb.[MatterOpenDate] <= cast('''+@pDateEnd+'''as date))
AND (ISNULL(vb.[MatterCloseDate], (CASE
WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)) > cast('''+@pDateEnd+'''as date))) OR ((vb.[MatterOpenDate] <= cast('''+@pDateEnd+'''as date)) AND (DATEDIFF(month,ISNULL(vb.[MatterCloseDate], (CASE
WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)),cast('''+@pDateEnd+'''as date)) <= 12))) THEN 1 WHEN NOT (((vb.[MatterOpenDate] <= cast('''+@pDateEnd+'''as date)) AND (ISNULL(vb.[MatterCloseDate], (CASE
WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)) > cast('''+@pDateEnd+'''as date))) OR ((vb.[MatterOpenDate] <= cast('''+@pDateEnd+'''as date)) AND (DATEDIFF(month,ISNULL(vb.[MatterCloseDate], (CASE
WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)),cast('''+@pDateEnd+'''as date)) <= 12))) THEN 0 ELSE NULL END) ELSE 1 END) <> 0)
and (ISNULL(''' + @MatterName + ''', ''-1'') = ''-1'' OR MD.MatterName=''' + @MatterName + ''')
AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR
CASE WHEN md.MatterCloseDate IS NULL THEN ''Open''
WHEN md.MatterCloseDate > ''' + @pDateEnd + ''' THEN ''Open''
ELSE ''Closed'' END =''' + @MatterStatus + ''')
AND (ISNULL(''' + @MatterOwnerName + ''', ''-1'') = ''-1'' OR vb.MatterOwnerName=''' + @MatterOwnerName + ''')
AND (ISNULL('''+@MatterNumber +''', ''-1'') = ''-1'' OR vb.MatterNumber='''+ @MatterNumber +''')
AND (ISNULL(''' + @VendorName + ''', ''-1'') = ''-1'' OR vb.VendorName=''' + @VendorName + ''')
AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR vb.VendorType=''' + @VendorType + ''')

AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR MatterDF01=''' + @MatterDynamicField1 + ''')
AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR MatterDF02=''' + @MatterDynamicField1 + ''')
AND (ISNULL(''' + @MatterVendorDynamicField1 + ''', ''-1'') = ''-1'' OR MatterVendorDF01=''' + @MatterVendorDynamicField1 + ''')
AND (ISNULL(''' + @MatterVendorDynamicField2 + ''', ''-1'') = ''-1'' OR MatterVendorDF02=''' + @MatterVendorDynamicField2 + ''')

GROUP BY
v.vendorid,
v.VendorName,
ed.CurrencyCode
ORDER BY SUM(amt.Amount) DESC'
Print (@SQL)
EXEC(@SQL)