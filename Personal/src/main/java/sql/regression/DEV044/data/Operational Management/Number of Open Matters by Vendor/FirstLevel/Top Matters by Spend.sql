--USE DEV044_IOD_DataMart

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
	Select Top 1000
		f.MatterName as ''Matter Name'', 
		p.PracticeAreaName as ''Practice Area'', 
		f.MatterStatus as ''Matter Status'', 
		E.currencyCode as ''Currency'' ,
		sum(il.Amount) as [Spend]
	from matterdim f join PracticeAreaDim p on f.PracticeAreaId=p.PracticeAreaId 
		 join invoicedim i on i.matterid =f.matterid  
		 join invoicelineitemfact il on i.invoiceid=il.invoiceid 
		 JOIN ExchangeRateDim E ON CAST(I.ExchangeRateDate AS DATE) = E.ExchangeRateDate 
	 where il.vendorid=^ParamOne^ and
	 --il.vendorid=53619 and
		i.InvoiceStatus IN (''' + @InvoiceStatus + ''')
		and (i.Invoicedate between ''' + @pDateStart + ''' and ''' + @pDateEnd + ''')
		and E.CurrencyCode = ''' + @CurrencyCode + '''
	 Group by 
		f.MatterId, 
		f.MatterName, 
		p.PracticeAreaName, 
		f.MatterStatus, 
		e.currencyCode 
	 having sum(il.amount)<>0 order by sum(il.amount) desc'

Print @SQL
EXEC(@SQL)

