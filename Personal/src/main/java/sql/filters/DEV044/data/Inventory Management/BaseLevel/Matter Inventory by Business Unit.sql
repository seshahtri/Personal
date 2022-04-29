EXEC AS USER = 'admin'
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
declare @matterownerid varchar(max);

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
--SET @MatterVendorDynamicField1=^DFMatterVendorDynamicField1^;
--SET @MatterVendorDynamicField2=^DFMatterVendorDynamicField2^;

--SET @pDateStart= '1/1/2017';
--SET @pDateEnd= '12/31/2017';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @DateField=REPLACE('Invoice Date',' ','');
--SET @CurrencyCode= 'USD';
----SET @DateField='InvoiceDate';
--SET @MatterName='-1';--'Matter 3686999';
----SET @MatterName='Matter 3686999';
--SET @MatterNumber='-1';
----SET @MatterNumber='1155280';
--SET @MatterStatus='-1';
--SET @MatterOwnerName ='-1'; --Halpert, Jim
--SET @VendorName='-1';--'Caron & Landry LLP';
--SET @VendorType ='-1';--'Law Firm';
--SET @PracticeAreaName ='-1'; --Consumer Finance, --Employment and Labor
--SET @BusinessUnitName='-1';--'NorthEast';--'NorthEast';
--SET @MatterDynamicField1='-1';--'Unspecified';
--SET @MatterDynamicField2='-1';
--SET @MatterVendorDynamicField1='-1';--'Unspecified';
--SET @MatterVendorDynamicField2='-1';

SET @PracticeAreaId = ISNULL((SELECT TOP 1 p.PracticeAreaId FROM PracticeAreaDim p WHERE p.PracticeAreaName = @PracticeAreaName),-1)
SET @BusinessUnitId = ISNULL((SELECT TOP 1 b.BusinessUnitId FROM BusinessUnitDim b where b.BusinessUnitName = @BusinessUnitName),-1)
SET @MatterownerId = ISNULL((SELECT TOP 1 d.timekeeperid FROM timekeeperdim d WHERE d.fullname = @MatterOwnerName),-1)

Set @SQL = 
'
SELECT
bu.RollupBusinessUnitName as [GB Client],
min(ex.CurrencyCode) as [Currency Code],
count(distinct(m.matterid)) as [Matters],
sum(case when InvoiceStatus in ('''+@InvoiceStatus+''') and '+@DateField+' <= '''+@pDateEnd+''' then m.Amount * isnull(ex.ExchangeRate,1) ELSE CAST(NULL AS FLOAT) END) as [Spend],
sum(case when InvoiceStatus in ('''+@InvoiceStatus+''') and '+@DateField+' <= '''+@pDateEnd+''' then m.hours ELSE CAST(NULL AS FLOAT) END) as [Hours]
FROM V_MatterSpendSummary m
INNER JOIN [dbo].BusinessUnitAndAllDescendants bud ON (m.BusinessUnitId = bud.ChildBusinessUnitId)
INNER JOIN ( SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM [dbo].fn_GetRollupBusinessUnitsWithSecurity ('''+ @BusinessUnitId +''', ''|'',-1,1)
) bu ON (bud.BusinessUnitId = bu.RollupBusinessUnitId)
LEFT JOIN [dbo].ExchangeRateDim ex ON (m.ExchangeRateDate = ex.ExchangeRateDate)
INNER JOIN [dbo].PracticeAreaAndAllDescendants pad ON (m.PracticeAreaId = pad.ChildPracticeAreaId)
INNER JOIN (
SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].fn_GetRollupPracticeAreasWithSecurity2 (''' + @PracticeAreaId +''', ''|'',-1,0)
) pa ON (pad.PracticeAreaId = pa.RollupPracticeAreaId)
where (((CASE WHEN (ex.CurrencyCode = '''+@CurrencyCode+''') THEN 1 WHEN NOT (ex.CurrencyCode = '''+@CurrencyCode+''') THEN 0 ELSE NULL END) IS NULL)
OR (ex.CurrencyCode = '''+@CurrencyCode+'''))
and m.MatterOpenDate <= '''+@pDateEnd+'''
AND (m.MatterCloseDate > '''+@pDateEnd+''' OR MatterCloseDate IS NULL)
--and matterownerid = '''+@matterownerid+'''
AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR MatterDF01=''' + @MatterDynamicField1 + ''')
AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR MatterDF02=''' + @MatterDynamicField1 + ''')
AND (ISNULL(''' + @MatterOwnerId + ''', ''-1'') = ''-1'' OR m.MatterownerId=''' + @MatterOwnerId + ''')
AND (ISNULL('''+@MatterNumber +''', ''-1'') = ''-1'' OR m.MatterNumber='''+ @MatterNumber +''')
AND (ISNULL('''+@MatterName +''', ''-1'') = ''-1'' OR m.MatterName='''+ @MatterName +''')

GROUP BY bu.RollupBusinessUnitName,bu.RollupBusinessUnitId
ORDER BY
Matters desc
'
print(@SQL)
EXEC(@SQL)