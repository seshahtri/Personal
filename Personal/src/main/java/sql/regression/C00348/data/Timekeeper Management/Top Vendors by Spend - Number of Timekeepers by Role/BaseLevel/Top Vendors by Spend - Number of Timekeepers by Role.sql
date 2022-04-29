       --Client name - C00348
   -- DashBoard name - Timekeeper Management
         -- Viz name - Top Vendors by Spend - Number of Timekeepers by Role	
            -- Level - Base Level

--use C00348_IOD_DataMart;


DECLARE @CurrencyCode  varchar (50);
DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @InvoiceStatus varchar (MAX);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;

--SET @pDateStart='01/01/2021';
--SET @pDateEnd='04/30/2022';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';

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
JOIN (SELECT top 100000
		 VendorId,
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
	AND PaymentDate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
	AND ER.CurrencyCode = '''+@CurrencyCode+'''
	AND RoleName IS NOT NULL
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
	AND PaymentDate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
	AND ER.CurrencyCode = '''+@CurrencyCode+'''
	AND RoleName IS NOT NULL
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
	WHEN RoleName = ''Legal Assistant'' THEN ''6''
	WHEN RoleName = ''Paralegal'' THEN ''7''
	WHEN RoleName = ''Billing Administrator'' THEN ''8''
	WHEN RoleName = ''Other'' THEN ''9''
ELSE RoleName END ASC




'
print(@SQL)
EXEC(@SQL)
