--use Dev044_IOD_DATAMART;

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
DECLARE @MatterDynamicField1 varchar(100);
DECLARE @MatterDynamicField2 varchar(100);
DECLARE @MatterVendorDynamicField1 varchar(100);
DECLARE @MatterVendorDynamicField2 varchar(100);



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
exec as user=''admin''
SELECT [RollupPracticeAreasWithSecurity].[RollupPracticeAreaName] AS [GB Client], MAX([ExchangeRateDim1].[CurrencyCode]) AS [Currency Code],
round((SUM((CASE WHEN (NOT ([Invoice Status].[Name] IS NULL)) THEN ([InvoiceSummary].[amount] * [ExchangeRateDim].[ExchangeRate]) ELSE CAST(NULL AS FLOAT) END))),7) AS [Spend],
round(( SUM((CASE ISNULL([InvoiceSummary].[budgetrnk], 1) WHEN 1 THEN ([V_MatterBudgetDetails].[BudgetAmount] * [ExchangeRateDim1].[ExchangeRate]) ELSE 0 END))),7)AS [Budget Amount],
Round(( CAST(SUM((CASE WHEN (NOT ([Invoice Status].[Name] IS NULL)) THEN ([InvoiceSummary].[amount] * [ExchangeRateDim].[ExchangeRate]) ELSE CAST(NULL AS FLOAT) END))
/SUM((CASE ISNULL([InvoiceSummary].[budgetrnk], 1) WHEN 1 THEN ([V_MatterBudgetDetails].[BudgetAmount] * [ExchangeRateDim1].[ExchangeRate]) ELSE 0 END))
AS FLOAT) *100 ),4)as [Percent of Budget Consumed],
Round(( CASE WHEN
CAST(1-((SUM((CASE WHEN (NOT ([Invoice Status].[Name] IS NULL)) THEN ([InvoiceSummary].[amount] * [ExchangeRateDim].[ExchangeRate]) ELSE CAST(NULL AS FLOAT) END))
/SUM((CASE ISNULL([InvoiceSummary].[budgetrnk], 1) WHEN 1 THEN ([V_MatterBudgetDetails].[BudgetAmount] * [ExchangeRateDim1].[ExchangeRate]) ELSE 0 END))))AS FLOAT) *100 >0
THEN CAST(1-((SUM((CASE WHEN (NOT ([Invoice Status].[Name] IS NULL)) THEN ([InvoiceSummary].[amount] * [ExchangeRateDim].[ExchangeRate]) ELSE CAST(NULL AS FLOAT) END))
/SUM((CASE ISNULL([InvoiceSummary].[budgetrnk], 1) WHEN 1 THEN ([V_MatterBudgetDetails].[BudgetAmount] * [ExchangeRateDim1].[ExchangeRate]) ELSE 0 END))))AS FLOAT) *100
ELSE 0 END),4) as [Percent of Budget Remaining], round(( LEFT
( STR(CAST((SUM((CASE ISNULL([InvoiceSummary].[budgetrnk], 1) WHEN 1 THEN ([V_MatterBudgetDetails].[BudgetAmount] * [ExchangeRateDim1].[ExchangeRate]) ELSE 0 END)) -
SUM((CASE WHEN (NOT ([Invoice Status].[Name] IS NULL)) THEN ([InvoiceSummary].[amount] * [ExchangeRateDim].[ExchangeRate]) ELSE CAST(NULL AS FLOAT) END))
) AS FLOAT),22,22),22)),7) AS [Budget Remaining]FROM [dbo].[V_MatterBudgetDetails] [V_MatterBudgetDetails]

INNER JOIN [dbo].[BusinessUnitAndAllDescendants] [BusinessUnitAndAllDescendants] ON [BusinessUnitAndAllDescendants].[ChildBusinessUnitId]=[V_MatterBudgetDetails].[BusinessUnitId] 

INNER JOIN (
SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] ('''+ @BusinessUnitId +''', ''|'',-1,0)
) [RollupBusinessUnitsWithSecurity] ON  [RollupBusinessUnitsWithSecurity].[RollupBusinessUnitId]=[BusinessUnitAndAllDescendants].[BusinessUnitId]


LEFT JOIN (
select invoicestatus, exchangeratedate,amount ,matterid,
budgetperiodid , ROW_NUMBER() over(partition by matterid,budgetperiodid order by matterid,budgetperiodid) budgetrnk
from InvoiceSummary
) [InvoiceSummary] ON (([V_MatterBudgetDetails].[MatterId] = [InvoiceSummary].[matterid]) AND ([V_MatterBudgetDetails].[BudgetPeriodId] = [InvoiceSummary].[budgetperiodid]))

LEFT JOIN [dbo].[ExchangeRateDim] [ExchangeRateDim] ON ([InvoiceSummary].[exchangeratedate] = [ExchangeRateDim].[ExchangeRateDate])

LEFT JOIN (
SELECT [Name] FROM fn_SplitQuotedStrings(''''''' + @InvoiceStatus + ''''''')
) [Invoice Status] ON ([InvoiceSummary].[invoicestatus] = [Invoice Status].[Name])

LEFT JOIN [dbo].[ExchangeRateDim] [ExchangeRateDim1] ON ([V_MatterBudgetDetails].[BudgetExchangeRateDate] = [ExchangeRateDim1].[ExchangeRateDate])

INNER JOIN [dbo].[PracticeAreaAndAllDescendants] [PracticeAreaAndAllDescendants] ON [PracticeAreaAndAllDescendants].[ChildPracticeAreaId]=[V_MatterBudgetDetails].[PracticeAreaId] 

INNER JOIN (
SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''' + @PracticeAreaId +''', ''|'',-1,1)
) [RollupPracticeAreasWithSecurity] ON [RollupPracticeAreasWithSecurity].[RollupPracticeAreaId]=[PracticeAreaAndAllDescendants].[PracticeAreaId] 


WHERE (((CASE WHEN ([V_MatterBudgetDetails].[IsLOM] <> 0) THEN (CASE WHEN ((([V_MatterBudgetDetails].[MatterOpenDate] <= cast('''+@pDateEnd+'''as date)) AND (ISNULL([V_MatterBudgetDetails].[MatterCloseDate], (CASE
WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)) > cast('''+@pDateEnd+''' as date))) OR (([V_MatterBudgetDetails].[MatterOpenDate] <= cast('''+@pDateEnd+'''as date)) AND (DATEDIFF(month,ISNULL([V_MatterBudgetDetails].[MatterCloseDate], (CASE
WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)),cast('''+@pDateEnd+'''as date)) <= 12))) THEN 1 WHEN NOT ((([V_MatterBudgetDetails].[MatterOpenDate] <= cast('''+@pDateEnd+'''as date)) AND (ISNULL([V_MatterBudgetDetails].[MatterCloseDate], (CASE
WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)) > cast('''+@pDateEnd+'''as date))) OR (([V_MatterBudgetDetails].[MatterOpenDate] <= cast('''+@pDateEnd+'''as date)) AND (DATEDIFF(month,ISNULL([V_MatterBudgetDetails].[MatterCloseDate], (CASE
WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)),cast('''+@pDateEnd+'''as date)) <= 12))) THEN 0 ELSE NULL END) ELSE 1 END) <> 0) AND ((CASE WHEN ((([V_MatterBudgetDetails].[BudgetPeriodStartDate] >= cast('''+@pDateStart+'''as date)) AND ([V_MatterBudgetDetails].[BudgetPeriodEndDate] <= DATEADD(second,-1,DATEADD(day,1,CAST('''+@pDateEnd+''' as datetime))))) OR (([V_MatterBudgetDetails].[BudgetPeriodStartDate] <= '''+@pDateStart+''') AND (DATEADD(second,-1,DATEADD(day,1,CAST('''+@pDateEnd+''' as datetime))) <= [V_MatterBudgetDetails].[BudgetPeriodEndDate])) OR (([V_MatterBudgetDetails].[BudgetPeriodStartDate] <= '''+@pDateStart+''') AND ([V_MatterBudgetDetails].[BudgetPeriodEndDate] >= '''+@pDateStart+''')) OR (([V_MatterBudgetDetails].[BudgetPeriodStartDate] >= '''+@pDateStart+''') AND ([V_MatterBudgetDetails].[BudgetPeriodStartDate] <= DATEADD(second,-1,DATEADD(day,1,CAST('''+@pDateEnd+''' as datetime)))) AND ([V_MatterBudgetDetails].[BudgetPeriodEndDate] >= DATEADD(second,-1,DATEADD(day,1,CAST('''+@pDateEnd+''' as datetime)))))) THEN 1 ELSE 0 END) = 1) AND (([InvoiceSummary].[matterid] IS NULL)
OR ([ExchangeRateDim].[CurrencyCode] = ''' + @CurrencyCode + ''')) AND (([ExchangeRateDim1].[CurrencyCode] IS NULL) OR ([ExchangeRateDim1].[CurrencyCode] = ''' + @CurrencyCode + ''')))

AND (ISNULL('''+@MatterName +''', ''-1'') = ''-1'' OR MatterName='''+ @MatterName +''')
AND (ISNULL('''+@MatterNumber +''', ''-1'') = ''-1'' OR MatterNumber='''+ @MatterNumber +''')
AND (ISNULL(''' + @MatterOwnerName + ''', ''-1'') = ''-1'' OR MatterOwnerName=''' + @MatterOwnerName + ''')


AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR
CASE WHEN MatterCloseDate IS NULL THEN ''Open''
WHEN MatterCloseDate > ''' + @pDateEnd + ''' THEN ''Open''
ELSE ''Closed'' END =''' + @MatterStatus + ''')

AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR MatterDF01=''' + @MatterDynamicField1 + ''')
AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR MatterDF02=''' + @MatterDynamicField2 + ''')


GROUP BY
[RollupPracticeAreasWithSecurity].[RollupPracticeAreaName]
order by [Budget Amount] desc'
Print (@SQL)
EXEC(@SQL)

