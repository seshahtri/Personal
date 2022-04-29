--Open Matters by Vendor

EXECUTE AS USER='Admin'

DECLARE @pDateStart varchar (MAX);
DECLARE @pDateEnd  varchar (MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @CurrencyCode varchar (50);
DECLARE @CurrencyId varchar;
DECLARE @InvoiceStatus varchar (MAX);

SET @pDateStart= ^StartDate^;
--SET @pDateEnd= ^EndDate^;
SET @CurrencyCode= ^Currency^;
--SET @InvoiceStatus= ^InvoiceStatus^;

--SET @pDateStart='2017-01-01';
SET @pDateEnd ='2017-12-31';
--SET @CurrencyCode ='USD';
SET @InvoiceStatus ='''Paid'',''Processed''';
SET @SQL=
'
		EXEC AS USER = ''admin''

		SELECT 
			
			mv.VendorName,
			mv.VendorType,
			ex.Currencycode,
			COUNT (DISTINCT MATTERID) [Open Matters],
			SUM (CASE WHEN mv.InvoiceStatus IN ('+@InvoiceStatus+') AND cast(mv.InvoiceDate as date)<=cast({d '''+ @pDateEnd+'''} as date)
			--SUM (CASE WHEN mv.InvoiceStatus IN ('+@InvoiceStatus+') AND (mv.InvoiceDate)<={d '''+ @pDateEnd+'''}
			--SUM (CASE WHEN mv.InvoiceStatus IN ('+@InvoiceStatus+') AND Convert(datetime2,mv.InvoiceDate,103)<={d '''+ @pDateEnd+'''}
			--SUM (CASE WHEN mv.InvoiceStatus IN ('+@InvoiceStatus+') AND Convert(datetime2,mv.InvoiceDate,23)<={d '''+ @pDateEnd+'''}
			--convert(varchar, getdate(), 23)
					THEN mv.Amount * ISNULL(ex.ExchangeRate, 1) ELSE CAST(NULL AS FLOAT) END) LOMSpend
		FROM V_MatterVendorSpendSummary mv
			INNER JOIN BusinessUnitAndAllDescendants bud ON mv.BusinessUnitId = bud.ChildBusinessUnitId
			INNER JOIN (
			SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
			FROM dbo.fn_GetRollupBusinessUnitsWithSecurity (''-1'', ''|'',-1,0)
						) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
			INNER JOIN PracticeAreaAndAllDescendants pad ON mv.PracticeAreaId = pad.ChildPracticeAreaId
			LEFT JOIN ExchangeRateDim ex ON mv.ExchangeRateDate = ex.ExchangeRateDate
			INNER JOIN (
			SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
			FROM dbo.fn_GetRollupPracticeAreasWithSecurity2 (''-1'', ''|'',-1,0)
						 ) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
		WHERE 
		  ex.CurrencyId = 1
		  AND mv.VendorType <> ''Client''
		  AND mv.MatterStatus <> ''Closed''
		GROUP BY
			mv.VendorId,
			mv.VendorName,
			mv.VendorType,
			ex.Currencycode
		ORDER BY [open Matters] DESC
'
PRINT (@SQL)
EXEC(@SQL)