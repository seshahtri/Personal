
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
--SET @pDateStart='5/1/2021';
--SET @pDateEnd='4/30/2022';
--SET @InvoiceStatus = 'Paid'',''Processed';

SET @SQL=
'
		EXEC AS USER = ''admin''

		SELECT 
		TOP 1
			ms.MatterOwnerId,
			MAX(ins.MatterOwnerName) AS MatterOwnerName,
			min(ex.CurrencyCode) CurrencyCode,
			COUNT (DISTINCT ms.MatterId) Matters,


			SUM (CASE WHEN ins.InvoiceStatus IN ('''+@InvoiceStatus+''') AND ins.PaymentDate<= '''+ @pDateEnd+'''
					THEN ins.Amount * ISNULL(ex.ExchangeRate, 1) ELSE CAST(NULL AS FLOAT) END) Spend
		FROM V_MatterSummary ms

			LEFT JOIN V_InvoiceSummary ins ON ms.MatterId = ins.MatterId
			LEFT JOIN ExchangeRateDim ex ON ins.ExchangeRateDate = ex.ExchangeRateDate

			INNER JOIN BusinessUnitAndAllDescendants bud ON ms.BusinessUnitId = bud.ChildBusinessUnitId
			INNER JOIN (
			SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
			FROM dbo.fn_GetRollupBusinessUnitsWithSecurity (''-1'', ''|'',-1,0)
						) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
			INNER JOIN PracticeAreaAndAllDescendants pad ON ms.PracticeAreaId = pad.ChildPracticeAreaId
			INNER JOIN (
			SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
			FROM dbo.fn_GetRollupPracticeAreasWithSecurity2 (''-1'', ''|'',-1,1)
						 ) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId

			
		WHERE 
		 -- ex.CurrencyCode = '''+@CurrencyCode+''',
		  (((CASE WHEN (ex.[CurrencyId] = 1) THEN 1 WHEN NOT (ex.[CurrencyId] = 1) THEN 0 ELSE NULL END) IS NULL) OR (ex.[CurrencyId] = 1))
		  AND ms.MatterStatus <> ''Closed''

		  
		GROUP BY
			ms.MatterOwnerId
		ORDER BY Matters DESC
'
PRINT (@SQL)
EXEC(@SQL)