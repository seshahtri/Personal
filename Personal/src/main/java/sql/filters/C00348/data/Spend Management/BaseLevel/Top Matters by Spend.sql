EXECUTE AS USER='admin'
DECLARE @InvoiceStatus varchar (1000);
DECLARE @CurrencyCode varchar (50);
DECLARE @DateField varchar (50);
DECLARE @pDateStart varchar (50);
DECLARE @pDateEnd varchar (50);
DECLARE @MatterName varchar (1000);
DECLARE @MatterStatus varchar (1000);
DECLARE @MatterOwnerName varchar (1000);
DECLARE @VendorName varchar (1000);
DECLARE @VendorType varchar (1000);
DECLARE @PracticeAreaName varchar (1000);
DECLARE @PracticeAreaId varchar(1000);
DECLARE @BusinessUnitName varchar (1000);
DECLARE @BusinessUnitId varchar(100);
DECLARE @MatterDF01 varchar (1000) = '-1';
DECLARE @MatterDF02 varchar(1000) = '-1';
DECLARE @MatterDF03 varchar(1000) = '-1';
DECLARE @MatterDF04 varchar(1000) = '-1';
DECLARE @MatterDF05 varchar(1000) = '-1';
DECLARE @MatterDF06 varchar(1000) = '-1';
DECLARE @MatterDF07 varchar(1000) = '-1';
DECLARE @MatterDF08 varchar(1000) = '-1';
DECLARE @MatterDF09 varchar(1000) = '-1';
DECLARE @MatterDF10 varchar(1000) = '-1';
DECLARE @MatterDF11 varchar(1000) = '-1';
DECLARE @MatterDF12 varchar(1000) = '-1';
DECLARE @MatterDF13 varchar(1000) = '-1';
DECLARE @MatterDF14 varchar(1000) = '-1';
DECLARE @MatterDF15 varchar(1000) = '-1';
DECLARE @MatterDF16 varchar(1000) = '-1';
DECLARE @MatterDF17 varchar(1000) = '-1';
DECLARE @MatterDF18 varchar(1000) = '-1';
DECLARE @MatterDF19 varchar(1000) = '-1';
DECLARE @MatterDF20 varchar(1000) = '-1';
DECLARE @MatterDF21 varchar(1000) = '-1';
DECLARE @MatterDF22 varchar(1000) = '-1';
DECLARE @MatterDF23 varchar(1000) = '-1';
DECLARE @MatterDF24 varchar(1000) = '-1';
DECLARE @MatterDF25 varchar(1000) = '-1';
DECLARE @SQL VARCHAR(4000);


SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;
SET @DateField= ^InvoiceDate^;
SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @MatterName= ^MatterName^;
SET @MatterStatus= ^MatterStatus^;
SET @MatterOwnerName= ^MatterOwner^;
SET @VendorName= ^VendorName^;
SET @VendorType= ^VendorType^;
SET @PracticeAreaName= ^ClientLevel^;
SET @BusinessUnitName= ^GBLocation^; 
SET @MatterDF01 = ^DFCountry^;
SET @MatterDF02 = ^DFCoverageGroup^;
SET @MatterDF03 = ^DFCoverageType^;
SET @MatterDF04 = ^DFBenefitState^;
SET @MatterDF05 = ^DFAccidentState^;
SET @MatterDF06 = ^DFStatusCode^;
SET @MatterDF07 = ^DFClaimNumber^;
SET @MatterDF08 = ^DFGBBranchName^;
SET @MatterDF09 = ^DFGBBranchNumber^;


--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';
--SET @DateField='PaymentDate';
--SET @pDateStart='1/1/2018';
--SET @pDateEnd='12/31/2019';
--SET @MatterName='-1';
--SET @MatterStatus='-1';
--SET @MatterOwnerName='-1';
--SET @VendorName='-1';
--SET @VendorType='-1';
--SET @PracticeAreaName='-1';
----SET @BusinessUnitName='Zone-CARRIER PRACTICE';
--SET @BusinessUnitName='-1';
--SET @MatterDF04 = 'AB';
----SET @MatterDF02 = 'Workers Compensation'
----SET @MatterDF02 = '-1'


SET @PracticeAreaId = ISNULL((SELECT TOP 1 p.PracticeAreaId FROM PracticeAreaDim p WHERE p.PracticeAreaName = @PracticeAreaName),-1)
SET @BusinessUnitId = ISNULL((SELECT TOP 1 b.BusinessUnitId FROM BusinessUnitDim b where b.BusinessUnitName = @BusinessUnitName),-1)
SET @SQL='
SELECT Top 1000
MIN(ili.MatterName) as ''Matter Name'',
MIN(ili.MatterDF03) as ''Coverage Type'',
MIN(ili.MatterNumber) as ''Matter Number'',
MIN(ili.MatterDF07) as ''Claim Number'',
MIN(ili.MatterDF08) as ''GB Branch Name'',
MIN(ili.MatterDF09) as ''GB Branch Number'',
MIN(ili.PracticeAreaName) as ''GB Client'',
MIN(ili.MatterOwnerName) as ''Matter Owner Name'',
MIN(ili.MatterDF06) as ''Status Code'',
MIN(ili.MatterStatus) as ''Matter Status'',
MIN(ex.CurrencyCode) as ''Currency Code'',
SUM(ili.Amount * ISNULL(ex.ExchangeRate, 1)) as ''Spend''
FROM V_InvoiceSummary ili
INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId
INNER JOIN (
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM fn_GetRollupPracticeAreasWithSecurity2 (''' + @PracticeAreaId +''', ''|'',-1,0)
) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
INNER JOIN BusinessUnitAndAllDescendants bud ON ili.BusinessUnitId = bud.ChildBusinessUnitId
INNER JOIN (
SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM fn_GetRollupBusinessUnitsWithSecurity ('''+ @BusinessUnitId +''', ''|'',-1,0)
) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate
WHERE
ili.InvoiceStatus IN (''' + @InvoiceStatus + ''')
AND ex.CurrencyCode = ''' + @CurrencyCode + '''
AND (ili.'+ @DateField + '>=''' + @pDateStart + ''' AND ili.' +@DateField +'<= '''+ @pDateEnd +''')
AND (ISNULL(''' + @MatterName + ''', ''-1'') = ''-1'' OR ili.MatterName=''' + @MatterName + ''')
AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR
CASE WHEN ili.MatterCloseDate IS NULL THEN ''Open''
WHEN ili.MatterCloseDate > ''' + @pDateEnd + ''' THEN ''Open''
ELSE ''Closed'' END =''' + @MatterStatus + ''')
AND (ISNULL(''' + @MatterOwnerName + ''', ''-1'') = ''-1'' OR ili.MatterOwnerName=''' + @MatterOwnerName + ''')
AND (ISNULL(''' + @VendorName + ''', ''-1'') = ''-1'' OR ili.VendorName=''' + @VendorName + ''')
AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR ili.VendorType=''' + @VendorType + ''')
AND (ISNULL(''' + @MatterDF01 + ''', ''-1'') = ''-1'' OR ili.MatterDF01=''' + @MatterDF01 + ''')
AND (ISNULL(''' + @MatterDF02 + ''', ''-1'') = ''-1'' OR ili.MatterDF02=''' + @MatterDF02 + ''')
AND (ISNULL(''' + @MatterDF03 + ''', ''-1'') = ''-1'' OR ili.MatterDF03=''' + @MatterDF03 + ''')
AND (ISNULL(''' + @MatterDF04 + ''', ''-1'') = ''-1'' OR ili.MatterDF04=''' + @MatterDF04 + ''')
AND (ISNULL(''' + @MatterDF05 + ''', ''-1'') = ''-1'' OR ili.MatterDF05=''' + @MatterDF05 + ''')
AND (ISNULL(''' + @MatterDF06 + ''', ''-1'') = ''-1'' OR ili.MatterDF06=''' + @MatterDF06 + ''')
AND (ISNULL(''' + @MatterDF07 + ''', ''-1'') = ''-1'' OR ili.MatterDF07=''' + @MatterDF07 + ''')
AND (ISNULL(''' + @MatterDF08 + ''', ''-1'') = ''-1'' OR ili.MatterDF08=''' + @MatterDF08 + ''')
AND (ISNULL(''' + @MatterDF09 + ''', ''-1'') = ''-1'' OR ili.MatterDF09=''' + @MatterDF09 + ''')
AND (ISNULL(''' + @MatterDF10 + ''', ''-1'') = ''-1'' OR ili.MatterDF10=''' + @MatterDF10 + ''')
AND (ISNULL(''' + @MatterDF11 + ''', ''-1'') = ''-1'' OR ili.MatterDF11=''' + @MatterDF11 + ''')
AND (ISNULL(''' + @MatterDF12 + ''', ''-1'') = ''-1'' OR ili.MatterDF12=''' + @MatterDF12 + ''')
AND (ISNULL(''' + @MatterDF13 + ''', ''-1'') = ''-1'' OR ili.MatterDF13=''' + @MatterDF13 + ''')
AND (ISNULL(''' + @MatterDF14 + ''', ''-1'') = ''-1'' OR ili.MatterDF14=''' + @MatterDF14 + ''')
AND (ISNULL(''' + @MatterDF15 + ''', ''-1'') = ''-1'' OR ili.MatterDF15=''' + @MatterDF15 + ''')
AND (ISNULL(''' + @MatterDF16 + ''', ''-1'') = ''-1'' OR ili.MatterDF16=''' + @MatterDF16 + ''')
AND (ISNULL(''' + @MatterDF17 + ''', ''-1'') = ''-1'' OR ili.MatterDF17=''' + @MatterDF17 + ''')
AND (ISNULL(''' + @MatterDF18 + ''', ''-1'') = ''-1'' OR ili.MatterDF18=''' + @MatterDF18 + ''')
AND (ISNULL(''' + @MatterDF19 + ''', ''-1'') = ''-1'' OR ili.MatterDF19=''' + @MatterDF19 + ''')
AND (ISNULL(''' + @MatterDF20 + ''', ''-1'') = ''-1'' OR ili.MatterDF20=''' + @MatterDF20 + ''')
AND (ISNULL(''' + @MatterDF21 + ''', ''-1'') = ''-1'' OR ili.MatterDF21=''' + @MatterDF21 + ''')
AND (ISNULL(''' + @MatterDF22 + ''', ''-1'') = ''-1'' OR ili.MatterDF22=''' + @MatterDF22 + ''')
AND (ISNULL(''' + @MatterDF23 + ''', ''-1'') = ''-1'' OR ili.MatterDF23=''' + @MatterDF23 + ''')
AND (ISNULL(''' + @MatterDF24 + ''', ''-1'') = ''-1'' OR ili.MatterDF24=''' + @MatterDF24 + ''')
AND (ISNULL(''' + @MatterDF25 + ''', ''-1'') = ''-1'' OR ili.MatterDF25=''' + @MatterDF25 + ''')
GROUP BY
ili.MatterId
ORDER BY
SUM(ili.Amount * ISNULL(ex.ExchangeRate, 1)) desc'
 

Print @SQL
EXEC(@SQL)