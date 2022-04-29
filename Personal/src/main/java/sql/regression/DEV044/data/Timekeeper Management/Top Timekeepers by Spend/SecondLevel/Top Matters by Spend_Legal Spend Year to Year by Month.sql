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

set @pDateStart= DATEADD(year, -2, @pDateStart)
SET @SQL='
EXEC AS USER =''admin''
Select 
	YEAR(i.InvoiceDate) as ''Year'',
	DateName(month, DateAdd(month, MONTH(i.InvoiceDate), -1)) as ''Month'',
	E.CurrencyCode as ''Currency Code'', 
	sum(Inv.NetFeeamount) as ''Fees'',
	CAST(sum(Inv.Feeunits) AS FLOAT) as ''Hours'',
	CAST(sum(Inv.Feeunits+Inv.Expenseunits) AS FLOAT) as ''Units'' 
from matterdim m
	join invoicedim i on i.matterid =m.matterid 
	JOIN ExchangeRateDim E ON CAST(I.ExchangeRateDate AS DATE) = E.ExchangeRateDate  
	join practiceareadim p1 on p1.practiceareaid=m.practiceareaid
	---join invoicelineitemfact il on il.invoiceid= i.invoiceid 
	join V_InvoiceTimekeeperSummary Inv on Inv.invoiceid=i.invoiceid
	 INNER JOIN [dbo].[PracticeAreaAndAllDescendants] [PracticeAreaAndAllDescendants]
		 ON (p1.[PracticeAreaId] = [PracticeAreaAndAllDescendants].[ChildPracticeAreaId])
  INNER JOIN (
  SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
  FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',-1,1)
) [RollupPracticeAreasWithSecurity] ON ([PracticeAreaAndAllDescendants].[PracticeAreaId] = [RollupPracticeAreasWithSecurity].[RollupPracticeAreaId])


Where --Inv.TimekeeperId=911971 And i.MatterId=3686999 and
	Inv.TimekeeperId=^ParamOne^ And i.MatterId=^ParamTwo^ and
     i.InvoiceStatus IN (''' + @InvoiceStatus + ''')
	 and (i.Invoicedate between ''' + @pDateStart + ''' and ''' + @pDateEnd + ''')
	 and E.CurrencyCode = ''' + @CurrencyCode + '''
group by YEAR(i.InvoiceDate), MONTH(i.InvoiceDate), CurrencyCode
order by YEAR(i.InvoiceDate), MONTH(i.InvoiceDate)
'
Print @SQL
EXEC(@SQL)

--select * from VendorDim where VendorName like 'Ackerman%'



