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
		pa.RollupPracticeAreaName as ''Practice Area'', 
		f.MatterStatus as ''Matter Status'', 
		E.currencyCode as ''Currency'' ,
		sum(il.Amount) as [Spend]
	from matterdim f --join PracticeAreaDim p on f.PracticeAreaId=p.PracticeAreaId 
	INNER JOIN PracticeAreaAndAllDescendants pad ON f.PracticeAreaId = pad.ChildPracticeAreaId
INNER JOIN (
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
--FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',32475,1)
FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',^ParamTwo^,1)
) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
		 join invoicedim i on i.matterid =f.matterid  
		 join invoicelineitemfact il on i.invoiceid=il.invoiceid 
		 JOIN ExchangeRateDim E ON CAST(I.ExchangeRateDate AS DATE) = E.ExchangeRateDate 
	 where il.vendorid=^ParamOne^ and
	 --il.vendorid=1044 and
		i.InvoiceStatus IN (''' + @InvoiceStatus + ''')
		and (i.Invoicedate between ''' + @pDateStart + ''' and ''' + @pDateEnd + ''')
		and E.CurrencyCode = ''' + @CurrencyCode + '''
	 Group by 
		f.MatterId, 
		f.MatterName, 
		pa.RollupPracticeAreaName, 
		f.MatterStatus, 
		e.currencyCode 
	 having sum(il.amount)<>0 order by sum(il.amount) desc'

Print @SQL
EXEC(@SQL)

--select * from PracticeAreaDim where PracticeAreaName like '%Employ%'