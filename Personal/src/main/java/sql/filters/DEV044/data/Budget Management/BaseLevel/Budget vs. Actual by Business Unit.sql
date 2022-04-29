--use DEV044_IOD_DataMart;

DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @DateField varchar (MAX);
DECLARE @CurrencyCode varchar (MAX);
DECLARE @InvoiceStatus varchar (MAX);
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
--SET @InvoiceStatus=^InvoiceStatus^;
SET @CurrencyCode=^Currency^;
SET @DateField=^InvoiceDate^;
SET @MatterName=^MatterName^;
SET @MatterNumber=^MatterNumber^;
SET @MatterStatus=^MatterStatus^;
SET @MatterOwnerName=^MatterOwner^;
SET @VendorName=^VendorName^;
SET @VendorType=^VendorType^;
SET @PracticeAreaName=^PracticeArea^;
SET @BusinessUnitName=^BusinessUnit^;
SET @MatterDynamicField1=^DFMatterDynamicField1^;
SET @MatterDynamicField2=^DFMatterDynamicField2^;


--SET @CurrencyCode ='USD';
--SET @pDateStart='1/1/2017';
--SET @pDateEnd='12/31/2017';
SET @InvoiceStatus ='Paid'''',''''Processed';
----SET @MatterName='Matter 5452644';
--SET @MatterName='-1';
--SET @MatterStatus='-1';
------SET @MatterStatus='Open';
--SET @MatterOwnerName = '-1';
----SET @MatterOwnerName ='Katsopolis, Jesse';
--SET @VendorName='-1';
--SET @VendorType ='-1';
------SET @VendorName='Gagnon & Gagnon';
------SET @VendorType = 'Law Firm';
--SET @PracticeAreaName ='-1';
------SET @PracticeAreaName ='Employment and Labor';
--SET @BusinessUnitName='-1';
------SET @BusinessUnitName='International';
------SET @MatterNumber=^MatterNumber^;
------SET @MatterNumber='5452644';
--SET @MatterNumber='-1';
--SET @MatterDynamicField1='-1';
--SET @MatterDynamicField2='-1';
--SET @MatterVendorDynamicField1='-1';
--SET @MatterVendorDynamicField2='-1';

SET @PracticeAreaId = ISNULL((SELECT TOP 1 p.PracticeAreaId FROM PracticeAreaDim p WHERE p.PracticeAreaName = @PracticeAreaName),-1)
SET @BusinessUnitId = ISNULL((SELECT TOP 1 b.BusinessUnitId FROM BusinessUnitDim b where b.BusinessUnitName = @BusinessUnitName),-1)

SET @SQL='
exec as user = ''admin''

SELECT 
	 MB.BusinessUnitName AS [Business Unit],
  MIN(ER1.[CurrencyCode]) AS [Currency Code],
  SUM((CASE WHEN (NOT (INVS.[Name] IS NULL)) THEN (INV.amount * ER.ExchangeRate) ELSE NULL END)) AS [Spend],
  SUM((CASE ISNULL(INV.[budgetrnk], 1) WHEN 1 THEN (MB.BudgetAmount * ER1.ExchangeRate) ELSE 0 END)) AS [Total Budget],

     SUM((CASE WHEN (NOT (INVS.[Name] IS NULL)) THEN (INV.amount * ER.ExchangeRate) ELSE NULL END)) /
  SUM((CASE ISNULL(INV.[budgetrnk], 1) WHEN 1 THEN (MB.BudgetAmount * ER1.ExchangeRate) ELSE 0 END)) *100  AS [Percent of Budget Consumed],

  ABS(SUM((CASE WHEN (NOT (INVS.[Name] IS NULL)) THEN (INV.amount * ER.ExchangeRate) ELSE NULL END)) 
   -  SUM((CASE ISNULL(INV.budgetrnk, 1) WHEN 1 THEN (MB.BudgetAmount * ER1.ExchangeRate) ELSE 0 END))) 
 / NULLIF( SUM((CASE ISNULL(INV.budgetrnk, 1) WHEN 1 THEN (MB.BudgetAmount * ER1.ExchangeRate) ELSE 0 END)),0) *100  as [Percent of Budget Remaining],

 ABS(SUM((CASE WHEN (NOT (INVS.[Name] IS NULL)) THEN (INV.amount * ER.ExchangeRate) ELSE NULL END)) 
  -  SUM((CASE ISNULL(INV.budgetrnk, 1) WHEN 1 THEN (MB.BudgetAmount * ER1.ExchangeRate) ELSE 0 END)))    AS [Budget Remaining] 
 
FROM 

	V_MatterBudgetDetails MB
JOIN BusinessUnitAndAllDescendants BAD ON MB.BusinessUnitId = BAD.ChildBusinessUnitId
JOIN (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
  FROM fn_GetRollupBusinessUnitsWithSecurity ('''+ @BusinessUnitId +''', ''|'',-1,0)) BUS ON BAD.BusinessUnitId = BUS.RollupBusinessUnitId
LEFT JOIN (
  SELECT invoicestatus, exchangeratedate,amount ,matterid,
     budgetperiodid , ROW_NUMBER() OVER(PARTITION BY matterid,budgetperiodid ORDER BY matterid,budgetperiodid) budgetrnk
    FROM InvoiceSummary
	where InvoiceDate between '''+@pDateStart+''' and '''+@pDateEnd+'''
) INV ON MB.MatterId = INV.matterid AND MB.BudgetPeriodId = INV.budgetperiodid
LEFT JOIN ExchangeRateDim ER ON INV.exchangeratedate = ER.ExchangeRateDate
LEFT JOIN (SELECT [Name] FROM fn_SplitQuotedStrings(''''''' + @InvoiceStatus + ''''''')
) INVS ON INV.invoicestatus = INVS.[Name]
LEFT JOIN ExchangeRateDim ER1 ON MB.BudgetExchangeRateDate = ER1.ExchangeRateDate
JOIN PracticeAreaAndAllDescendants PAD ON MB.PracticeAreaId = PAD.ChildPracticeAreaId
JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
  FROM fn_GetRollupPracticeAreasWithSecurity2 (''' + @PracticeAreaId +''', ''|'',-1,0)) PAS ON PAD.PracticeAreaId = PAS.RollupPracticeAreaId
  
  
  
WHERE 1= 1

/*(((CASE WHEN (MB.IsLOM <> 0) THEN (CASE WHEN (((MB.MatterOpenDate <= (SELECT CAST(eomonth(GETDATE()) AS datetime))) 
AND (ISNULL(MB.MatterCloseDate, (CASE
	WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
	ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)) > (SELECT CAST(eomonth(GETDATE()) AS datetime)))) 
	OR ((MB.MatterOpenDate <= (SELECT CAST(eomonth(GETDATE()) AS datetime))) 
	AND (DATEDIFF(month,ISNULL(MB.MatterCloseDate, (CASE
	WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
	ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)),(SELECT CAST(eomonth(GETDATE()) AS datetime))) <= 12))) 
	THEN 1 WHEN NOT (((MB.MatterOpenDate <= (SELECT CAST(eomonth(GETDATE()) AS datetime))) 
	AND (ISNULL(MB.MatterCloseDate, (CASE
	WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
	ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)) > (SELECT CAST(eomonth(GETDATE()) AS datetime)))) 
	OR ((MB.MatterOpenDate <= (SELECT CAST(eomonth(GETDATE()) AS datetime))) 
	AND (DATEDIFF(month,ISNULL(MB.MatterCloseDate, (CASE
	WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
	ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)),(SELECT CAST(eomonth(GETDATE()) AS datetime))) <= 12))) 
	THEN 0 ELSE NULL END) ELSE 1 END) <> 0) AND ((CASE WHEN (((MB.BudgetPeriodStartDate >= (select DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-11, 0) )) 
	AND (MB.BudgetPeriodEndDate <= DATEADD(second,-1,DATEADD(day,1,CAST((SELECT CAST(eomonth(GETDATE()) AS datetime)) as datetime))))) 
	OR ((MB.BudgetPeriodStartDate <= (select DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-11, 0) )) 
	AND (DATEADD(second,-1,DATEADD(day,1,CAST((SELECT CAST(eomonth(GETDATE()) AS datetime)) as datetime))) <= MB.BudgetPeriodEndDate)) 
	OR ((MB.BudgetPeriodStartDate <= (select DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-11, 0) )) 
	AND (MB.BudgetPeriodEndDate >= (select DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-11, 0) ))) 
	OR ((MB.BudgetPeriodStartDate >= (select DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-11, 0) )) 
	AND (MB.BudgetPeriodStartDate <= DATEADD(second,-1,DATEADD(day,1,CAST((SELECT CAST(eomonth(GETDATE()) AS datetime)) as datetime)))) 
	AND (MB.BudgetPeriodEndDate >= DATEADD(second,-1,DATEADD(day,1,CAST((SELECT CAST(eomonth(GETDATE()) AS datetime)) as datetime)))))) THEN 1 ELSE 0 END) = 1) */
	AND ((INV.[matterid] IS NULL) 
	OR (ER.CurrencyCode = '''+@CurrencyCode+''')) 
	AND ((ER1.CurrencyCode IS NULL) 
	OR (ER1.CurrencyCode = '''+@CurrencyCode+'''))
	and (ISNULL(''' + @MatterName + ''', ''-1'') = ''-1'' OR MB.MatterName=''' + @MatterName + ''')
	AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR
	CASE WHEN MB.MatterCloseDate IS NULL THEN ''Open''
	WHEN MB.MatterCloseDate > ''' + @pDateEnd + ''' THEN ''Open''
	ELSE ''Closed'' END =''' + @MatterStatus + ''')
	AND (ISNULL(''' + @MatterOwnerName + ''', ''-1'') = ''-1'' OR MB.MatterOwnerName=''' + @MatterOwnerName + ''')
	AND (ISNULL('''+@MatterNumber +''', ''-1'') = ''-1'' OR mb.MatterNumber='''+ @MatterNumber +''')	
	
	

	AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR mb.MatterDF01=''' + @MatterDynamicField1 + ''')
	AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR mb.MatterDF02=''' + @MatterDynamicField2 + ''')
	
GROUP BY 
	MB.BusinessUnitName
ORDER BY Spend DESC
'
print(@SQL)
exec(@SQL)