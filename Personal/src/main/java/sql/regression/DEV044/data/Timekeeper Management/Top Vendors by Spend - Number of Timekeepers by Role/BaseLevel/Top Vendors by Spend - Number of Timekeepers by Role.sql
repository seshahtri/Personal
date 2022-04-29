DECLARE @CurrencyCode  varchar (50);
DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @InvoiceStatus varchar (MAX);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @CurrencyCode= ^Currency^;
SET @InvoiceStatus= ^InvoiceStatus^;

--SET @CurrencyCode ='USD';
--SET @pDateStart='01/01/2017'; 
--SET @pDateEnd ='12/31/2017';
--SET @InvoiceStatus ='Paid'',''Processed';

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
