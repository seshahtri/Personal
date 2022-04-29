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



SET @SQL = '
exec as user = ''admin''
SELECT 
MatterOwnerName [Matter Owner], TotalInvoices [Total Invoices], AverageDays [Average Days], MaxDays [Max Days], MinDays [Min Days] FROM 
( SELECT A1.MatterOwnerId, A1.TotalInvoices, A1.AverageDays, B1.MaxDays, B1.MinDays 
FROM (
SELECT MatterOwnerId,COUNT(DISTINCT A.InvoiceId) TotalInvoices, ROUND(CAST(SUM(DateDiff) AS FLOAT)/COUNT(DISTINCT A.InvoiceId),0) AverageDays 
FROM ( 
 SELECT DISTINCT MatterOwnerId, InvoiceId FROM  [dbo].[V_InvoiceSummary] ILI
WHERE Invoiceid IN (
SELECT DISTINCT InvoiceId
FROM
    [dbo].[V_InvoiceSummary] ILI
         INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId
INNER JOIN (
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM fn_GetRollupPracticeAreasWithSecurity2 (''' + @PracticeAreaId + ''', ''|'',-1,0)
) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
WHERE 
    invoiceStatus IN ( '+@InvoiceStatus+' ) 
    and '+@DateField+' between '''+@pDateStart+''' AND '''+@pDateEnd+'''
       and InReviewDate IS NOT NULL 
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
AND (ISNULL(''' + @VendorName + ''', ''-1'') = ''-1'' OR ILI.VendorName=''' + @VendorName + ''')
AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR ILI.VendorType=''' + @VendorType + ''')
 GROUP BY 
 InvoiceId
HAVING (MAX(DATEDIFF(day,InReviewDate,ApprovedDate))) IS NOT NULL)) A JOIN (

SELECT DISTINCT InvoiceId, MAX(DATEDIFF(day,InReviewDate,ApprovedDate)) DateDiff
FROM
    [dbo].[V_InvoiceSummary] ILI
      INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId
INNER JOIN (
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM fn_GetRollupPracticeAreasWithSecurity2 (''' + @PracticeAreaId + ''', ''|'',-1,0)
) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
WHERE 
    invoiceStatus IN   ('+@InvoiceStatus+')
    and '+@DateField+' between '''+@pDateStart+''' AND '''+@pDateEnd+'''
       and InReviewDate IS NOT NULL 
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
AND (ISNULL(''' + @VendorName + ''', ''-1'') = ''-1'' OR ILI.VendorName=''' + @VendorName + ''')
AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR ILI.VendorType=''' + @VendorType + ''')
 GROUP BY 
 InvoiceId) B ON A.InvoiceId = B.InvoiceId
GROUP BY MatterOwnerId) A1   JOIN (


SELECT MatterOwnerId, COUNT (DISTINCT InvoiceID) TotalInvoices, MAX(DATEDIFF(day,InReviewDate,ApprovedDate)) MaxDays, 
MIN(DATEDIFF(day,InReviewDate,ApprovedDate)) MinDays
FROM     [dbo].[V_InvoiceSummary] ILI
       INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId
INNER JOIN (
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM fn_GetRollupPracticeAreasWithSecurity2 (''' + @PracticeAreaId + ''', ''|'',-1,0)
) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
WHERE InvoiceID IN (
SELECT DISTINCT InvoiceId 
FROM
    [dbo].[V_InvoiceSummary] ILI
       INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId
INNER JOIN (
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM fn_GetRollupPracticeAreasWithSecurity2 (''' + @PracticeAreaId + ''', ''|'',-1,0)
) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
       -- ili        join [dbo].[V_MatterOwners] MO on ili.matterownerid = Mo.MatterOwnerName
WHERE 
    invoiceStatus IN  ('+@InvoiceStatus+')
    and '+@DateField+' between '''+@pDateStart+''' AND '''+@pDateEnd+'''
       and InReviewDate IS NOT NULL 
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
AND (ISNULL(''' + @VendorName + ''', ''-1'') = ''-1'' OR ILI.VendorName=''' + @VendorName + ''')
AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR ILI.VendorType=''' + @VendorType + ''')
	  

 GROUP BY 
 InvoiceId
HAVING (MAX(DATEDIFF(day,InReviewDate,ApprovedDate))) IS NOT NULL)
GROUP BY MatterOwnerId ) B1 ON A1.MatterOwnerId = B1.MatterOwnerId  OR (A1.MatterOwnerId IS NULL AND B1.MatterOwnerId IS NULL)) AS IDS
 left JOIN V_MatterOwners MO ON IDS.MatterOwnerId = MO.MatterOwnerId
ORDER BY TotalInvoices DESC

'
print(@SQL)
exec(@SQL)