--USE DEV044_IOD_DataMart

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

SET @SQL='
Select 
    TOP 1
    i.MatterId,
	YEAR(i.InvoiceDate) as ''Year'',
	DateName(month, DateAdd(month, MONTH(i.InvoiceDate), -1)) as ''Month'',
	E.CurrencyCode as ''Currency Code'', 
	sum(il.amount) as ''Spend'',
	CAST(sum(il.units) AS FLOAT) as ''Units'' 
from matterdim m
	join invoicedim i on i.matterid =m.matterid 
	JOIN ExchangeRateDim E ON CAST(I.ExchangeRateDate AS DATE) = E.ExchangeRateDate  
	join practiceareadim p1 on p1.practiceareaid=m.practiceareaid
	join invoicelineitemfact il on il.invoiceid= i.invoiceid 
where  
     i.InvoiceStatus IN (''' + @InvoiceStatus + ''')
	 and (i.Invoicedate between ''' + @pDateStart + ''' and ''' + @pDateEnd + ''')
	and E.CurrencyCode = ''' + @CurrencyCode + '''
group by i.matterid, YEAR(i.InvoiceDate), MONTH(i.InvoiceDate), CurrencyCode
order by YEAR(i.InvoiceDate), MONTH(i.InvoiceDate)
'
Print @SQL
EXEC(@SQL)