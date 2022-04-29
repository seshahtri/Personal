use DEV044_IOD_DataMart;

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
DECLARE @MatterownerId varchar (MAX);

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
--SET @DateField=REPLACE('Invoice Date',' ','');
----SET @MatterName='Matter 5452644';
--SET @MatterName='-1';
--SET @MatterStatus='-1';
----SET @MatterStatus='Open';
--SET @MatterOwnerName = '-1';
----SET @MatterOwnerName ='Katsopolis, Jesse';
--SET @VendorName='-1';
--SET @VendorType ='-1';
----SET @VendorName='Gagnon & Gagnon';
----SET @VendorType = 'Law Firm';
--SET @PracticeAreaName ='-1';
----SET @PracticeAreaName ='Employment and Labor';
--SET @BusinessUnitName='-1';
----SET @BusinessUnitName='International';
--SET @MatterNumber='-1';
----SET @MatterNumber='5452644';
--SET @MatterDynamicField1='-1';
--SET @MatterDynamicField2='-1';
--SET @MatterVendorDynamicField1='-1';
--SET @MatterVendorDynamicField2='-1';

SET @PracticeAreaId = ISNULL((SELECT TOP 1 p.PracticeAreaId FROM PracticeAreaDim p WHERE p.PracticeAreaName = @PracticeAreaName),-1)
SET @BusinessUnitId = ISNULL((SELECT TOP 1 b.BusinessUnitId FROM BusinessUnitDim b where b.BusinessUnitName = @BusinessUnitName),-1)
SET @MatterownerId = ISNULL((SELECT TOP 1 d.timekeeperid FROM timekeeperdim d WHERE d.fullname = @MatterOwnerName),-1)


SET @SQL='
execute  as user= ''admin''

SELECT RollupPracticeAreasWithSecurity.RollupPracticeAreaName AS PracticeAreaName,  
  min(ExchangeRateDim.CurrencyCode) AS [Currency Code],
  COUNT(DISTINCT MSS.MatterId) AS Matters,
  SUM((CASE WHEN ( MSS.InvoiceStatus in( '''+@InvoiceStatus+''') ) AND (MSS.InvoiceDate <= '''+@pDateEnd+''') THEN (MSS.Amount * ISNULL(ExchangeRateDim.ExchangeRate, 1)) ELSE CAST(NULL AS FLOAT) END)) AS Spend,
  SUM((CASE WHEN ( MSS.InvoiceStatus in( '''+@InvoiceStatus+''') AND (MSS.InvoiceDate <= '''+@pDateEnd+''')) THEN MSS.Hours ELSE CAST(NULL AS FLOAT) END)) AS [Hours]
  
FROM [dbo].V_MatterSpendSummary MSS

  INNER JOIN [dbo].[BusinessUnitAndAllDescendants] [BusinessUnitAndAllDescendants] ON (MSS.[BusinessUnitId] = [BusinessUnitAndAllDescendants].[ChildBusinessUnitId])
  INNER JOIN (
  SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
  FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''' + @BusinessUnitId + ''', ''|'',-1,0)
) [RollupBusinessUnitsWithSecurity] ON ([BusinessUnitAndAllDescendants].[BusinessUnitId] = [RollupBusinessUnitsWithSecurity].[RollupBusinessUnitId])

 LEFT JOIN [dbo].[ExchangeRateDim] [ExchangeRateDim] ON (MSS.[ExchangeRateDate] = [ExchangeRateDim].[ExchangeRateDate])

  INNER JOIN [dbo].[PracticeAreaAndAllDescendants] [PracticeAreaAndAllDescendants] ON (MSS.[PracticeAreaId] = [PracticeAreaAndAllDescendants].[ChildPracticeAreaId])
  INNER JOIN (
  SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
  FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''' + @PracticeAreaId+''', ''|'',-1,1)
) [RollupPracticeAreasWithSecurity] ON ([PracticeAreaAndAllDescendants].[PracticeAreaId] = [RollupPracticeAreasWithSecurity].[RollupPracticeAreaId])
WHERE 
((((CASE WHEN ([ExchangeRateDim].[CurrencyCode] = '''+@CurrencyCode+''') THEN 1 WHEN NOT ([ExchangeRateDim].[CurrencyCode] = '''+@CurrencyCode+''') THEN 0 ELSE NULL END) IS NULL) OR ([ExchangeRateDim].[CurrencyCode] = '''+@CurrencyCode+''')) 
AND ((CASE WHEN ((CASE WHEN ((MSS.[MatterOpenDate] <= '''+@pDateEnd+''') AND (ISNULL(MSS.[MatterCloseDate], (CASE  WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)) > '''+@pDateEnd+''')) 
THEN ''Open'' WHEN (MSS.[MatterOpenDate] <= '''+@pDateEnd+''') 
THEN ''Closed'' ELSE CAST(NULL AS NVARCHAR) END) = ''Open'') THEN 1 ELSE 0 END) = 1))

and (ISNULL(''' + @MatterName + ''', ''-1'') = ''-1'' OR MSS.MatterName=''' + @MatterName + ''')
AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR
CASE WHEN MSS.MatterCloseDate IS NULL THEN ''Open''
WHEN MSS.MatterCloseDate > ''' + @pDateEnd + ''' THEN ''Open''
ELSE ''Closed'' END =''' + @MatterStatus + ''')
AND (ISNULL(''' + @MatterOwnerId + ''', ''-1'') = ''-1'' OR MSS.MatterownerId=''' + @MatterOwnerId + ''')
AND (ISNULL('''+@MatterNumber +''', ''-1'') = ''-1'' OR MSS.MatterNumber='''+ @MatterNumber +''')
--AND (ISNULL(''' + @VendorName + ''', ''-1'') = ''-1'' OR MSS.VendorName=''' + @VendorName + ''')
--AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR MSS.VendorType=''' + @VendorType + ''')

AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR MatterDF01=''' + @MatterDynamicField1 + ''')
AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR MatterDF02=''' + @MatterDynamicField1 + ''')
--AND (ISNULL(''' + @MatterVendorDynamicField1 + ''', ''-1'') = ''-1'' OR MatterVendorDF01=''' + @MatterVendorDynamicField1 + ''')
--AND (ISNULL(''' + @MatterVendorDynamicField2 + ''', ''-1'') = ''-1'' OR MatterVendorDF02=''' + @MatterVendorDynamicField2 + ''')



GROUP BY [RollupPracticeAreasWithSecurity].[RollupPracticeAreaName]--, ExchangeRateDim.CurrencyCode
order by COUNT_BIG(DISTINCT MSS.MatterId) desc, PracticeAreaName desc
'
print(@SQL)
exec(@SQL)