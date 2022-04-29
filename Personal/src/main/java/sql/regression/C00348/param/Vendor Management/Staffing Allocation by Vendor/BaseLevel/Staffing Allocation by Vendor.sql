--USE DEV044_IOD_DataMart;
DECLARE @CurrencyCode varchar (50);
DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @InvoiceStatus varchar (MAX);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @CurrencyCode= ^Currency^;
SET @InvoiceStatus= ^InvoiceStatus^;

--SET @CurrencyCode ='USD';
--SET @pDateStart='03/01/2021';
--SET @pDateEnd ='02/28/2022';
--SET @InvoiceStatus ='Paid'',''Processed';

SET @SQL = '
	exec as user = ''admin''
	SELECT
		Top 1 ili.VendorId,
		MIN(ili.VendorName) as [Vendor Name],
		ili.RoleName as [Role Name],
		MIN(ex.CurrencyCode) as [Currency Code],
		(SUM(ili.HoursForRates)/(CASE WHEN vs.VendorHours=0 THEN NULL ELSE vs.VendorHours END)*100) as [% Hours Billed],
		SUM(ili.HoursForRates) as [Hours],
		vs.VendorHours as [Total Hours],
		SUM((ili.GrossFeeAmountForRates) * ISNULL(ex.ExchangeRate, 1)) as [Spend]
		--vs.VendorSpend
	FROM V_InvoiceTimekeeperSummary ili
	INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId
	INNER JOIN (
		SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
		FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',-1,0)
		) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
	INNER JOIN BusinessUnitAndAllDescendants bud ON ili.BusinessUnitId = bud.ChildBusinessUnitId
	INNER JOIN (
		SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
		FROM fn_GetRollupBusinessUnitsWithSecurity (-1, ''|'',-1,0)
		) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
	INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate
	JOIN (
		SELECT
			ili.VendorId,
			SUM(ili.HoursForRates) VendorHours,
			SUM((ili.GrossFeeAmountForRates) * ISNULL(ex.ExchangeRate, 1)) VendorSpend
		FROM V_InvoiceTimekeeperSummary ili
		INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId
		INNER JOIN (
		SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
		FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',-1,0)
		) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
		INNER JOIN BusinessUnitAndAllDescendants bud ON ili.BusinessUnitId = bud.ChildBusinessUnitId
		INNER JOIN (
		SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
		FROM fn_GetRollupBusinessUnitsWithSecurity (-1, ''|'',-1,0)
		) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
		INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate
		WHERE
			ili.InvoiceStatus IN ('''+@InvoiceStatus+''')
			AND ex.CurrencyId = 1
			AND (ili.paymentdate >='''+@pDateStart+''' AND ili.paymentdate<= '''+@pDateEnd+''')
			AND ili.RoleName IS NOT NULL
			AND ili.FeeRate<=2500
			AND (ili.HoursForRates > 0 OR ili.GrossFeeAmountForRates > 0)
		GROUP BY
			ili.VendorId
		) vs on vs.VendorId=ili.VendorId
	WHERE
		ili.InvoiceStatus IN ('''+@InvoiceStatus+''')
		AND ex.CurrencyId = 1
		AND (ili.paymentdate >='''+@pDateStart+''' AND ili.paymentdate<= '''+@pDateEnd+''')
		AND ili.RoleName IS NOT NULL
		AND ili.FeeRate<=2500
		AND (ili.HoursForRates > 0 OR ili.GrossFeeAmountForRates > 0)
	GROUP BY
		ili.VendorId,
		vs.VendorHours,
		ili.RoleName,
		vs.VendorSpend
	ORDER BY
		vs.VendorSpend desc,
		CASE WHEN ili.RoleName=''Partner'' THEN 1
			WHEN ili.RoleName=''Associate'' THEN 2
			WHEN ili.RoleName=''Paralegal'' THEN 3
			WHEN ili.RoleName=''Of Counsel'' THEN 4
		ELSE 5
		END
	'
PRINT(@SQL)
EXEC(@SQL)
