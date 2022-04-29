--USE Q5_C00348_IOD_DataMart

EXEC AS USER ='admin'

DECLARE @pDateStart varchar (50);
DECLARE @pDateEnd varchar (50);
DECLARE @InvoiceStatus nvarchar (1000);
DECLARE @CurrencyCode varchar (50);
DECLARE @SQL VARCHAR(4000);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;

--SET @pDateStart='1/1/2018';
--SET @pDateEnd='12/31/2021';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';
--SET @Category='Fee';

SET @SQL='
	SELECT  Top 1000
		MIN(ili.MatterName) as ''Matter Name'',
		MIN(ili.MatterDF03) as ''Coverage Type'',
		MIN(ili.MatterNumber) as ''Matter Number'',
		MIN(ili.MatterDF07) as ''Claim Number'',
		MIN(ili.MatterDF08) as ''GB Branch Name'',
		MIN(ili.MatterDF09) as ''GB Branch Number'',
		MIN(ili.PracticeAreaName) as ''GB Client'',
		MIN(ili.MatterOwnerName) as ''Matter Owner Name'',
		MIN(ili.MatterDF06) as ''Status Code'',
		MIN(ili.MatterStatus) as ''Matter Status'',
		MIN(ex.CurrencyCode) as ''Currency Code'',
		SUM(ili.Amount * ISNULL(ex.ExchangeRate, 1)) as ''Spend''
	FROM V_InvoiceSummary ili
		INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId
		INNER JOIN (
			SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
			--FROM fn_GetRollupPracticeAreasWithSecurity2 (''-1'', ''|'',42684,0)
			FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',^ParamTwo^,0)
					) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
		INNER JOIN BusinessUnitAndAllDescendants bud ON ili.BusinessUnitId = bud.ChildBusinessUnitId
		INNER JOIN (
			SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
			FROM fn_GetRollupBusinessUnitsWithSecurity (-1, ''|'',^ParamOne^,0)
					) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
		INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate
	WHERE
		ili.InvoiceStatus IN (''' + @InvoiceStatus + ''')
		AND ex.CurrencyCode = ''' + @CurrencyCode + ''' 
		AND (ili.PaymentDate >= ''' + @pDateStart + ''' AND ili.PaymentDate<= ''' + @pDateEnd + ''')
	GROUP BY
		ili.MatterId
	ORDER BY
		SUM(ili.Amount * ISNULL(ex.ExchangeRate, 1)) desc'

Print @SQL
EXEC(@SQL)