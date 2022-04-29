--use DEV044_IOD_DataMart;

DECLARE @CurrencyCode varchar (50);
DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @InvoiceStatus varchar (MAX);

set @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @CurrencyCode= ^Currency^;
SET @InvoiceStatus= ^InvoiceStatus^;

set @pDateStart= DATEADD(year, -2, @pDateStart);

--SET @CurrencyCode ='USD';
--SET @pDateEnd ='2017-12-31 23:59:59.99';
--SET @InvoiceStatus ='Paid'',''Processed';
--set @pDateStart= DATEADD(year, -3, @pDateEnd)


SET @SQL = '
exec as user=''admin''



select YEAR(its.InvoiceDate) as ''Year'',
DateName(month, DateAdd(month, MONTH(its.InvoiceDate), -1)) as ''Month'',
E.CurrencyCode as ''Currency Code'',
sum([its].[GrossFeeAmountForRates]* ISNULL([e].[ExchangeRate],1)) as ''Fees'',
sum(its.HoursForRates) as ''hours'',
CAST(sum([FeeUnits]+[ExpenseUnits]) AS FLOAT) as Units
from matterdim m
join v_invoicetimekeepersummary its on its.MatterId = m.MatterID
JOIN ExchangeRateDim E ON CAST(Its.ExchangeRateDate AS DATE) = E.ExchangeRateDate
join practiceareadim p1 on p1.practiceareaid=m.practiceareaid
--join invoicelineitemfact il on il.invoiceid= its.invoiceid



Where
its.matterid = ^ParamOne^
--its.matterid = ''3686999''
AND its.VendorID = ^ParamTwo^
--AND its.VendorID = 53626
and its.InvoiceStatus in ('''+@InvoiceStatus+''')
AND its.InvoiceDate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
and E.CurrencyCode= '''+@CurrencyCode+'''
group by YEAR(its.InvoiceDate), MONTH(its.InvoiceDate), CurrencyCode
order by YEAR(its.InvoiceDate), MONTH(its.InvoiceDate)
'
print(@SQL)
EXEC(@SQL)