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
execute as user=''admin''
SELECT RollupPracticeAreaName [Practice Area], [Vendor Name], [Currency Code],
LEFT( STR(CAST([Percent of Total Practice Area Spend] AS FLOAT),22,22),22) [Percent of Total Practice Area Spend],
LEFT( STR(CAST(Spend AS FLOAT),22,22),22) [Spend]
FROM (
select TOP 1000000
[RollupPracticeArea].RollupPracticeAreaName,p1.VendorName as [Vendor Name], E.currencycode as [Currency Code],
CAST(sum((il.amount*AllocatedFraction) * ((ISNULL(e.ExchangeRate,1.0)))) AS FLOAT) as Spend,
A.Spend AS SpendOrder, CAST((CAST (SUM(il.amount) AS FLOAT)/NULLIF(A.Spend, 0)*100) AS FLOAT) [Percent of Total Practice Area Spend]
from vendordim p1
join invoicedim i on i.vendorid =p1.vendorid
join invoicelineitemfact il on il.invoiceid= i.invoiceid
JOIN V_InvoiceSummary ili on ili.invoiceid = i.invoiceid
join ExchangeRateDim E ON CAST(I.ExchangeRateDate AS DATE) = E.ExchangeRateDate
INNER JOIN
dbo.InvoiceCostCenter ICC
ON ICC.InvoiceId = I.InvoiceId
Left join matterdim f on f.matterid=i.matterid
Right JOIN [dbo].[PracticeAreaAndAllDescendants] [PracticeAreaAndAllDescendants] ON f.[PracticeAreaId] = [PracticeAreaAndAllDescendants].[ChildPracticeAreaId]
INNER JOIN (
SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',-1,1)
) [RollupPracticeArea] ON ([PracticeAreaAndAllDescendants].[PracticeAreaId] = [RollupPracticeArea].[RollupPracticeAreaId])



JOIN (
select TOP 1000000 RollupPracticeAreaName, CAST(sum((il.amount*AllocatedFraction) * ((ISNULL(e.ExchangeRate,1.0))))AS FLOAT) as Spend
from vendordim p1
join invoicedim i on i.vendorid =p1.vendorid
join invoicelineitemfact il on il.invoiceid= i.invoiceid
JOIN V_InvoiceSummary ili on ili.invoiceid = i.invoiceid
join ExchangeRateDim E ON CAST(I.ExchangeRateDate AS DATE) = E.ExchangeRateDate
INNER JOIN
dbo.InvoiceCostCenter ICC
ON ICC.InvoiceId = I.InvoiceId
Left join matterdim f on f.matterid=i.matterid
Right JOIN [dbo].[PracticeAreaAndAllDescendants] [PracticeAreaAndAllDescendants] ON f.[PracticeAreaId] = [PracticeAreaAndAllDescendants].[ChildPracticeAreaId]
INNER JOIN (
SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',-1,1)
) [RollupPracticeArea] ON ([PracticeAreaAndAllDescendants].[PracticeAreaId] = [RollupPracticeArea].[RollupPracticeAreaId])
where E.currencyid=''1''
AND i.invoicestatus IN ('''+@InvoiceStatus+''')
AND i.InvoiceDate between '''+@pDateStart+''' and '''+@pDateEnd+'''
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
Group by RollupPracticeAreaName
ORDER BY Spend DESC
) A ON A.RollupPracticeAreaName = [RollupPracticeArea].RollupPracticeAreaName


where E.currencyid=''1''
AND i.invoicestatus IN ('''+@InvoiceStatus+''')
AND i.InvoiceDate between '''+@pDateStart+''' and '''+@pDateEnd+'''
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
Group by p1.VendorName, E.CurrencyCode,[RollupPracticeArea].RollupPracticeAreaName, Spend
ORDER BY SpendOrder DESC, Spend DESC ) Br
ORDER BY SpendOrder DESC



'
print(@SQL)
EXEC(@SQL)