DECLARE @CurrencyCode  varchar (50);
DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @DateField varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @InvoiceStatus varchar (MAX);
DECLARE @MatterName varchar (1000);
DECLARE @MatterNumber varchar (1000);
DECLARE @MatterStatus varchar (1000);
DECLARE @MatterOwnerName varchar (1000);
DECLARE @MatterOwnerId varchar (1000);
DECLARE @VendorName varchar (1000);
DECLARE @VendorId varchar (1000);
DECLARE @VendorType varchar (1000);
DECLARE @PracticeAreaName varchar (1000);
DECLARE @PracticeAreaId varchar(1000);
DECLARE @BusinessUnitName varchar (1000);
DECLARE @BusinessUnitId varchar (1000);
DECLARE @MatterDynamicField1 varchar (1000);
DECLARE @MatterDynamicField2 varchar (1000);
DECLARE @MatterVendorDynamicField1 varchar (1000);
DECLARE @MatterVendorDynamicField2 varchar (1000);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
--SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;
SET @DateField=^InvoiceDate^;
SET @MatterName=^MatterName^;
SET @MatterNumber =^MatterNumber^;
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

--SET @pDateStart='01/01/2017';
--SET @pDateEnd ='12/31/2017';
--SET @CurrencyCode ='USD';
SET @InvoiceStatus ='''Paid'',''Processed''';
--SET @MatterName = '-1';  --Matter 1141548
--SET @MatterNumber ='-1';
--SET @MatterOwnerName ='-1';
--SET @MatterStatus = '-1';
--SET @VendorName='-1';
--SET @VendorType ='-1';
--SET @BusinessUnitName ='-1';
--SET @PracticeAreaName='-1';
--SET @MatterDynamicField1='-1';
--SET @MatterDynamicField2='-1';
--SET @MatterVendorDynamicField1='-1';
--SET @MatterVendorDynamicField2='-1';
SET @PracticeAreaId = ISNULL((SELECT TOP 1 p.PracticeAreaId FROM PracticeAreaDim p WHERE p.PracticeAreaName = @PracticeAreaName),-1)
SET @BusinessUnitId = ISNULL((SELECT TOP 1 b.BusinessUnitId FROM BusinessUnitDim b where b.BusinessUnitName = @BusinessUnitName),-1)
SET @MatterOwnerId = ISNULL((Select TOP 1 MO.MatterOwnerId FROM V_MatterOwners MO where MO.MatterOwnerName = @MatterOwnerName),-1)
SET @VendorId = ISNULL((Select TOP 1 V.VendorId FROM vendordim V where V.vendorname =@VendorName),-1)
SET @SQL=
'		EXEC AS USER = ''admin''
		SELECT 			
			mv.VendorName,
			mv.VendorType,
			ex.Currencycode,
			COUNT (DISTINCT MATTERID) [Open Matters],
			SUM (CASE WHEN mv.InvoiceStatus IN ('+@InvoiceStatus+') AND convert(varchar,mv.InvoiceDate,101)<='''+ @pDateEnd+'''
					THEN mv.Amount * ISNULL(ex.ExchangeRate, 1) ELSE CAST(NULL AS FLOAT) END) LOMSpend
		   FROM V_MatterVendorSpendSummary mv
			INNER JOIN BusinessUnitAndAllDescendants bud ON mv.BusinessUnitId = bud.ChildBusinessUnitId
			INNER JOIN (
			SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
			FROM dbo.fn_GetRollupBusinessUnitsWithSecurity (''-1'', ''|'',-1,0)
						) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
			INNER JOIN PracticeAreaAndAllDescendants pad ON mv.PracticeAreaId = pad.ChildPracticeAreaId
			LEFT JOIN ExchangeRateDim ex ON mv.ExchangeRateDate = ex.ExchangeRateDate
			INNER JOIN (
			SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
			FROM dbo.fn_GetRollupPracticeAreasWithSecurity2 (''-1'', ''|'',-1,0)
						 ) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
		WHERE 
		  ex.CurrencyId = 1
		  AND mv.VendorType <> ''Client''
		  AND mv.MatterStatus <> ''Closed''
		  AND (ISNULL(''' + @mattername + ''', ''-1'') = ''-1'' OR mv.mattername=''' + @mattername + ''')
	  AND (ISNULL(''' + @MatterNumber + ''', ''-1'') = ''-1'' OR mv.MatterNumber=''' + @MatterNumber + ''')
	  AND (ISNULL(''' + @MatterOwnerId + ''', ''-1'') = ''-1'' OR mv.MatterOwnerId=''' + @MatterOwnerId + ''')
	   --AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR mv.MatterStatus=''' + @MatterStatus + ''')
	   AND (ISNULL(''' + @VendorId + ''', ''-1'') = ''-1'' OR mv.VendorId=''' + @VendorId + ''')
	    --AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR mv.VendorType=''' + @VendorType + ''')
	    AND (ISNULL(''' + @PracticeAreaId + ''', ''-1'') = ''-1'' OR mv.PracticeAreaId=''' + @PracticeAreaId + ''')
		AND (ISNULL(''' + @BusinessUnitId + ''', ''-1'') = ''-1'' OR mv.BusinessUnitId=''' + @BusinessUnitId + ''')
		AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR mv.MatterDF01=''' + @MatterDynamicField1 + ''')
        AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR mv.MatterDF02=''' + @MatterDynamicField2 + ''')
		AND (ISNULL(''' + @MatterVendorDynamicField1 + ''', ''-1'') = ''-1'' OR mv.MatterVendorDF01=''' + @MatterVendorDynamicField1 + ''')
        AND (ISNULL(''' + @MatterVendorDynamicField2 + ''', ''-1'') = ''-1'' OR mv.MatterVendorDF02=''' + @MatterVendorDynamicField2 + ''')
		GROUP BY
			mv.VendorId,
			mv.VendorName,
			mv.VendorType,
			ex.Currencycode
		ORDER BY [open Matters] DESC
'
PRINT (@SQL)
EXEC(@SQL)
