--USE Q5_C00348_IOD_DataMart

EXECUTE AS USER='admin'

DECLARE @pDateStart varchar (50);
DECLARE @pDateEnd varchar (50);
DECLARE @InvoiceStatus nvarchar (1000);
DECLARE @CurrencyCode varchar (50);
DECLARE @SQL VARCHAR(4000);

--SET @pDateStart= ^StartDate^;
--SET @pDateEnd= ^EndDate^;
--SET @InvoiceStatus= ^InvoiceStatus^;
--SET @CurrencyCode= ^Currency^;

SET @pDateStart='1/1/2017';
SET @pDateEnd='12/31/2017';
SET @InvoiceStatus = 'Paid'',''Processed';
SET @CurrencyCode='USD';

SET @SQL=' 
	Select f.MatterName as ''Matter Name'',
	p.PracticeAreaName as ''Practice Area'',
	f.MatterStatus as ''Matter Status'',
	E.currencyCode as ''Currency Code'' ,
sum(il.Amount* ISNULL(E.ExchangeRate, 1))  [Spend]
 from matterdim f join PracticeAreaDim p on f.PracticeAreaId=p.PracticeAreaId 
 join invoicedim i on i.matterid =f.matterid  
 join invoicelineitemfact il on i.invoiceid=il.invoiceid 
 JOIN ExchangeRateDim E ON CAST(I.ExchangeRateDate AS DATE) = E.ExchangeRateDate 
 where i.InvoiceStatus IN (''' + @InvoiceStatus + ''')
 --and i.Invoicedate between ''2017-01-01 00:00:00.000'' and ''2017-12-31 23:59:59.998'' 
 AND (i.InvoiceDate >= ''' + @pDateStart + ''' AND i.InvoiceDate<= ''' + @pDateEnd + ''')
 --and e.currencyId = 1 
 AND e.CurrencyCode = ''' + @CurrencyCode + '''
 --AND il.VendorID = ^ParamOne^ 
 AND il.vendorid = 1047
 Group by f.MatterId, f.MatterName, p.PracticeAreaName, f.MatterStatus, e.currencyCode 
 having sum(il.amount)<>0 order by sum(il.amount) desc'

Print @SQL
EXEC(@SQL)