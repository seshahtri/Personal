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
DECLARE @MatterOwnerId varchar(MAX);
DECLARE @VendorName varchar (MAX);
DECLARE @VendorId varchar(MAX);
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
SET @DateField=^InvoiceDate^;
SET @MatterName=^MatterName^;
SET @MatterNumber=^MatterNumber^;
SET @MatterStatus=^MatterStatus^;
SET @MatterOwnerName =^MatterOwner^;;
SET  @VendorName=^VendorName^;
SET  @VendorType =^VendorType^;
SET  @PracticeAreaName =^PracticeArea^;
SET  @BusinessUnitName=^BusinessUnit^;
SET @MatterDynamicField1=^DFMatterDynamicField1^;
SET @MatterDynamicField2=^DFMatterDynamicField2^;
SET @MatterVendorDynamicField1=^DFMatterVendorDynamicField1^;
SET @MatterVendorDynamicField2=^DFMatterVendorDynamicField2^;




--SET @pDateStart= '1/1/2017';
--SET @pDateEnd= '12/31/2017';
--SET @InvoiceStatus= 'Paid'',''Processed';
--SET @CurrencyCode= 'USD';
--SET @DateField=REPLACE('Invoice Date',' ','');
--SET @MatterName='-1';--'Matter 1249426';
--SET @MatterNumber='-1';
--SET @MatterStatus='-1';
--SET @MatterOwnerName ='-1';--'Clavin, Cliff ';
--SET @VendorName='-1';--'Caron & Landry LLP';
--SET @VendorType ='-1';--'Law Firm';
--SET @PracticeAreaName ='-1';--'Corporate';
--SET @BusinessUnitName='-1';--'NorthEast';--'NorthEast';
--SET @MatterDynamicField1='-1';--'Unspecified';
--SET @MatterDynamicField2='-1';
--SET @MatterVendorDynamicField1='-1';--'Unspecified';
--SET @MatterVendorDynamicField2='-1';

SET @PracticeAreaId = ISNULL((SELECT TOP 1 p.PracticeAreaId FROM PracticeAreaDim p WHERE p.PracticeAreaName = @PracticeAreaName),-1)
SET @BusinessUnitId = ISNULL((SELECT TOP 1 b.BusinessUnitId FROM BusinessUnitDim b where b.BusinessUnitName = @BusinessUnitName),-1)
SET @MatterOwnerId= ISNULL((Select Top 1 ili.MatterOwnerId from V_InvoiceTimekeeperSummary ili where ili.MatterOwnerName=@MatterOwnerName),-1)
SET @VendorId= ISNULL((Select Top 1 ili.VendorId from V_InvoiceTimekeeperSummary ili where ili.VendorName=@VendorName),-1)

SET @SQL = '
				exec as user = ''admin''
SELECT 
  DISTINCT ils.afaruletypes AS [AFA Type], 
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
  
	   INNER JOIN (
					Select * from PracticeAreaAndAllDescendants pad 
					INNER JOIN (
					SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
					FROM fn_GetRollupPracticeAreasWithSecurity2 (''' + @PracticeAreaId + ''', ''|'',-1,0)
					) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
					)A ON ils.PracticeAreaId = A.ChildPracticeAreaId
		Inner JOIN (
					Select * from BusinessUnitAndAllDescendants bud 
					INNER JOIN (
					SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
					FROM fn_GetRollupBusinessUnitsWithSecurity (''' + @BusinessUnitId + ''', ''|'',-1,0)
					) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
					)B  ON ils.BusinessUnitId = B.ChildBusinessUnitId

  JOIN (
    SELECT 
      ils.afaruletypes, 
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

	  
	   INNER JOIN (
					Select * from PracticeAreaAndAllDescendants pad 
					INNER JOIN (
					SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
					FROM fn_GetRollupPracticeAreasWithSecurity2 (''' + @PracticeAreaId + ''', ''|'',-1,0)
					) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
					)A ON ils.PracticeAreaId = A.ChildPracticeAreaId
		Inner JOIN (
					Select * from BusinessUnitAndAllDescendants bud 
					INNER JOIN (
					SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
					FROM fn_GetRollupBusinessUnitsWithSecurity (''' + @BusinessUnitId + ''', ''|'',-1,0)
					) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
					)B  ON ils.BusinessUnitId = B.ChildBusinessUnitId

    WHERE 
      ils.invoicestatus IN ('''+@InvoiceStatus+''')
      AND ils.invoicestatusdate BETWEEN  '''+@pDateStart+''' AND '''+@pDateEnd+'''
      AND ils.currencyid = 1 
      AND ils.afaruletypes IS NOT NULL 
      AND ils.grossfeeamount IS NOT NULL 
						AND (ISNULL(''' + @MatterName + ''', ''-1'') = ''-1'' OR ils.MatterName=''' + @MatterName + ''')
						AND (ISNULL(''' + @MatterNumber + ''', ''-1'') = ''-1'' OR ils.MatterNumber=''' + @MatterNumber + ''')
						AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR
						CASE WHEN ils.MatterCloseDate IS NULL THEN ''Open''
						WHEN ils.MatterCloseDate > ''' + @pDateEnd + ''' THEN ''Open''
						ELSE ''Closed'' END =''' + @MatterStatus + ''')
						AND (ISNULL(''' + @MatterOwnerId + ''', ''-1'') = ''-1'' OR ils.MatterOwnerId=''' + @MatterOwnerId + ''')
						AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR ils.MatterDF01=''' + @MatterDynamicField1 + ''')
						AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR ils.MatterDF02=''' + @MatterDynamicField2 + ''')
						AND (ISNULL(''' + @MatterVendorDynamicField1 + ''', ''-1'') = ''-1'' OR ils.MatterVendorDF01=''' + @MatterVendorDynamicField1 + ''')
						AND (ISNULL(''' + @MatterVendorDynamicField2 + ''', ''-1'') = ''-1'' OR ils.MatterVendorDF02=''' + @MatterVendorDynamicField2 + ''')
						AND (ISNULL(''' + @VendorId + ''', ''-1'') = ''-1'' OR VendorId=''' + @VendorId + ''')
						AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR ils.VendorType=''' + @VendorType + ''')
    GROUP BY 
      ils.afaruletypes
  ) AS af ON af.afaruletypes = ils.afaruletypes 
WHERE 
  ils.invoicestatus IN ('''+@InvoiceStatus+''')
  AND ils.invoicestatusdate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
  AND ils.currencyid = 1 
  AND ils.afaruletypes IS NOT NULL 
  AND (ISNULL(''' + @MatterName + ''', ''-1'') = ''-1'' OR ils.MatterName=''' + @MatterName + ''')
						AND (ISNULL(''' + @MatterNumber + ''', ''-1'') = ''-1'' OR ils.MatterNumber=''' + @MatterNumber + ''')
						AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR
						CASE WHEN ils.MatterCloseDate IS NULL THEN ''Open''
						WHEN ils.MatterCloseDate > ''' + @pDateEnd + ''' THEN ''Open''
						ELSE ''Closed'' END =''' + @MatterStatus + ''')
						AND (ISNULL(''' + @MatterOwnerId + ''', ''-1'') = ''-1'' OR ils.MatterOwnerId=''' + @MatterOwnerId + ''')
						AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR ils.MatterDF01=''' + @MatterDynamicField1 + ''')
						AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR ils.MatterDF02=''' + @MatterDynamicField2 + ''')
						AND (ISNULL(''' + @MatterVendorDynamicField1 + ''', ''-1'') = ''-1'' OR ils.MatterVendorDF01=''' + @MatterVendorDynamicField1 + ''')
						AND (ISNULL(''' + @MatterVendorDynamicField2 + ''', ''-1'') = ''-1'' OR ils.MatterVendorDF02=''' + @MatterVendorDynamicField2 + ''')
						AND (ISNULL(''' + @VendorId + ''', ''-1'') = ''-1'' OR VendorId=''' + @VendorId + ''')
						AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR ils.VendorType=''' + @VendorType + ''')
ORDER BY 
  [AFA Savings] DESC

				'
PRINT(@SQL)
EXEC(@SQL)
