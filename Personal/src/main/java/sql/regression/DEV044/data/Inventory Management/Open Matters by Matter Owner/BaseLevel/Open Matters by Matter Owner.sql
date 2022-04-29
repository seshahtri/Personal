--Open Matters by Matter Owner

--use DEV044_IOD_DataMart;

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
--SET @pDateStart='1/1/2017';
--SET @pDateEnd='12/31/2017';
--SET @InvoiceStatus = 'Paid'',''Processed';

SET @SQL=
'
		EXEC AS USER = ''admin''

		SELECT 
			--ms.MatterOwnerId,
			MAX(ins.MatterOwnerName) AS MatterOwnerName,
			ex.CurrencyCode CurrencyCode,
			COUNT (DISTINCT ms.MatterId) Matters,
			SUM (CASE WHEN ins.InvoiceStatus IN ('''+@InvoiceStatus+''') AND ins.InvoiceDate<= '''+ @pDateEnd+'''
					THEN ins.Amount * ISNULL(ex.ExchangeRate, 1) ELSE CAST(NULL AS FLOAT) END) Spend
		FROM V_MatterSummary ms
			INNER JOIN BusinessUnitAndAllDescendants bud ON ms.BusinessUnitId = bud.ChildBusinessUnitId
			INNER JOIN (
			SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
			FROM dbo.fn_GetRollupBusinessUnitsWithSecurity (''-1'', ''|'',-1,0)
						) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
			INNER JOIN PracticeAreaAndAllDescendants pad ON ms.PracticeAreaId = pad.ChildPracticeAreaId
			INNER JOIN (
			SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
			FROM dbo.fn_GetRollupPracticeAreasWithSecurity2 (''-1'', ''|'',-1,0)
						 ) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
			LEFT JOIN V_InvoiceSummary ins ON ms.MatterId = ins.MatterId
			LEFT JOIN ExchangeRateDim ex ON ins.ExchangeRateDate = ex.ExchangeRateDate
		WHERE 
		  ex.CurrencyCode = '''+@CurrencyCode+'''
		  AND ms.MatterStatus <> ''Closed''
		GROUP BY
			ms.MatterOwnerId,CurrencyCode
		ORDER BY Matters DESC
'
PRINT (@SQL)
EXEC(@SQL)