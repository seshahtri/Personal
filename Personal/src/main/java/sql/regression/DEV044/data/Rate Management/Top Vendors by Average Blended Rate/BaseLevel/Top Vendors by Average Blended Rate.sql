--use DEV044_IOD_DataMart;

DECLARE @CurrencyCode  varchar (50);
DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @InvoiceStatus varchar (MAX);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @CurrencyCode= ^Currency^;
SET @InvoiceStatus= ^InvoiceStatus^;

--SET @CurrencyCode ='USD';
--SET @pDateStart='2017-01-01 00:00:00.00'; 
--SET @pDateEnd ='2017-12-31 23:59:59.99';
--SET @InvoiceStatus ='Paid'',''Processed';

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
    AND invoiceDate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+''' 
	AND ER.CurrencyCode = '''+@CurrencyCode+'''
GROUP BY 
    VendorName,
    CurrencyCode
HAVING 
    SUM(HoursForRates) > 0.01
ORDER BY [Blended Avg. Rate] DESC
'
print (@SQL)
EXEC(@SQL)
