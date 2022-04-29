--USE C00348_IOD_DataMart;

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
--SET @pDateStart='3/1/2021';
--SET @pDateEnd='2/28/2022';
--SET @InvoiceStatus = 'Paid'',''Processed';


SET @SQL = '
EXEC AS USER=''admin''

SELECT
	--ili.MatterId,
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
	SUM(ili.GrossFeeAmount * ISNULL(ex.ExchangeRate, 1)) as ''Spend''
FROM V_InvoiceTimekeeperSummary ili
	INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId
	INNER JOIN (
		SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
		FROM fn_GetRollupPracticeAreasWithSecurity2 (''-1'', ''|'',-1,0)
				) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
	INNER JOIN BusinessUnitAndAllDescendants bud ON ili.BusinessUnitId = bud.ChildBusinessUnitId
	INNER JOIN (
		SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
		FROM fn_GetRollupBusinessUnitsWithSecurity (''-1'', ''|'',-1,0)
				) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
	INNER JOIN ExchangeRateDim ex ON ili.ExchangeRateDate = ex.ExchangeRateDate 
	WHERE
	ili.InvoiceStatus IN ('''+@InvoiceStatus+''')
	AND ex.CurrencyCode = '''+@CurrencyCode+''' 
	AND (ili.PaymentDate >= '''+@pDateStart+''' AND ili.PaymentDate<= '''+@pDateEnd+''') 
	--and ili.RoleId = 30647
	--and ili.TimekeeperId = 816992
	and ili.RoleId = ^ParamOne^
	and ili.TimekeeperId = ^ParamTwo^
	--and ili.mattername like ''%YALI, KEVIN vs. Constellis Holdings, LLC-017300%''
	GROUP BY
	ili.MatterId
ORDER BY
	SUM(ili.Amount * ISNULL(ex.ExchangeRate, 1)) desc
'
print(@SQL);
Exec(@SQL);