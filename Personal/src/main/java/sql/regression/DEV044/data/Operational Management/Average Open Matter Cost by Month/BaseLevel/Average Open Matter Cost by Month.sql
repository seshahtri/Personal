--Average Open Matter Cost by Month

DECLARE @pDateStart varchar (MAX);
DECLARE @pDateEnd  varchar (MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @CurrencyCode varchar (50);
DECLARE @CurrencyId varchar;
DECLARE @InvoiceStatus varchar (MAX);

--SET @pDateStart= ^StartDate^;
--SET @pDateEnd= ^EndDate^;
--SET @CurrencyCode= ^Currency^;
--SET @InvoiceStatus= ^InvoiceStatus^;

SET @pDateStart='2017-01-01';
SET @pDateEnd ='2017-12-31';
SET @CurrencyCode ='USD';
SET @InvoiceStatus ='''Paid'',''Processed''';

SET @SQL=
'

		EXECUTE AS USER=''Admin''
		SELECT 
			YEAR (i.InvoiceDate) Year,
			case 
when MONTH(i.InvoiceDate) = 1 then ''January ''
when MONTH(i.InvoiceDate) = 2 then ''Febuary ''
when MONTH(i.InvoiceDate) = 3 then ''March ''
when MONTH(i.InvoiceDate) = 4 then ''April ''
when MONTH(i.InvoiceDate) = 5 then ''May ''
when MONTH(i.InvoiceDate) = 6 then ''June ''
when MONTH(i.InvoiceDate) = 7 then ''July ''
when MONTH(i.InvoiceDate) = 8 then ''August ''
when MONTH(i.InvoiceDate) = 9 then ''September ''
when MONTH(i.InvoiceDate) = 10 then ''October ''
when MONTH(i.InvoiceDate) = 11 then ''November ''
when MONTH(i.InvoiceDate) = 12 then ''December ''
end as Month,
			--MONTH(i.InvoiceDate) Month,
			MIN(ex.CurrencyCode) AS [Currency Code],
			COUNT(DISTINCT i.MatterId) [Open Matters],
			COUNT(DISTINCT I.InvoiceId) Invoices,  
			SUM(I.NetFeeAmount  * ISNULL(ex.ExchangeRate, 1)) Fees, 
			SUM(I.NetExpAmount * ISNULL(ex.ExchangeRate, 1)) Expenses,
			SUM(i.Amount * ISNULL(ex.ExchangeRate, 1)) Spend,  
			SUM(i.Amount * ISNULL(ex.ExchangeRate, 1)) / COUNT_BIG(DISTINCT (CASE WHEN ((((DATEPART(year,i.[MatterOpenDate]) * 100) + DATEPART(month,i.[MatterOpenDate])) <= ((DATEPART(year,i.[InvoiceDate]) * 100) + DATEPART(month,i.[InvoiceDate]))) AND ((i.[MatterCloseDate] IS NULL) OR (((DATEPART(year,i.[MatterCloseDate]) * 100) + DATEPART(month,i.[MatterCloseDate])) >= ((DATEPART(year,i.[InvoiceDate]) * 100) + DATEPART(month,i.[InvoiceDate]))))) THEN (i.[MatterId]) ELSE CAST(NULL AS BIGINT) END)) AS [Avg Cost]
		FROM V_InvoiceSummary i
			INNER JOIN BusinessUnitAndAllDescendants bud ON i.BusinessUnitId = bud.ChildBusinessUnitId
			INNER JOIN (
			SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
			FROM dbo.fn_GetRollupBusinessUnitsWithSecurity (''-1'', ''|'',-1,0)
						) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
			INNER JOIN PracticeAreaAndAllDescendants pad ON i.PracticeAreaId = pad.ChildPracticeAreaId
			INNER JOIN (
			SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
			FROM dbo.fn_GetRollupPracticeAreasWithSecurity2 (''-1'', ''|'',-1,0)
							) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
			JOIN ExchangeRateDim ex ON i.ExchangeRateDate = ex.ExchangeRateDate
		WHERE i.InvoiceStatus in ('+@InvoiceStatus+') 
			AND (i.InvoiceDate >= '''+@pDateStart+''' AND i.InvoiceDate<= '''+@pDateEnd+''')
			AND ex.CurrencyId =1
			AND((DATEPART(year,i.MatterOpenDate) * 100) + DATEPART(month,i.MatterOpenDate)) <= ((DATEPART(year,i.InvoiceDate) * 100) + DATEPART(month,i.InvoiceDate)) 
					AND (i.MatterCloseDate IS NULL OR ((DATEPART(year,i.MatterCloseDate) * 100) + DATEPART(month,i.MatterCloseDate)) >= ((DATEPART(year,i.InvoiceDate) * 100) + DATEPART(month,i.InvoiceDate)))
		GROUP BY
		YEAR (i.InvoiceDate),
		MONTH(i.InvoiceDate)
'
PRINT (@SQL)
EXEC(@SQL)