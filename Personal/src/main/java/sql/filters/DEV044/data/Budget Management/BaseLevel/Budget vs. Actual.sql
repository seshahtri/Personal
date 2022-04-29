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
DECLARE @MatterownerId varchar(100);
DECLARE @MatterDynamicField1 varchar (1000);
DECLARE @MatterDynamicField2 varchar (1000);
DECLARE @MatterVendorDynamicField1 varchar (1000);
DECLARE @MatterVendorDynamicField2 varchar (1000);


SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;
SET @DateField=^InvoiceDate^;
SET @MatterName=^MatterName^;
SET @MatterNumber=^MatterNumber^;
SET @MatterStatus=^MatterStatus^;
SET @MatterOwnerName =^MatterOwner^;;
SET @PracticeAreaName =^PracticeArea^;
SET @BusinessUnitName=^BusinessUnit^;
SET @MatterDynamicField1=^DFMatterDynamicField1^;
SET @MatterDynamicField2=^DFMatterDynamicField2^;
SET @MatterVendorDynamicField1=^DFMatterVendorDynamicField1^;
SET @MatterVendorDynamicField2=^DFMatterVendorDynamicField2^;



--SET @CurrencyCode ='USD';
--SET @pDateStart='2017-01-01';
--SET @pDateEnd ='2017-12-31';
--SET @InvoiceStatus ='Paid'',''Processed';
--SET @MatterName='-1';
--SET @MatterStatus='-1';
--SET @PracticeAreaName ='-1';
--SET @BusinessUnitName='-1';
--SET @MatterDynamicField1='-1';
--SET @MatterDynamicField2='-1';
--SET @MatterNumber='-1';
--SET @MatterOwnerName='-1'
--SET @MatterName='Matter 3686999';
--SET @MatterStatus='Closed';
--SET @PracticeAreaName ='Employment & Labor';
--SET @BusinessUnitName='International';
--SET @MatterNumber='1155280';
--SET @MatterOwnerName='Halpert, Jim';



SET @PracticeAreaId = ISNULL((SELECT TOP 1 p.PracticeAreaId FROM PracticeAreaDim p WHERE p.PracticeAreaName = @PracticeAreaName),-1)
SET @BusinessUnitId = ISNULL((SELECT TOP 1 b.BusinessUnitId FROM BusinessUnitDim b where b.BusinessUnitName = @BusinessUnitName),-1)



SET @MatterownerId = ISNULL((SELECT TOP 1 m.MatterownerId FROM V_MatterBudgetDetails m WHERE m.MatterOwnerName = @MatterOwnerName),-1)




SET @SQL = '
exec as user = ''admin''



SELECT mb.BudgetPeriodName as [Budget Period Name],
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



AND (ISNULL('''+@MatterName +''', ''-1'') = ''-1'' OR [Matter Name]='''+ @MatterName +''')
AND (ISNULL('''+@MatterNumber +''', ''-1'') = ''-1'' OR [Matter Number]='''+ @MatterNumber +''')
AND (ISNULL('''+@MatterOwnerId +''', ''-1'') = ''-1'' OR [MatterownerId]='''+ @MatterOwnerId +''')



AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR
CASE WHEN mbi.MatterCloseDate IS NULL THEN ''Open''
WHEN mbi.MatterCloseDate > ''' + @pDateEnd + ''' THEN ''Open''
ELSE ''Closed'' END =''' + @MatterStatus + ''')



AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR mbi.MatterDF01=''' + @MatterDynamicField1 + ''')
AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR mbi.MatterDF02=''' + @MatterDynamicField2 + ''')



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



INNER JOIN [dbo].[PracticeAreaAndAllDescendants] [PracticeAreaAndAllDescendants] ON [PracticeAreaAndAllDescendants].[ChildPracticeAreaId]=[mb].[PracticeAreaId]



INNER JOIN (
SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''' + @PracticeAreaId +''', ''|'',-1,0)
) [RollupPracticeAreasWithSecurity] ON [RollupPracticeAreasWithSecurity].[RollupPracticeAreaId]=[PracticeAreaAndAllDescendants].[PracticeAreaId]



INNER JOIN [dbo].[BusinessUnitAndAllDescendants] [BusinessUnitAndAllDescendants] ON [BusinessUnitAndAllDescendants].[ChildBusinessUnitId]=[mb].[BusinessUnitId]



INNER JOIN (
SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] ('''+ @BusinessUnitId +''', ''|'',-1,0)
) [RollupBusinessUnitsWithSecurity] ON [RollupBusinessUnitsWithSecurity].[RollupBusinessUnitId]=[BusinessUnitAndAllDescendants].[BusinessUnitId]




WHERE
ili.InvoiceStatus IN ('''+@InvoiceStatus+''')
AND ili.InvoiceDate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
AND ili.CurrencyCode='''+@CurrencyCode+'''
AND mb.CurrencyCode='''+@CurrencyCode+'''



AND (ISNULL('''+@MatterName +''', ''-1'') = ''-1'' OR ili.MatterName='''+ @MatterName +''')
AND (ISNULL('''+@MatterNumber +''', ''-1'') = ''-1'' OR [Matter Number]='''+ @MatterNumber +''')
AND (ISNULL('''+@MatterOwnerId +''', ''-1'') = ''-1'' OR ili.MatterownerId='''+ @MatterOwnerId +''')



AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR
CASE WHEN mb.MatterCloseDate IS NULL THEN ''Open''
WHEN mb.MatterCloseDate > ''' + @pDateEnd + ''' THEN ''Open''
ELSE ''Closed'' END =''' + @MatterStatus + ''')



AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR mb.MatterDF01=''' + @MatterDynamicField1 + ''')
AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR mb.MatterDF02=''' + @MatterDynamicField2 + ''')




AND mb.BudgetPeriodId IS NOT NULL
GROUP BY
ili.BudgetPeriodId
) amt ON amt.BudgetPeriodId=mb.BudgetPeriodId
GROUP BY
mb.BudgetPeriodName,
mb.CurrencyCode,
amt.Amount
'
print(@SQL)
exec(@SQL)