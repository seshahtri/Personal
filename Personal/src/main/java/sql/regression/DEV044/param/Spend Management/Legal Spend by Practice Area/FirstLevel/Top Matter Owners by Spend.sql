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
SELECT top 1
t.MatterOwnerId,
	d.FullName as ''MatterOwnerName'',
	CASE WHEN t.MatterCloseDate  IS NULL THEN ''Active'' Else ''Closed'' End as ''Matter State'',
	e.CurrencyCode as ''Currency Code'',
	SUM (il.amount) as ''Amount'',
	COUNT(Distinct t.Matterid) as ''Matters'',
	a.Total_Spend  as ''Total Amount'',
	a.Total_Units as ''Total Units'',
	a.Total_Hours  as ''Total Hours''
FROM matterdim t


	LEFT JOIN TimekeeperDim d ON t.MatterOwnerId = d.TimekeeperId
	join invoicedim i on i.matterid =t.matterid
	JOIN ExchangeRateDim E ON CAST(I.ExchangeRateDate AS DATE) = E.ExchangeRateDate 
	join invoicelineitemfact il on  i.invoiceid=il.invoiceid
	join (SELECT RollupPracticeAreaId, RollupPracticeAreaName
	FROM [dbo].[fn_GetPracticeAreasWithChildrenWithRollupPracticeArea] (''-1'', ''|'',^ParamOne^)) pa on pa.RollupPracticeAreaId=t.PracticeAreaId
	--FROM [dbo].[fn_GetPracticeAreasWithChildrenWithRollupPracticeArea] (''-1'', ''|'',32475)) pa on pa.RollupPracticeAreaId=t.PracticeAreaId
	 
	LEFT OUTER JOIN (SELECT  f.MatterOwnerId, SUM (il.Amount) as Total_Spend, SUM(il.units) as Total_Units, SUM(il.units) as Total_Hours
			from matterdim  f
			join invoicedim i on i.matterid =f.matterid 
			JOIN ExchangeRateDim E ON CAST(I.ExchangeRateDate AS DATE) = E.ExchangeRateDate 
			join invoicelineitemfact il on  i.invoiceid=il.invoiceid
			Where e.CurrencyCode = '''+@CurrencyCode+'''
and InvoiceStatus in ('''+@InvoiceStatus+''')
and InvoiceDate between '''+@pDateStart+''' and '''+@pDateEnd+''' 
GROUP BY f.MatterOwnerId) a ON a.MatterOwnerId=t.MatterOwnerId OR ISNULL(a.MatterOwnerId, '''') = ISNULL(t.MatterOwnerId,'''')
WHERE e.CurrencyCode = '''+@CurrencyCode+'''
and
InvoiceStatus in ('''+@InvoiceStatus+''')
and InvoiceDate between '''+@pDateStart+''' and '''+@pDateEnd+''' 
GROUP BY t.MatterOwnerId, d.FullName, a.Total_Spend, CASE WHEN t.MatterCloseDate  IS NULL THEN ''Active'' Else ''Closed'' End, a.Total_Hours, e.CurrencyCode,a.Total_Units
ORDER BY SUM (il.amount) desc, ''Matter State''
'
print(@SQL)
EXEC(@SQL)