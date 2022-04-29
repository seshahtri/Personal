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

SET @SQL='
exec as user = ''admin''
SELECT top 1 
MatterOwnerId,
FullName [Matter Owner],
COUNT(DISTINCT MI.MatterId) [Open Matters],
SUM (Spend) Spend
FROM V_MatterInfo MI
JOIN V_Timekeeper TK ON TK.TimekeeperId = MI.MatterOwnerId
LEFT JOIN (
SELECT MatterId, CurrencyCode, SUM(f.Amount) Spend
FROM V_InvoiceLineItemSpendFactWithCurrency f
WHERE CurrencyCode = '''+@CurrencyCode+'''
AND InvoiceStatus IN ('''+@InvoiceStatus+''')
and InvoiceDate between '''+@pDateStart+''' and '''+@pDateEnd+''' 
GROUP BY MatterId, CurrencyCode) S ON S.MatterId = MI.MatterId
WHERE MatterOpenDate < = '''+@pDateEnd+''' 
AND (MatterCloseDate > '''+@pDateEnd+''' OR MatterCloseDate IS NULL)
GROUP BY MatterOwnerId, FullName
ORDER BY [Open Matters] DESC
'
print(@SQL)
exec(@SQL)