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
exec AS user=''admin''
SELECT 
	VendorName AS [Vendor Name],
	RoleName AS [Role Name],
	ER.CurrencyCode AS [Currency Code],
	COUNT(DISTINCT TimeKeeperID) AS [Timekeepers ],
	SUM(GrossFeeAmountForRates * ISNULL(ExchangeRate, 1)) AS [Spend ],
	SUM(HoursForRates) AS [Hours ]
FROM 	
	V_InvoiceTimeKeeperSummary ITS
JOIN (SELECT 
		TOP 1000 VendorId,
		SUM(GrossFeeAmountForRates * ISNULL(ExchangeRate, 1)) AS SpendByVendor
FROM 	V_InvoiceTimeKeeperSummary ITS
JOIN PracticeAreaAndAllDescendants PAD ON ITS.PracticeAreaId = PAD.ChildPracticeAreaId
JOIN (SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',-1,0)) PAS ON PAD.PracticeAreaID = PAS.RollupPracticeAreaId
JOIN BusinessUnitAndAllDescendants BAD ON ITS.BusinessUnitId = BAD.ChildBusinessUnitId
JOIN ( SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''-1'', ''|'',''-1'',0)) BAS ON BAD.BusinessUnitId = BAS.RollupBusinessUnitId
JOIN ExchangeRateDim ER ON ITS.ExchangeRateDate = ER.ExchangeRateDate
WHERE 
	TimeKeeperRoleID <> -1
	AND InvoiceStatus in ('''+@InvoiceStatus+''')
	AND InvoiceDate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
	AND ER.CurrencyCode = '''+@CurrencyCode+'''
	AND RoleName IS NOT NULL
	AND FeeRate <=2500
	AND (HoursForRates > 0 OR GrossFeeAmountForRates >0)
	AND (ISNULL(''' + @mattername + ''', ''-1'') = ''-1'' OR ITS.mattername=''' + @mattername + ''')
	  AND (ISNULL(''' + @MatterNumber + ''', ''-1'') = ''-1'' OR ITS.MatterNumber=''' + @MatterNumber + ''')
	  AND (ISNULL(''' + @MatterOwnerId + ''', ''-1'') = ''-1'' OR ITS.MatterOwnerId=''' + @MatterOwnerId + ''')
	   AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR ITS.MatterStatus=''' + @MatterStatus + ''')
	   AND (ISNULL(''' + @VendorId + ''', ''-1'') = ''-1'' OR ITS.VendorId=''' + @VendorId + ''')
	    AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR ITS.VendorType=''' + @VendorType + ''')
	    AND (ISNULL(''' + @PracticeAreaId + ''', ''-1'') = ''-1'' OR ITS.PracticeAreaId=''' + @PracticeAreaId + ''')
		AND (ISNULL(''' + @BusinessUnitId + ''', ''-1'') = ''-1'' OR ITS.BusinessUnitId=''' + @BusinessUnitId + ''')
		AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR ITS.MatterDF01=''' + @MatterDynamicField1 + ''')
        AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR ITS.MatterDF02=''' + @MatterDynamicField2 + ''')
		AND (ISNULL(''' + @MatterVendorDynamicField1 + ''', ''-1'') = ''-1'' OR ITS.MatterVendorDF01=''' + @MatterVendorDynamicField1 + ''')
        AND (ISNULL(''' + @MatterVendorDynamicField2 + ''', ''-1'') = ''-1'' OR ITS.MatterVendorDF02=''' + @MatterVendorDynamicField2 + ''') 

GROUP BY 	
	VendorId
ORDER BY SpendByVendor DESC) SPV ON ITS.VendorId = SPV.VendorId
JOIN PracticeAreaAndAllDescendants PAD ON ITS.PracticeAreaId = PAD.ChildPracticeAreaId
JOIN (SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',-1,0)) PAS ON PAD.PracticeAreaID = PAS.RollupPracticeAreaId
JOIN BusinessUnitAndAllDescendants BAD ON ITS.BusinessUnitId = BAD.ChildBusinessUnitId
JOIN ( SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''-1'', ''|'',''-1'',0)) BAS ON BAD.BusinessUnitId = BAS.RollupBusinessUnitId
JOIN ExchangeRateDim ER ON ITS.ExchangeRateDate = ER.ExchangeRateDate

WHERE 
	TimeKeeperRoleID <> -1
	AND InvoiceStatus in ('''+@InvoiceStatus+''')
	AND InvoiceDate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
	AND ER.CurrencyCode = '''+@CurrencyCode+'''
	AND RoleName IS NOT NULL
	AND FeeRate <=2500
	AND (HoursForRates > 0 OR GrossFeeAmountForRates >0) 
	AND (ISNULL(''' + @mattername + ''', ''-1'') = ''-1'' OR ITS.mattername=''' + @mattername + ''')
	  AND (ISNULL(''' + @MatterNumber + ''', ''-1'') = ''-1'' OR ITS.MatterNumber=''' + @MatterNumber + ''')
	  AND (ISNULL(''' + @MatterOwnerId + ''', ''-1'') = ''-1'' OR ITS.MatterOwnerId=''' + @MatterOwnerId + ''')
	   AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR ITS.MatterStatus=''' + @MatterStatus + ''')
	   AND (ISNULL(''' + @VendorId + ''', ''-1'') = ''-1'' OR ITS.VendorId=''' + @VendorId + ''')
	    AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR ITS.VendorType=''' + @VendorType + ''')
	    AND (ISNULL(''' + @PracticeAreaId + ''', ''-1'') = ''-1'' OR ITS.PracticeAreaId=''' + @PracticeAreaId + ''')
		AND (ISNULL(''' + @BusinessUnitId + ''', ''-1'') = ''-1'' OR ITS.BusinessUnitId=''' + @BusinessUnitId + ''')
		AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR ITS.MatterDF01=''' + @MatterDynamicField1 + ''')
        AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR ITS.MatterDF02=''' + @MatterDynamicField2 + ''')
		AND (ISNULL(''' + @MatterVendorDynamicField1 + ''', ''-1'') = ''-1'' OR ITS.MatterVendorDF01=''' + @MatterVendorDynamicField1 + ''')
        AND (ISNULL(''' + @MatterVendorDynamicField2 + ''', ''-1'') = ''-1'' OR ITS.MatterVendorDF02=''' + @MatterVendorDynamicField2 + ''') 

GROUP BY 	
	VendorName,
	RoleName,
	ER.CurrencyCode, 
	SpendByVendor
ORDER BY 
	SpendByVendor DESC, 
	CASE WHEN RoleName =''Senior Partner'' THEN ''1''
	WHEN RoleName = ''Lead Partner'' THEN ''2''
	WHEN RoleName = ''Partner'' THEN ''3''
	WHEN RoleName = ''Of Counsel'' THEN ''4''
	WHEN RoleName = ''Associate'' THEN ''5''
	WHEN RoleName = ''Paralegal'' THEN ''6''
	WHEN RoleName = ''Support'' THEN ''7''
	WHEN RoleName = ''Other'' THEN ''8''
ELSE RoleName END ASC
'
print(@SQL)
EXEC(@SQL)
