--use DEV044_IOD_DataMart;

DECLARE @pDateStart varchar (50);
DECLARE @pDateEnd varchar (50);
DECLARE @InvoiceStatus nvarchar (1000);
DECLARE @CurrencyCode varchar (50);
DECLARE @SQL VARCHAR(4000);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;

--SET @pDateStart='1/1/2017';
--SET @pDateEnd='12/31/2017';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';

SET @SQL='
EXEC AS USER =''admin''
SELECT DISTINCT v.VendorName, 
f.RoleName,  
f.currencycode,
(t.NetFeeAmount/sum (t.NetFeeAmount)  OVER (PARTITION BY 1))*100  ''% of total Fees'',
SUM(f.NetFeeAmount) ''Fees'', 
SUM(f.units) hours,
SUM(f.NetFeeAmount)/SUM(f.units) as ''Avg. Rate''
FROM V_InvoiceLineItemSpendFactWithCurrency f
JOIN V_Vendor v ON f.vendorid = v.vendorid 
JOIN V_Timekeeper TK ON TK.TimekeeperId = f.MatterOwnerId
join (select RoleName, sum(f.NetFeeAmount) as NetFeeAmount
from V_InvoiceLineItemSpendFactWithCurrency f
JOIN V_Vendor v ON f.vendorid = v.vendorid 
JOIN V_Timekeeper TK ON TK.TimekeeperId = f.MatterOwnerId
WHERE rolename IS NOT NULL
AND CurrencyCode = '''+@CurrencyCode+'''
AND Category = ''Fee''
AND Hours > 0
AND SumRate > 0
AND f.InvoiceStatus IN ('''+@InvoiceStatus+''') 
and f.InvoiceDate between '''+@pDateStart+''' and '''+@pDateEnd+'''  
AND f.VendorID = ^ParamOne^ 
--AND f.VendorID = 1047 
and f.roleid = ^ParamTwo^
--and f.roleid = 24
GROUP BY f.RoleName 
--ORDER BY rolename
) t on t.RoleName = f.RoleName

WHERE f.rolename IS NOT NULL
AND CurrencyCode = '''+@CurrencyCode+'''
AND Category = ''Fee''
AND Hours > 0
AND SumRate > 0
AND f.InvoiceStatus IN ('''+@InvoiceStatus+''') 
and f.InvoiceDate between '''+@pDateStart+''' and '''+@pDateEnd+'''  
AND f.VendorID = ^ParamOne^ 
--AND f.VendorID = 1047 
and f.roleid = ^ParamTwo^
--and f.roleid = 24
GROUP BY v.VendorName, f.rolename, f.currencycode, t.NetFeeAmount
--ORDER BY fees desc,hours desc,f.rolename
'
print(@SQL)
EXEC(@SQL)