--USE DEV044_IOD_DataMart;

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
SET @InvoiceStatus= ^InvoiceStatus^;
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

--SET @CurrencyCode ='USD';
--SET @pDateStart='2017-01-01 00:00:00.00';
--SET @pDateEnd ='2017-12-31 23:59:59.99';
--SET @InvoiceStatus ='Paid'',''Processed';
--SET @MatterName = 'Matter 1141548';
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


SET @SQL = '
exec as user = ''admin''
SELECT
--ili.VendorId,
MIN(ili.VendorName) as [Vendor Name],
ili.RoleName as [Role Name],
MIN(ex.CurrencyCode) as [Currency Code],
(SUM(ili.HoursForRates)/(CASE WHEN vs.VendorHours=0 THEN NULL ELSE vs.VendorHours END)*100) as [% Hours Billed],
SUM(ili.HoursForRates) as [Hours],
vs.VendorHours as [Total Hours],
SUM((ili.GrossFeeAmountForRates) * ISNULL(ex.ExchangeRate, 1)) as [Spend]
--vs.VendorSpend
FROM V_InvoiceTimekeeperSummary ili
INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId
INNER JOIN (
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',-1,0)
) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
INNER JOIN BusinessUnitAndAllDescendants bud ON ili.BusinessUnitId = bud.ChildBusinessUnitId
INNER JOIN (
SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM fn_GetRollupBusinessUnitsWithSecurity (-1, ''|'',-1,0)
) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate
JOIN (
SELECT
ili.VendorId,
SUM(ili.HoursForRates) VendorHours,
SUM((ili.GrossFeeAmountForRates) * ISNULL(ex.ExchangeRate, 1)) VendorSpend
FROM V_InvoiceTimekeeperSummary ili
INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId
INNER JOIN (
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',-1,0)
) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
INNER JOIN BusinessUnitAndAllDescendants bud ON ili.BusinessUnitId = bud.ChildBusinessUnitId
INNER JOIN (
SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM fn_GetRollupBusinessUnitsWithSecurity (-1, ''|'',-1,0)
) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate
WHERE
ili.InvoiceStatus IN ('''+@InvoiceStatus+''')
AND ex.CurrencyId = 1
AND (ili.invoicedate >='''+@pDateStart+''' AND ili.InvoiceDate<= '''+@pDateEnd+''')
AND ili.RoleName IS NOT NULL
AND ili.FeeRate<=2500
AND (ili.HoursForRates > 0 OR ili.GrossFeeAmountForRates > 0)
AND (ISNULL(''' + @mattername + ''', ''-1'') = ''-1'' OR ili.mattername=''' + @mattername + ''')
	  AND (ISNULL(''' + @MatterNumber + ''', ''-1'') = ''-1'' OR ili.MatterNumber=''' + @MatterNumber + ''')
	  AND (ISNULL(''' + @MatterOwnerId + ''', ''-1'') = ''-1'' OR ili.MatterOwnerId=''' + @MatterOwnerId + ''')
	   AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR ili.MatterStatus=''' + @MatterStatus + ''')
	   AND (ISNULL(''' + @VendorId + ''', ''-1'') = ''-1'' OR ili.VendorId=''' + @VendorId + ''')
	    AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR ili.VendorType=''' + @VendorType + ''')
	    AND (ISNULL(''' + @PracticeAreaId + ''', ''-1'') = ''-1'' OR ili.PracticeAreaId=''' + @PracticeAreaId + ''')
		AND (ISNULL(''' + @BusinessUnitId + ''', ''-1'') = ''-1'' OR ili.BusinessUnitId=''' + @BusinessUnitId + ''')
		AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR ili.MatterDF01=''' + @MatterDynamicField1 + ''')
        AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR ili.MatterDF02=''' + @MatterDynamicField2 + ''')
		AND (ISNULL(''' + @MatterVendorDynamicField1 + ''', ''-1'') = ''-1'' OR ili.MatterVendorDF01=''' + @MatterVendorDynamicField1 + ''')
        AND (ISNULL(''' + @MatterVendorDynamicField2 + ''', ''-1'') = ''-1'' OR ili.MatterVendorDF02=''' + @MatterVendorDynamicField2 + ''') 
GROUP BY
ili.VendorId
) vs on vs.VendorId=ili.VendorId
WHERE
ili.InvoiceStatus IN ('''+@InvoiceStatus+''')
AND ex.CurrencyId = 1
AND (ili.invoicedate >='''+@pDateStart+''' AND ili.InvoiceDate<= '''+@pDateEnd+''')
AND ili.RoleName IS NOT NULL
AND ili.FeeRate<=2500
AND (ili.HoursForRates > 0 OR ili.GrossFeeAmountForRates > 0)
AND (ISNULL(''' + @mattername + ''', ''-1'') = ''-1'' OR ili.mattername=''' + @mattername + ''')
	  AND (ISNULL(''' + @MatterNumber + ''', ''-1'') = ''-1'' OR ili.MatterNumber=''' + @MatterNumber + ''')
	  AND (ISNULL(''' + @MatterOwnerId + ''', ''-1'') = ''-1'' OR ili.MatterOwnerId=''' + @MatterOwnerId + ''')
	   AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR ili.MatterStatus=''' + @MatterStatus + ''')
	   AND (ISNULL(''' + @VendorId + ''', ''-1'') = ''-1'' OR ili.VendorId=''' + @VendorId + ''')
	    AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR ili.VendorType=''' + @VendorType + ''')
	    AND (ISNULL(''' + @PracticeAreaId + ''', ''-1'') = ''-1'' OR ili.PracticeAreaId=''' + @PracticeAreaId + ''')
		AND (ISNULL(''' + @BusinessUnitId + ''', ''-1'') = ''-1'' OR ili.BusinessUnitId=''' + @BusinessUnitId + ''')
		AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR ili.MatterDF01=''' + @MatterDynamicField1 + ''')
        AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR ili.MatterDF02=''' + @MatterDynamicField2 + ''')
		AND (ISNULL(''' + @MatterVendorDynamicField1 + ''', ''-1'') = ''-1'' OR ili.MatterVendorDF01=''' + @MatterVendorDynamicField1 + ''')
        AND (ISNULL(''' + @MatterVendorDynamicField2 + ''', ''-1'') = ''-1'' OR ili.MatterVendorDF02=''' + @MatterVendorDynamicField2 + ''') 
GROUP BY
ili.VendorId,
vs.VendorHours,
ili.RoleName,
vs.VendorSpend
ORDER BY
vs.VendorHours desc,
CASE WHEN ili.RoleName=''Partner'' THEN 1
WHEN ili.RoleName=''Associate'' THEN 2
WHEN ili.RoleName=''Paralegal'' THEN 3
WHEN ili.RoleName=''Of Counsel'' THEN 4
ELSE 5
END
'
PRINT(@SQL)
EXEC(@SQL)