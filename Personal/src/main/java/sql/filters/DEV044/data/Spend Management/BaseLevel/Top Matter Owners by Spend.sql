--USE DEV044_IOD_DataMart

EXEC AS USER ='admin' 

DECLARE @pDateStart varchar (50);
DECLARE @pDateEnd varchar (50);
DECLARE @DateField varchar (50);
DECLARE @InvoiceStatus nvarchar (1000);
DECLARE @CurrencyCode varchar (50);
DECLARE @SQL VARCHAR(4000);
DECLARE @MatterName varchar (1000);
DECLARE @MatterNumber varchar (1000);
DECLARE @MatterStatus varchar (1000);
DECLARE @MatterOwnerName varchar (1000);
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



SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @InvoiceStatus= ^InvoiceStatus^;
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





--SET @pDateStart='1/1/2017';
--SET @pDateEnd='12/31/2017';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';
--SET @DateField='InvoiceDate';
--SET @MatterName='-1';
--SET @MatterNumber='-1';
--SET @MatterStatus='-1';
--SET @MatterOwnerName ='-1';
--SET  @VendorName='-1';
--SET  @VendorType ='-1';
--SET  @PracticeAreaName ='-1';
--SET  @BusinessUnitName='-1';
--SET @MatterDynamicField1='-1';
--SET @MatterDynamicField2='-1';
--SET @MatterVendorDynamicField1='-1';
--SET @MatterVendorDynamicField2='-1';



SET @PracticeAreaId = ISNULL((SELECT TOP 1 p.PracticeAreaId FROM PracticeAreaDim p WHERE p.PracticeAreaName = @PracticeAreaName),-1)
SET @BusinessUnitId = ISNULL((SELECT TOP 1 b.BusinessUnitId FROM BusinessUnitDim b where b.BusinessUnitName = @BusinessUnitName),-1)

SET @SQL='
SELECT 
	d.FullName as ''MatterOwner'',
	CASE WHEN t.MatterCloseDate  IS NULL THEN ''Active'' Else ''Closed'' End as [Matter State],
	e.CurrencyCode as ''Currency Code'',
	SUM (il.amount) as ''Spend'',
	COUNT(Distinct t.Matterid) as ''Matters'',
	a.Total_Spend  as ''Total Spend'',
	a.Total_Hours  as ''Total Hours''
	--a.Total_Hours  as ''Total Units''
FROM matterdim t
	LEFT JOIN TimekeeperDim d ON t.MatterOwnerId = d.TimekeeperId
	join invoicedim i on i.matterid =t.matterid
	JOIN ExchangeRateDim E ON CAST(I.ExchangeRateDate AS DATE) = E.ExchangeRateDate 
	join invoicelineitemfact il on  i.invoiceid=il.invoiceid
	Left Join V_InvoiceSummary ili on ili.invoiceid=i.invoiceid
	LEFT OUTER JOIN (SELECT TOP 10 f.MatterOwnerId, SUM (il.Amount) as Total_Spend, SUM(il.units) as Total_Hours
					from matterdim  f
						join invoicedim i on i.matterid =f.matterid 
						JOIN ExchangeRateDim E ON CAST(I.ExchangeRateDate AS DATE) = E.ExchangeRateDate 
						join invoicelineitemfact il on  i.invoiceid=il.invoiceid
						Left Join V_InvoiceSummary ili on ili.invoiceid=i.invoiceid
					Where
						e.CurrencyCode = ''' + @CurrencyCode + '''
						and ili.InvoiceStatus IN (''' + @InvoiceStatus + ''')
						AND (ili.'+@DateField+' between ''' + @pDateStart + ''' and ''' + @pDateEnd + ''')
						AND (ISNULL(''' + @MatterName + ''', ''-1'') = ''-1'' OR ili.MatterName=''' + @MatterName + ''')
AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR
CASE WHEN ili.MatterCloseDate IS NULL THEN ''Open''
WHEN ili.MatterCloseDate > ''' + @pDateEnd + ''' THEN ''Open''
ELSE ''Closed'' END =''' + @MatterStatus + ''')
	AND (ISNULL(''' + @MatterOwnerName + ''', ''-1'') = ''-1'' OR MatterOwnerName=''' + @MatterOwnerName + ''')
AND (ISNULL(''' + @VendorName + ''', ''-1'') = ''-1'' OR VendorName=''' + @VendorName + ''')
AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR VendorType=''' + @VendorType + ''')
				    GROUP BY f.MatterOwnerId) a ON  
						(case when a.MatterOwnerId is null then '' '' else a.MatterOwnerId end = case when t.MatterOwnerId is null then '' '' else t.MatterOwnerId end)
WHERE 
	 e.CurrencyCode = ''' + @CurrencyCode + '''
	 and ili.InvoiceStatus IN (''' + @InvoiceStatus + ''')
	 AND (ili.'+@DateField+' between ''' + @pDateStart + ''' and ''' + @pDateEnd + ''')
	 AND (ISNULL(''' + @MatterName + ''', ''-1'') = ''-1'' OR ili.MatterName=''' + @MatterName + ''')
	 AND (ISNULL(''' + @MatterNumber + ''', ''-1'') = ''-1'' OR ili.MatterNumber=''' + @MatterNumber + ''')
AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR
CASE WHEN ili.MatterCloseDate IS NULL THEN ''Open''
WHEN ili.MatterCloseDate > ''' + @pDateEnd + ''' THEN ''Open''
ELSE ''Closed'' END =''' + @MatterStatus + ''')
	AND (ISNULL(''' + @MatterOwnerName + ''', ''-1'') = ''-1'' OR MatterOwnerName=''' + @MatterOwnerName + ''')
AND (ISNULL(''' + @VendorName + ''', ''-1'') = ''-1'' OR VendorName=''' + @VendorName + ''')
AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR VendorType=''' + @VendorType + ''')
AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR VendorType=''' + @MatterDynamicField1 + ''')
AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR VendorType=''' + @MatterDynamicField2 + ''')
AND (ISNULL(''' + @MatterVendorDynamicField1 + ''', ''-1'') = ''-1'' OR VendorType=''' + @MatterVendorDynamicField1 + ''')
AND (ISNULL(''' + @MatterVendorDynamicField2 + ''', ''-1'') = ''-1'' OR VendorType=''' + @MatterVendorDynamicField2 + ''')
GROUP BY t.MatterOwnerId, d.FullName, a.Total_Spend, CASE WHEN t.MatterCloseDate  IS NULL THEN ''Active'' Else ''Closed'' End, a.Total_Hours, e.CurrencyCode
ORDER BY SUM (il.Amount) desc, CASE WHEN t.MatterCloseDate  IS NULL THEN ''Active'' Else ''Closed'' End  
'
Print @SQL
EXEC(@SQL)