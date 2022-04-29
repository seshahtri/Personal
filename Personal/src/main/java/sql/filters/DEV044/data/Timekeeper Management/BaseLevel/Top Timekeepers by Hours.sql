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
--SET @DateField=REPLACE('Invoice Date',' ','');
--SET @MatterName='-1';--'Matter 3686999';
--SET @MatterNumber='-1';
--SET @MatterStatus='-1';
--SET @MatterOwnerName ='-1';--'clavin, cliff';
--SET  @VendorName='-1';---'Ackerman, Bell and calder ';
--SET  @VendorType ='-1';--'Law Firm';
--SET  @PracticeAreaName ='-1';--'Corporate';
--SET  @BusinessUnitName='-1';--'International';
--SET @MatterDynamicField1='-1';--'Unspecified';
--SET @MatterDynamicField2='-1';
--SET @MatterVendorDynamicField1='-1';--'Unspecified';
--SET @MatterVendorDynamicField2='-1';

SET @PracticeAreaId = ISNULL((SELECT TOP 1 p.PracticeAreaId FROM PracticeAreaDim p WHERE p.PracticeAreaName = @PracticeAreaName),-1)
SET @BusinessUnitId = ISNULL((SELECT TOP 1 b.BusinessUnitId FROM BusinessUnitDim b where b.BusinessUnitName = @BusinessUnitName),-1)

SET @SQL='
   EXEC AS USER =''admin''
	SELECT
		MIN(ili.TimekeeperName) as ''Timekeeper Name'',
		MIN(ili.VendorParentName) as ''Vendor Name'',
		MIN(ili.RoleName) as ''Role Name'',
		MIN(ex.CurrencyCode) as ''Currency Code'',
		SUM(ili.HoursForRates) as ''Hours'',
		SUM(ili.GrossFeeAmountForRates * ISNULL(ex.ExchangeRate, 1)) as ''Fees''
	FROM V_InvoiceTimekeeperSummary ili
		INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId
		INNER JOIN (
			SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
			FROM fn_GetRollupPracticeAreasWithSecurity ('''+@PracticeAreaId+''', ''|'',-1,0)
					) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
		INNER JOIN BusinessUnitAndAllDescendants bud ON ili.BusinessUnitId = bud.ChildBusinessUnitId
		INNER JOIN (
			SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
			FROM fn_GetRollupBusinessUnitsWithSecurity2 ('''+@BusinessUnitId+''', ''|'',-1,0)
					) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
		INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate
	WHERE
		ili.InvoiceStatus IN (''' + @InvoiceStatus + ''')
		AND ex.CurrencyCode = ''' + @CurrencyCode + '''
		AND (ili.'+@DateField+' >= ''' + @pDateStart + ''' AND ili.InvoiceDate<= ''' + @pDateEnd + ''')
		AND ili.HoursForRates>0
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
AND (ISNULL(''' + @VendorName + ''', ''-1'') = ''-1'' OR VendorName=''' + @VendorName + ''')
AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR VendorType=''' + @VendorType + ''')
	
	GROUP BY
		ili.TimekeeperId,
		ili.TimekeeperRoleId
	ORDER BY
		SUM(ili.HoursForRates) desc'

Print @SQL
EXEC(@SQL)