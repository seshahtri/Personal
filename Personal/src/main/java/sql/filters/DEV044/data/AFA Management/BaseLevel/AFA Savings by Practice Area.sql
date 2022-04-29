--USE DEV044_IOD_DataMart;

DECLARE @pDateStart varchar (MAX);
DECLARE @pDateEnd varchar (MAX);
DECLARE @DateField varchar (MAX);
DECLARE @InvoiceStatus nvarchar (MAX);
DECLARE @CurrencyCode varchar (MAX);
DECLARE @SQL VARCHAR(MAX);
DECLARE @MatterName varchar (MAX);
DECLARE @MatterNumber varchar (MAX);
DECLARE @MatterStatus varchar (MAX);
DECLARE @MatterOwnerName varchar (MAX);
DECLARE @VendorName varchar (MAX);
DECLARE @VendorType varchar (MAX);
DECLARE @PracticeAreaName varchar (MAX);
DECLARE @PracticeAreaId varchar(MAX);
DECLARE @BusinessUnitName varchar (MAX);
DECLARE @BusinessUnitId varchar(MAX);
DECLARE @MatterDynamicField1 varchar(MAX);
DECLARE @MatterDynamicField2 varchar(MAX);
DECLARE @MatterVendorDynamicField1 varchar(MAX);
DECLARE @MatterVendorDynamicField2 varchar(MAX);


SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;
SET @DateField=^invoicedate^;
SET @MatterName=^MatterName^;
SET @MatterNumber=^MatterNumber^;
SET @MatterStatus=^MatterStatus^;
SET @MatterOwnerName =^MatterOwner^;;
SET @VendorName=^VendorName^;
SET @VendorType =^VendorType^;
SET @PracticeAreaName =^PracticeArea^;
SET @BusinessUnitName=^BusinessUnit^;
SET @MatterDynamicField1=^DFMatterDynamicField1^;
SET @MatterDynamicField2=^DFMatterDynamicField2^;
SET @MatterVendorDynamicField1=^DFMatterVendorDynamicField1^;
SET @MatterVendorDynamicField2=^DFMatterVendorDynamicField2^;



--SET @pDateStart= '1/1/2017';
--SET @pDateEnd= '12/31/2017';
--SET @InvoiceStatus= 'Paid'',''Processed';
--SET @CurrencyCode= 'USD';
--SET @DateField='invoicedate';
--SET @MatterName='-1';--'Matter 3686999';
--SET @MatterNumber='-1';
--SET @MatterStatus='-1';
--SET @MatterOwnerName ='-1';--'Katsopolis, Jesse';
--SET @VendorName='-1';--'Caron & Landry LLP';
--SET @VendorType ='-1';--'Law Firm';
--SET @PracticeAreaName ='-1'; -- --Employment and Labor --Consumer Finance --Commercial Transactions and Agreements
--SET @BusinessUnitName='-1';--'NorthEast';--'NorthEast';
--SET @MatterDynamicField1='-1';--'Unspecified';
--SET @MatterDynamicField2='-1';
--SET @MatterVendorDynamicField1='-1';--'Unspecified';
--SET @MatterVendorDynamicField2='-1';



SET @PracticeAreaId = ISNULL((SELECT TOP 1 p.PracticeAreaId FROM PracticeAreaDim p WHERE p.PracticeAreaName = @PracticeAreaName),-1)
SET @BusinessUnitId = ISNULL((SELECT TOP 1 b.BusinessUnitId FROM BusinessUnitDim b where b.BusinessUnitName = @BusinessUnitName),-1)


SET @SQL = '
				exec as user = ''admin''
	--AFA Savings by Practice Area-- 
	SELECT 
	  DISTINCT af.practiceareaname as PracticeArea, 
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
	  RIGHT JOIN practiceareadim p on p.practiceareaid = ils.practiceareaid
	  RIGHT join practiceareadim p2 on p2.level = ''2'' and P.[path] like p2.[Path] + ''%''
	  RIGHT JOIN (
		SELECT 
		  p2.practiceareaname,p2.practiceareaid,
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
		  JOIN practiceareadim p on p.practiceareaid = ils.practiceareaid
		  inner join practiceareadim p2 on p2.level = ''2'' and P.[path] like p2.[Path] + ''%''
		  JOIN BusinessUnitAndAllDescendants BAD ON ils.BusinessUnitId = BAD.ChildBusinessUnitId
JOIN (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
  FROM fn_GetRollupBusinessUnitsWithSecurity (''' + @BusinessUnitId + ''', ''|'',-1,0)) BUS ON BAD.BusinessUnitId = BUS.RollupBusinessUnitId
    JOIN PracticeAreaAndAllDescendants PAD ON ils.PracticeAreaId = PAD.ChildPracticeAreaId
	JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
  FROM fn_GetRollupPracticeAreasWithSecurity2 (''' + @PracticeAreaId + ''', ''|'',-1,0)) PAS ON PAD.PracticeAreaId = PAS.RollupPracticeAreaId
		WHERE 
	  ils.invoicestatus IN ('''+@InvoiceStatus+''')
	  AND ils.invoicestatusdate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
	  AND ils.CurrencyCode = '''+@CurrencyCode+'''
	  AND ils.afaruletypes IS NOT NULL 
	  AND ils.grossfeeamount IS NOT NULL
		  --AND vendorid = 61
	AND (ISNULL(''' + @MatterName + ''', ''-1'') = ''-1'' OR MatterName=''' + @MatterName + ''')
AND (ISNULL(''' + @MatterNumber + ''', ''-1'') = ''-1'' OR MatterNumber=''' + @MatterNumber + ''')
AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR
CASE WHEN MatterCloseDate IS NULL THEN ''Open''
WHEN MatterCloseDate > ''' + @pDateEnd + ''' THEN ''Open''
ELSE ''Closed'' END =''' + @MatterStatus + ''')
--AND (ISNULL(''' + @MatterOwnerName + ''', ''-1'') = ''-1'' OR MatterOwnerName=''' + @MatterOwnerName + ''')
AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR MatterDF01=''' + @MatterDynamicField1 + ''')
AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR MatterDF02=''' + @MatterDynamicField2 + ''')
AND (ISNULL(''' + @MatterVendorDynamicField1 + ''', ''-1'') = ''-1'' OR MatterVendorDF01=''' + @MatterVendorDynamicField1 + ''')
AND (ISNULL(''' + @MatterVendorDynamicField2 + ''', ''-1'') = ''-1'' OR MatterVendorDF02=''' + @MatterVendorDynamicField2 + ''')
--AND (ISNULL(''' + @VendorName + ''', ''-1'') = ''-1'' OR VendorName=''' + @VendorName + ''')
AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR VendorType=''' + @VendorType + ''')
		GROUP BY 
		 p2.practiceareaname,p2.practiceareaid
	  ) AS af ON 1=1 --af.practiceareaid = ils.practiceareaid 
	  JOIN BusinessUnitAndAllDescendants BAD ON ils.BusinessUnitId = BAD.ChildBusinessUnitId
JOIN (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
  FROM fn_GetRollupBusinessUnitsWithSecurity (''' + @BusinessUnitId + ''', ''|'',-1,0)) BUS ON BAD.BusinessUnitId = BUS.RollupBusinessUnitId
    JOIN PracticeAreaAndAllDescendants PAD ON ils.PracticeAreaId = PAD.ChildPracticeAreaId
	JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
  FROM fn_GetRollupPracticeAreasWithSecurity2 (''' + @PracticeAreaId + ''', ''|'',-1,0)) PAS ON PAD.PracticeAreaId = PAS.RollupPracticeAreaId
	WHERE 
	  ils.invoicestatus IN ('''+@InvoiceStatus+''')
	  AND ils.invoicestatusdate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
	  AND ils.CurrencyCode = '''+@CurrencyCode+'''
	  AND ils.afaruletypes IS NOT NULL 
	  AND ils.grossfeeamount IS NOT NULL
	  --AND vendorid = 61
	  AND (ISNULL(''' + @MatterName + ''', ''-1'') = ''-1'' OR MatterName=''' + @MatterName + ''')
AND (ISNULL(''' + @MatterNumber + ''', ''-1'') = ''-1'' OR MatterNumber=''' + @MatterNumber + ''')
AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR
CASE WHEN MatterCloseDate IS NULL THEN ''Open''
WHEN MatterCloseDate > ''' + @pDateEnd + ''' THEN ''Open''
ELSE ''Closed'' END =''' + @MatterStatus + ''')
--AND (ISNULL(''' + @MatterOwnerName + ''', ''-1'') = ''-1'' OR MatterOwnerName=''' + @MatterOwnerName + ''')
AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR MatterDF01=''' + @MatterDynamicField1 + ''')
AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR MatterDF02=''' + @MatterDynamicField2 + ''')
AND (ISNULL(''' + @MatterVendorDynamicField1 + ''', ''-1'') = ''-1'' OR MatterVendorDF01=''' + @MatterVendorDynamicField1 + ''')
AND (ISNULL(''' + @MatterVendorDynamicField2 + ''', ''-1'') = ''-1'' OR MatterVendorDF02=''' + @MatterVendorDynamicField2 + ''')
--AND (ISNULL(''' + @VendorName + ''', ''-1'') = ''-1'' OR VendorName=''' + @VendorName + ''')
AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR VendorType=''' + @VendorType + ''')

	ORDER BY 
	  [AFA Savings] DESC


				'
PRINT(@SQL)
EXEC(@SQL)

