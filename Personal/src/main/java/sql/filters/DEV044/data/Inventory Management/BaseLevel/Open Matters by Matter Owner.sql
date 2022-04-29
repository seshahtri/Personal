--Open Matters by Matter Owner

--use DEV044_IOD_DataMart;

DECLARE @CurrencyCode varchar (50);
DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @DateField varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @InvoiceStatus varchar (MAX);
DECLARE @MatterName varchar (1000);
DECLARE @MatterOwnerName varchar (1000);
DECLARE @MatterNumber varchar (1000);
DECLARE @MatterStatus varchar (1000);
DECLARE @PracticeAreaName varchar (1000);
DECLARE @PracticeAreaId varchar(1000);
DECLARE @BusinessUnitName varchar (1000);
DECLARE @BusinessUnitId varchar(100);
DECLARE @MatterDynamicField1 varchar (1000);
DECLARE @MatterDynamicField2 varchar (1000);
DECLARE @MatterVendorDynamicField1 varchar (1000);
DECLARE @MatterVendorDynamicField2 varchar (1000);
DECLARE @MatterDF01 varchar (1000);
DECLARE @MatterDF02 varchar (1000);
DECLARE @MatterownerId varchar (1000);
DECLARE @VendorName varchar (1000);
DECLARE @VendorType varchar (1000);

SET @pDateStart=^StartDate^;
SET @pDateEnd=^EndDate^;
SET @InvoiceStatus=^InvoiceStatus^;
SET @CurrencyCode=^Currency^;
SET @DateField=^InvoiceDate^;
SET @MatterName=^MatterName^;
SET @MatterNumber=^MatterNumber^;
SET @MatterStatus=^MatterStatus^;
SET @MatterOwnerName=^MatterOwner^;;
SET @PracticeAreaName=^PracticeArea^;
SET @BusinessUnitName=^BusinessUnit^;
SET @MatterDynamicField1= ^DFMatterDynamicField1^;
SET @MatterDynamicField2= ^DFMatterDynamicField2^;
SET @MatterVendorDynamicField1=^DFMatterVendorDynamicField1^;
SET @MatterVendorDynamicField2=^DFMatterVendorDynamicField2^;
SET @VendorName= ^VendorName^;
SET @VendorType= ^VendorType^;


--SET @CurrencyCode ='USD';
--SET @pDateStart='2017-01-01';
--SET @pDateEnd ='2017-12-31';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @MatterName='-1';
--SET @MatterNumber='-1';
--SET @MatterOwnerName='-1';
--SET @MatterDynamicField1='-1';
--SET @MatterDynamicField2='-1';
--SET @MatterStatus='-1';
--SET @PracticeAreaName ='-1';
--SET @BusinessUnitName='-1';
--SET @MatterName='Matter 3686999';
--SET @MatterStatus='Closed';
--SET @PracticeAreaName ='Employment and Labor';
--SET @BusinessUnitName='International';
--SET @MatterNumber='1155280';
--SET @MatterOwnerName='Halpert, Jim'
--SET @MatterDynamicField1='Unspecified';
--SET @MatterDynamicField2='Unspecified';



SET @PracticeAreaId = ISNULL((SELECT TOP 1 p.PracticeAreaId FROM PracticeAreaDim p WHERE p.PracticeAreaName = @PracticeAreaName),-1)
SET @BusinessUnitId = ISNULL((SELECT TOP 1 b.BusinessUnitId FROM BusinessUnitDim b where b.BusinessUnitName = @BusinessUnitName),-1)
SET @MatterownerId = ISNULL((SELECT TOP 1 d.timekeeperid FROM timekeeperdim d WHERE d.fullname = @MatterOwnerName),-1)

SET @SQL=
'
		EXEC AS USER = ''admin''

	

			SELECT 
			--ms.MatterOwnerId,
			MAX(ins.MatterOwnerName) AS MatterOwnerName,
			min(ex.CurrencyCode) CurrencyCode,
			COUNT (DISTINCT ms.MatterId) Matters,
			SUM (CASE WHEN ins.InvoiceStatus IN ('''+@InvoiceStatus+''') AND ins.InvoiceDate<= '''+ @pDateEnd+'''
					THEN ins.Amount * ISNULL(ex.ExchangeRate, 1) ELSE CAST(NULL AS FLOAT) END) Spend
		FROM dbo.V_MatterSummary ms
			INNER JOIN dbo.BusinessUnitAndAllDescendants bud ON (ms.BusinessUnitId = bud.ChildBusinessUnitId)
			INNER JOIN (
			SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
			FROM dbo.fn_GetRollupBusinessUnitsWithSecurity ('''+ @BusinessUnitId +''', ''|'',-1,0)
						) bu ON (bud.BusinessUnitId = bu.RollupBusinessUnitId)
			INNER JOIN dbo.PracticeAreaAndAllDescendants pad ON (ms.PracticeAreaId = pad.ChildPracticeAreaId)
			INNER JOIN (
			SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
			FROM dbo.fn_GetRollupPracticeAreasWithSecurity2  (''' + @PracticeAreaId +''', ''|'',-1,0)
						 ) pa ON (pad.PracticeAreaId = pa.RollupPracticeAreaId)
			LEFT JOIN dbo.V_InvoiceSummary ins ON (ms.MatterId = ins.MatterId)
			LEFT JOIN dbo.ExchangeRateDim ex ON (ins.ExchangeRateDate = ex.ExchangeRateDate)
		WHERE 
		  --ex.CurrencyId IS NULL OR (ex.CurrencyId = 1)
		  --ex.CurrencyCode = '''+@CurrencyCode+'''
		  (((CASE WHEN (ex.[CurrencyId] = 1) THEN 1 WHEN NOT (ex.[CurrencyId] = 1) THEN 0 ELSE NULL END) IS NULL)
OR (ex.[CurrencyId] = 1))

		  AND ms.MatterStatus <> ''Closed''

		   AND (ISNULL('''+@MatterName +''', ''-1'') = ''-1'' OR ms.MatterName='''+ @MatterName +''')
		  AND (ISNULL('''+@MatterNumber +''', ''-1'') = ''-1'' OR ms.MatterNumber='''+ @MatterNumber +''')
		  AND (ISNULL('''+@MatterOwnerId +''', ''-1'') = ''-1'' OR ms.MatterownerId='''+ @MatterOwnerId +''')
		  AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR ms.MatterDF01=''' + @MatterDynamicField1 + ''')
		  AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR ms.MatterDF02=''' + @MatterDynamicField2 + ''')

		GROUP BY
			ms.MatterOwnerId--,CurrencyCode
		ORDER BY Matters DESC,matterownername desc

'
PRINT (@SQL)
EXEC(@SQL)