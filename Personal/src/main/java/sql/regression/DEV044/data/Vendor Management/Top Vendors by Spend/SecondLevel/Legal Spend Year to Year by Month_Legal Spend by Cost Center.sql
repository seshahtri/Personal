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
--SET @pDateStart='2017-03-01 00:00:00.00'; 
--SET @pDateEnd ='2017-03-31 23:59:59.99';
--SET @InvoiceStatus ='Paid'',''Processed';

SET @SQL = '

execute as user = ''admin''
select min(cc.RollupCostCenterName) as [Cost Center Name],
min(c.CurrencyCode) as [Currency Code],
sum(ilts.Amount) as [Total Spend],
sum(ilts.Amount) * 100 /sum(ilts.Amount) as [% of Total Spend],
sum(ilts.NetFeeAmount) as [Fees],
sum(ilts.NetExpAmount) as [Expense]
from V_InvoiceLineItemSpendFactWithCurrency ilts
inner join (select MatterId, RollupCostCenterId,RollupCostCenterName
from [dbo].[fn_GetCostCenterMatters] (''-1'', ''|'',-1,0)
) cc on cc.MatterId = ilts.MatterId
JOIN (SELECT  InvoiceId, SUM (AMOUNT) [TOTAL SPEND] FROM V_InvoiceLineItemSpendFactWithCurrency group by InvoiceId) a on ilts.InvoiceId = a.InvoiceId
inner join V_Currency c on ilts.CurrencyId = c.CurrencyId
where c.CurrencyCode = '''+@CurrencyCode+'''
and ilts.InvoiceDate between '''+@pDateStart+''' AND '''+@pDateEnd+'''
and ilts.InvoiceStatus in ('''+@InvoiceStatus+''')
AND ilts.VendorID = ^ParamOne^ 
		--AND ilts.VendorID = 53626 

'
print(@SQL)
EXEC(@SQL)
