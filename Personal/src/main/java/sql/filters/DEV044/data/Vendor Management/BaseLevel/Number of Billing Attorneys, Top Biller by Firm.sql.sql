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
--SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;
SET @DateField=^InvoiceDate^;
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
SET @InvoiceStatus= '''Paid'',''Processed''';
--SET @CurrencyCode= 'USD';
--SET @DateField='InvoiceDate';
--SET @MatterName='-1';--'Matter 3686999';
--SET @MatterNumber='-1';
--SET @MatterStatus='-1';
--SET @MatterOwnerName ='-1';--'Conner, Dan';
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
EXECUTE AS USER=''Admin''
SELECT
V.vendorname as [Law Firm],
a.FullName as [Top Billing Attorney],
E.CurrencyCode as [Currency Code],
CAST(a.TopBillingAttorneyFees AS FLOAT) as [Top Billing Attorney Fees],
CAST(CAST(a.TopBillingAttorneyFees AS FLOAT)/CAST(SUM(il.NetFeeAmount) AS FLOAT) AS FLOAT)*100 [Top Billing Attorney % of Law Firm Fees],
Count (DISTINCT il.timekeeperid) as [Number of Attorneys Billing],
CAST(SUM(il.NetFeeAmount) AS FLOAT) as [Law Firm Fees]
FROM invoicedim i
JOIN ExchangeRateDim E ON CAST(I.ExchangeRateDate AS DATE) = E.ExchangeRateDate
JOIN invoicelineitemfact il on il.invoiceid= i.invoiceid
JOIN Vendordim V on V.vendorid = il.vendorid
JOIN BillCodeDim BC ON BC.BillCodeId = il.BillCodeId
JOIN TimekeeperDim tk on tk.TimekeeperId=il.TimekeeperId
Join V_InvoiceSummary ili on ili.invoiceid=i.invoiceid
INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId
INNER JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM dbo.fn_GetRollupPracticeAreasWithSecurity2 (''' + @PracticeAreaId + ''', ''|'',-1,0)
) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
INNER JOIN BusinessUnitAndAllDescendants bud ON ili.BusinessUnitId = bud.ChildBusinessUnitId
INNER JOIN (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM dbo.fn_GetRollupBusinessUnitsWithSecurity (''' + @BusinessUnitId + ''', ''|'',-1,0)
) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
LEFT JOIN (
SELECT
tk.TimekeeperId,
tk.FullName,
il.VendorId,
CAST(SUM(il.NetFeeAmount) AS FLOAT) TopBillingAttorneyFees,
ROW_NUMBER() OVER (PARTITION BY il.VendorId ORDER BY SUM(il.NetFeeAmount) DESC) AS RowNumber
FROM invoicedim i
JOIN ExchangeRateDim E ON CAST(I.ExchangeRateDate AS DATE) = E.ExchangeRateDate
JOIN invoicelineitemfact il on il.invoiceid= i.invoiceid
JOIN BillCodeDim BC ON BC.BillCodeId = il.BillCodeId
JOIN TimekeeperDim tk on tk.TimekeeperId=il.TimekeeperId
Join V_InvoiceSummary ili1 on ili1.invoiceid=i.invoiceid
INNER JOIN PracticeAreaAndAllDescendants pad ON ili1.PracticeAreaId = pad.ChildPracticeAreaId
INNER JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM dbo.fn_GetRollupPracticeAreasWithSecurity2 (''' + @PracticeAreaId + ''', ''|'',-1,0)
) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
INNER JOIN BusinessUnitAndAllDescendants bud ON ili1.BusinessUnitId = bud.ChildBusinessUnitId
INNER JOIN (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM dbo.fn_GetRollupBusinessUnitsWithSecurity (''' + @BusinessUnitId + ''', ''|'',-1,0)
) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
WHERE E.CurrencyId = 1 AND i.InvoiceStatus in ('+@InvoiceStatus+') AND i.'+@DateField+' between '''+@pDateStart+''' AND '''+@pDateEnd+''' AND BC.Category = ''Fee'' AND tk.TimekeeperId is not null
AND (ISNULL(''' + @MatterName + ''', ''-1'') = ''-1'' OR MatterName=''' + @MatterName + ''')
AND (ISNULL(''' + @MatterNumber + ''', ''-1'') = ''-1'' OR MatterNumber=''' + @MatterNumber + ''')
AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR
CASE WHEN MatterCloseDate IS NULL THEN ''Open''
WHEN MatterCloseDate > ''' + @pDateEnd + ''' THEN ''Open''
ELSE ''Closed'' END =''' + @MatterStatus + ''')
AND (ISNULL(''' + @MatterOwnerName + ''', ''-1'') = ''-1'' OR MatterOwnerName=''' + @MatterOwnerName + ''')
AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR MatterDF01=''' + @MatterDynamicField1 + ''')
AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR MatterDF02=''' + @MatterDynamicField2 + ''')
AND (ISNULL(''' + @MatterVendorDynamicField1 + ''', ''-1'') = ''-1'' OR MatterVendorDF01=''' + @MatterVendorDynamicField1 + ''')
AND (ISNULL(''' + @MatterVendorDynamicField2 + ''', ''-1'') = ''-1'' OR MatterVendorDF02=''' + @MatterVendorDynamicField2 + ''')
AND (ISNULL(''' + @VendorName + ''', ''-1'') = ''-1'' OR ili1.VendorName=''' + @VendorName + ''')
AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR ili1.VendorType=''' + @VendorType + ''')
GROUP BY tk.TimekeeperId,
tk.FullName,
il.VendorId
) a on a.VendorId=il.VendorId
WHERE E.CurrencyId = 1
AND i.InvoiceStatus in ('+@InvoiceStatus+') AND i.'+@DateField+' between '''+@pDateStart+''' AND '''+@pDateEnd+'''
AND BC.Category = ''Fee''
AND tk.TimekeeperId is not null
AND a.RowNumber=1
AND (ISNULL(''' + @MatterName + ''', ''-1'') = ''-1'' OR MatterName=''' + @MatterName + ''')
AND (ISNULL(''' + @MatterNumber + ''', ''-1'') = ''-1'' OR MatterNumber=''' + @MatterNumber + ''')
AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR
CASE WHEN MatterCloseDate IS NULL THEN ''Open''
WHEN MatterCloseDate > ''' + @pDateEnd + ''' THEN ''Open''
ELSE ''Closed'' END =''' + @MatterStatus + ''')
AND (ISNULL(''' + @MatterOwnerName + ''', ''-1'') = ''-1'' OR MatterOwnerName=''' + @MatterOwnerName + ''')
AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR MatterDF01=''' + @MatterDynamicField1 + ''')
AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR MatterDF02=''' + @MatterDynamicField2 + ''')
AND (ISNULL(''' + @MatterVendorDynamicField1 + ''', ''-1'') = ''-1'' OR MatterVendorDF01=''' + @MatterVendorDynamicField1 + ''')
AND (ISNULL(''' + @MatterVendorDynamicField2 + ''', ''-1'') = ''-1'' OR MatterVendorDF02=''' + @MatterVendorDynamicField2 + ''')
AND (ISNULL(''' + @VendorName + ''', ''-1'') = ''-1'' OR ili.VendorName=''' + @VendorName + ''')
AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR ili.VendorType=''' + @VendorType + ''')
GROUP BY V.vendorname,a.FullName, a.TopBillingAttorneyFees, E.CurrencyCode
ORDER BY [Number of Attorneys Billing] desc
'
PRINT (@SQL)
EXEC(@SQL)