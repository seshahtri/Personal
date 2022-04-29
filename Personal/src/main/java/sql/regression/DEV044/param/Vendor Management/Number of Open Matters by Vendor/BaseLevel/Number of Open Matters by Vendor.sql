--Open Matters by Vendor

EXECUTE AS USER='Admin'

DECLARE @pDateStart varchar (MAX);
DECLARE @pDateEnd  varchar (MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @CurrencyCode varchar (50);
DECLARE @CurrencyId varchar;
DECLARE @InvoiceStatus varchar (MAX);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @CurrencyCode= ^Currency^;
--SET @InvoiceStatus= ^InvoiceStatus^;

--SET @pDateStart='01/01/2017';
--SET @pDateEnd ='12/31/2017';
--SET @CurrencyCode ='USD';
SET @InvoiceStatus ='''Paid'',''Processed''';
SET @SQL=
'
		EXEC AS USER = ''admin''

		SELECT Top 1
			mv.VendorId,
			mv.VendorName,
			mv.VendorType,
			ex.Currencycode,
			COUNT (DISTINCT MATTERID) [Open Matters],
			SUM (CASE WHEN mv.InvoiceStatus IN ('+@InvoiceStatus+') AND convert(varchar,mv.InvoiceDate,101)<='''+ @pDateEnd+'''
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


--select {d '2017-12-31'},FORMAT(mv.InvoiceDate,'yyyy-MM-dd'),convert(date,mv.InvoiceDate)  FROM V_MatterVendorSpendSummary mv

--select convert(varchar,mv.InvoiceDate,101) FROM V_MatterVendorSpendSummary mv