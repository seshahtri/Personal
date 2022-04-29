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




SET @SQL=
'



EXECUTE AS USER=''Admin''
SELECT
YEAR (i.InvoiceDate) Year,
case
when MONTH(i.InvoiceDate) = 1 then ''January ''
when MONTH(i.InvoiceDate) = 2 then ''Febuary ''
when MONTH(i.InvoiceDate) = 3 then ''March ''
when MONTH(i.InvoiceDate) = 4 then ''April ''
when MONTH(i.InvoiceDate) = 5 then ''May ''
when MONTH(i.InvoiceDate) = 6 then ''June ''
when MONTH(i.InvoiceDate) = 7 then ''July ''
when MONTH(i.InvoiceDate) = 8 then ''August ''
when MONTH(i.InvoiceDate) = 9 then ''September ''
when MONTH(i.InvoiceDate) = 10 then ''October ''
when MONTH(i.InvoiceDate) = 11 then ''November ''
when MONTH(i.InvoiceDate) = 12 then ''December ''
end as Month,
--MONTH(i.InvoiceDate) Month,
MIN(ex.CurrencyCode) AS [Currency Code],
COUNT(DISTINCT i.MatterId) [Open Matters],
COUNT(DISTINCT I.InvoiceId) Invoices,
SUM(I.NetFeeAmount * ISNULL(ex.ExchangeRate, 1)) Fees,
SUM(I.NetExpAmount * ISNULL(ex.ExchangeRate, 1)) Expenses,
SUM(i.Amount * ISNULL(ex.ExchangeRate, 1)) Spend,
SUM(i.Amount * ISNULL(ex.ExchangeRate, 1)) / COUNT_BIG(DISTINCT (CASE WHEN ((((DATEPART(year,i.[MatterOpenDate]) * 100) + DATEPART(month,i.[MatterOpenDate])) <= ((DATEPART(year,i.[InvoiceDate]) * 100) + DATEPART(month,i.[InvoiceDate]))) AND ((i.[MatterCloseDate] IS NULL) OR (((DATEPART(year,i.[MatterCloseDate]) * 100) + DATEPART(month,i.[MatterCloseDate])) >= ((DATEPART(year,i.[InvoiceDate]) * 100) + DATEPART(month,i.[InvoiceDate]))))) THEN (i.[MatterId]) ELSE CAST(NULL AS BIGINT) END)) AS [Avg Cost]
FROM V_InvoiceSummary i
INNER JOIN BusinessUnitAndAllDescendants bud ON i.BusinessUnitId = bud.ChildBusinessUnitId
INNER JOIN (
SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM dbo.fn_GetRollupBusinessUnitsWithSecurity (''' + @BusinessUnitId + ''', ''|'',-1,0)
) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
INNER JOIN PracticeAreaAndAllDescendants pad ON i.PracticeAreaId = pad.ChildPracticeAreaId
INNER JOIN (
SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM dbo.fn_GetRollupPracticeAreasWithSecurity2 (''' + @PracticeAreaId + ''', ''|'',-1,0)
) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
JOIN ExchangeRateDim ex ON i.ExchangeRateDate = ex.ExchangeRateDate
WHERE i.InvoiceStatus in ('+@InvoiceStatus+')
AND (i.'+@DateField+' >= '''+@pDateStart+''' AND i.'+@DateField+'<= '''+@pDateEnd+''')
AND ex.CurrencyId =1
AND((DATEPART(year,i.MatterOpenDate) * 100) + DATEPART(month,i.MatterOpenDate)) <= ((DATEPART(year,i.InvoiceDate) * 100) + DATEPART(month,i.InvoiceDate))
AND (i.MatterCloseDate IS NULL OR ((DATEPART(year,i.MatterCloseDate) * 100) + DATEPART(month,i.MatterCloseDate)) >= ((DATEPART(year,i.InvoiceDate) * 100) + DATEPART(month,i.InvoiceDate)))
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
AND (ISNULL(''' + @VendorName + ''', ''-1'') = ''-1'' OR i.VendorName=''' + @VendorName + ''')
AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR i.VendorType=''' + @VendorType + ''')
GROUP BY
YEAR (i.InvoiceDate),
MONTH(i.InvoiceDate)
'
PRINT (@SQL)
EXEC(@SQL)