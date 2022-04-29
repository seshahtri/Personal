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
--SET @pDateStart='2017-01-01 00:00:00.00'; 
--SET @pDateEnd ='2017-12-31 23:59:59.99';
--SET @InvoiceStatus ='Paid'',''Processed';

SET @SQL = '
exec as user=''admin''
Select  f.MatterName as ''Matter Name'', pa.RollupPracticeAreaName as ''Practice Area'', f.MatterStatus as ''Matter Status'', E.currencyCode as ''Currency Code'' ,
--LTRIM(STR(CAST(sum(il.Amount) AS FLOAT), 25, 5)) [Spend]
CAST(SUM(il.Amount) AS FLOAT) as [Spend]
 from matterdim f 
 join (SELECT RollupPracticeAreaId, RollupPracticeAreaName
 FROM [dbo].[fn_GetPracticeAreasWithChildrenWithRollupPracticeArea] (''-1'', ''|'',^ParamTwo^)) pa on pa.RollupPracticeAreaId=f.PracticeAreaId
--FROM [dbo].[fn_GetPracticeAreasWithChildrenWithRollupPracticeArea] (''-1'', ''|'',32475)) pa on pa.RollupPracticeAreaId=f.PracticeAreaId
 join invoicedim i on i.matterid =f.matterid  
 join invoicelineitemfact il on i.invoiceid=il.invoiceid 
 JOIN ExchangeRateDim E ON CAST(I.ExchangeRateDate AS DATE) = E.ExchangeRateDate 
 where i.InvoiceStatus in ('''+@InvoiceStatus+''') 
 and i.Invoicedate between '''+@pDateStart+''' and '''+@pDateEnd+''' 
 and e.CurrencyCode = '''+@CurrencyCode+'''
 AND i.VendorID = ^ParamOne^ 
--		AND i.VendorID = 53626 
 Group by f.MatterId, f.MatterName, pa.RollupPracticeAreaName, f.MatterStatus, e.currencyCode 
 having sum(il.amount)<>0 order by sum(il.amount) desc
 '
 print(@SQL)
 EXEC(@SQL)