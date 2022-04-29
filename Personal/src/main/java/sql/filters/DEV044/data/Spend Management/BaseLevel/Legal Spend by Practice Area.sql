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
Select 
	pa.RollupPracticeAreaName as ''Practice Area '',
	ed.CurrencyCode as ''Currency Code'', 
	Sum(invs.Amount*ISNULL(ed.ExchangeRate,1)) as ''Total Spend''
from V_InvoiceSummary invs
	join ExchangeRateDim ed on ed.ExchangeRateDate = invs.ExchangeRateDate
	INNER JOIN BusinessUnitAndAllDescendants B on b.childbusinessunitid=invs.BusinessUnitId
	INNER JOIN 
			  (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
			   FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] ('''+ @BusinessUnitId +''', ''|'',-1,0)) ba on ba.RollupBusinessUnitId=b.BusinessUnitId
	INNER JOIN PracticeAreaAndAllDescendants P on P.ChildPracticeAreaId=invs.PracticeAreaId
	INNER JOIN 
			 (
			  SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
		      FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''' + @PracticeAreaId +''', ''|'',-1,1)) pa on pa.RollupPracticeAreaId=p.PracticeAreaId
WHERE 
    invs.InvoiceStatus IN (''' + @InvoiceStatus + ''')
	AND (invs.'+@DateField+' between ''' + @pDateStart + ''' and ''' + @pDateEnd + ''')
	AND ed.CurrencyCode = ''' + @CurrencyCode + '''
	AND (ISNULL(''' + @MatterName + ''', ''-1'') = ''-1'' OR MatterName=''' + @MatterName + ''')
	AND (ISNULL(''' + @MatterNumber + ''', ''-1'') = ''-1'' OR MatterNumber=''' + @MatterNumber + ''')
	AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR
CASE WHEN MatterCloseDate IS NULL THEN ''Open''
WHEN MatterCloseDate > ''' + @pDateEnd + ''' THEN ''Open''
ELSE ''Closed'' END =''' + @MatterStatus + ''')
	AND (ISNULL(''' + @MatterOwnerName + ''', ''-1'') = ''-1'' OR MatterOwnerName=''' + @MatterOwnerName + ''')
AND (ISNULL(''' + @VendorName + ''', ''-1'') = ''-1'' OR VendorName=''' + @VendorName + ''')
AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR VendorType=''' + @VendorType + ''')
AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR VendorType=''' + @MatterDynamicField1 + ''')
AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR VendorType=''' + @MatterDynamicField2 + ''')
AND (ISNULL(''' + @MatterVendorDynamicField1 + ''', ''-1'') = ''-1'' OR VendorType=''' + @MatterVendorDynamicField1 + ''')
AND (ISNULL(''' + @MatterVendorDynamicField2 + ''', ''-1'') = ''-1'' OR VendorType=''' + @MatterVendorDynamicField2 + ''')

GROUP BY pa.RollupPracticeAreaName,ed.CurrencyCode
ORDER BY [Total Spend] desc
'
Print @SQL
EXEC(@SQL)