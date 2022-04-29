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

--SET @pDateStart='03/1/2021';
--SET @pDateEnd='02/28/2022';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';

SET @SQL = '

exec as user = ''admin''
SELECT 
    VendorName as [Vendor Name], 
    CurrencyCode as [Currency Code],
    SUM(GrossFeeAmountForRates) / SUM(HoursForRates)  [Blended Avg. Rate],
  	SUM(GrossFeeAmountForRates) Fees,
    SUM(HoursForRates) Hours
FROM V_InvoiceTimeKeeperSummary ITKS
JOIN PracticeAreaAndAllDescendants PAD ON ITKS.PracticeAreaId = PAD. ChildPracticeAreaId
JOIN (SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
   FROM fn_GetRollupPracticeAreasWithSecurity2 (''-1'', ''|'',-1,0)) PAS ON PAD.PracticeAreaId = PAS.RollupPracticeAreaId
JOIN BusinessUnitAndAllDescendants BAD ON ITKS.BusinessUnitId = BAD.ChildBusinessUnitId
JOIN (SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
  FROM fn_GetRollupBusinessUnitsWithSecurity (''-1'', ''|'',-1,0)) BAS ON BAD.BusinessUnitId = BAS.RollupBusinessUnitId
JOIN ExchangeRateDim ER ON ITKS.ExchangeRateDate = ER.ExchangeRateDate
WHERE
    InvoiceStatus IN ('''+@InvoiceStatus+''')
    AND PaymentDate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+''' 
	AND ER.CurrencyCode = '''+@CurrencyCode+'''
GROUP BY 
    VendorName,
    CurrencyCode
HAVING 
    SUM(HoursForRates) > 0.01
ORDER BY [Blended Avg. Rate] DESC, [Vendor Name]
'
print (@SQL)
EXEC(@SQL)
