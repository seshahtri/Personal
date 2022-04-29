--use DEV044_IOD_DataMart;

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
--SET @PracticeAreaName ='-1'; -- --Employment and Labor --Consumer Finance
--SET @BusinessUnitName='-1';--'NorthEast';--'NorthEast';
--SET @MatterDynamicField1='-1';--'Unspecified';
--SET @MatterDynamicField2='-1';
--SET @MatterVendorDynamicField1='-1';--'Unspecified';
--SET @MatterVendorDynamicField2='-1';



SET @PracticeAreaId = ISNULL((SELECT TOP 1 p.PracticeAreaId FROM PracticeAreaDim p WHERE p.PracticeAreaName = @PracticeAreaName),-1)
SET @BusinessUnitId = ISNULL((SELECT TOP 1 b.BusinessUnitId FROM BusinessUnitDim b where b.BusinessUnitName = @BusinessUnitName),-1)

SET @SQL='

EXEC AS USER =''admin''
--Adjustments by AFA Type by Vendor--
SELECT
   v.vendorname as [Vendor Name],
   ils.AfaRuleTypes as ''AFA Type'',
   CAST( sum(ils.AfaFeeAmount * - 1) AS FLOAT ) as ''AFA Adjustments'',
   COUNT(distinct ils.matterid) as ''# Matters'' 
FROM
   V_InvoiceLineItemSpendFactWithCurrency ils 
   JOIN
      vendordim v 
      on v.vendorid = ils.vendorid 
   JOIN
      costcenterdim c 
      on c.costcenterid = ils.costcenterid 		
      LEFT 
   JOIN
      (
         SELECT
            top 100000 v.vendorid,
            v.vendorname,
            CAST( sum(ils.AfaFeeAmount * - 1) AS FLOAT ) as ''Adjustments'' 
         FROM
            V_InvoiceLineItemSpendFactWithCurrency ils 
            JOIN
               vendordim v 
               on v.vendorid = ils.vendorid 
            JOIN
               costcenterdim c 
               on c.costcenterid = ils.costcenterid 					
         WHERE
            ils.InvoiceStatus IN ('''+@InvoiceStatus+''')
            AND ils.invoicestatusdate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
            AND ils.currencycode = '''+@CurrencyCode+''' 		
            AND ils.AfaRuleTypes IS NOT NULL 
         group by
            v.vendorid,
            v.vendorname 
         order by
            Adjustments desc 
      )
      ad 
      on ad.vendorid = ils.vendorid 
	  JOIN BusinessUnitAndAllDescendants BAD ON ils.BusinessUnitId = BAD.ChildBusinessUnitId
JOIN (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
  FROM fn_GetRollupBusinessUnitsWithSecurity (''' + @BusinessUnitId + ''', ''|'',-1,0)) BUS ON BAD.BusinessUnitId = BUS.RollupBusinessUnitId
    JOIN PracticeAreaAndAllDescendants PAD ON ils.PracticeAreaId = PAD.ChildPracticeAreaId
JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
  FROM fn_GetRollupPracticeAreasWithSecurity2 (''' + @PracticeAreaId + ''', ''|'',-1,0)) PAS ON PAD.PracticeAreaId = PAS.RollupPracticeAreaId
WHERE
   ils.InvoiceStatus IN ('''+@InvoiceStatus+''')
   AND ils.invoicestatusdate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+''' 
   AND ils.currencycode = '''+@CurrencyCode+'''
   AND ils.AfaRuleTypes IS NOT NULL 
   AND ad.adjustments IS NOT NULL 
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
AND (ISNULL(''' + @VendorName + ''', ''-1'') = ''-1'' OR v.VendorName=''' + @VendorName + ''')
AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR v.VendorType=''' + @VendorType + ''')
group by
   v.vendorname,
   ils.AfaRuleTypes,
   ad.adjustments 
order by
   ad.adjustments desc'

Print @SQL
EXEC(@SQL)