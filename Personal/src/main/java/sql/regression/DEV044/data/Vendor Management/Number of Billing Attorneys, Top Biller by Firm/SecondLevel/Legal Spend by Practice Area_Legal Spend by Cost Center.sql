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
--SET @pDateStart='01/01/2017'; 
--SET @pDateEnd ='12/31/2017';
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
join (SELECT RollupPracticeAreaId, RollupPracticeAreaName
FROM [dbo].[fn_GetPracticeAreasWithChildrenWithRollupPracticeArea] (''-1'', ''|'',^ParamTwo^)) pa on pa.RollupPracticeAreaId=ilts.PracticeAreaId
--FROM [dbo].[fn_GetPracticeAreasWithChildrenWithRollupPracticeArea] (''-1'', ''|'',32475)) pa on pa.RollupPracticeAreaId=ilts.PracticeAreaId
inner join V_Currency c on ilts.CurrencyId = c.CurrencyId
where c.CurrencyCode = '''+@CurrencyCode+'''
and ilts.InvoiceDate between '''+@pDateStart+''' AND '''+@pDateEnd+'''
and ilts.InvoiceStatus in ('''+@InvoiceStatus+''')
--and vendorid=1044
and vendorid=^ParamOne^

'
print(@SQL)
EXEC(@SQL)
