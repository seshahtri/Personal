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

--SET @pDateStart='1/1/2017';
--SET @pDateEnd='12/31/2017';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';

SET @SQL='
SELECT 
	d.FullName as ''MatterOwner'',
	CASE WHEN t.MatterCloseDate  IS NULL THEN ''Active'' Else ''Closed'' End as [Matter State],
	e.CurrencyCode as ''Currency Code'',
	SUM (il.amount) as ''Spend'',
	COUNT(Distinct t.Matterid) as ''Matters'',
	a.Total_Spend  as ''Total Spend'',
	a.Total_Hours  as ''Total Hours'',
	a.Total_Hours  as ''Total Units''
FROM matterdim t
	LEFT JOIN TimekeeperDim d ON t.MatterOwnerId = d.TimekeeperId
	join invoicedim i on i.matterid =t.matterid
	INNER JOIN PracticeAreaAndAllDescendants P on P.ChildPracticeAreaId=t.PracticeAreaId
	INNER JOIN 
			 (
			  SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
		      --FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',32475,1)) pa on pa.RollupPracticeAreaId=p.PracticeAreaId
			  FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',^ParamTwo^,1)) pa on pa.RollupPracticeAreaId=p.PracticeAreaId
	JOIN ExchangeRateDim E ON CAST(I.ExchangeRateDate AS DATE) = E.ExchangeRateDate 
	join invoicelineitemfact il on  i.invoiceid=il.invoiceid
	LEFT OUTER JOIN (SELECT TOP 10 f.MatterOwnerId, SUM (il.Amount) as Total_Spend, SUM(il.units) as Total_Hours
					from matterdim  f
						join invoicedim i on i.matterid =f.matterid 
						INNER JOIN PracticeAreaAndAllDescendants P on P.ChildPracticeAreaId=f.PracticeAreaId
	INNER JOIN 
			 (
			  SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
		      --FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',32475,1)) pa on pa.RollupPracticeAreaId=p.PracticeAreaId
			  FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',^ParamTwo^,1)) pa on pa.RollupPracticeAreaId=p.PracticeAreaId
						JOIN ExchangeRateDim E ON CAST(I.ExchangeRateDate AS DATE) = E.ExchangeRateDate 
						join invoicelineitemfact il on  i.invoiceid=il.invoiceid
					Where
						e.CurrencyCode = ''' + @CurrencyCode + '''
						and InvoiceStatus IN (''' + @InvoiceStatus + ''')
						AND (Invoicedate between ''' + @pDateStart + ''' and ''' + @pDateEnd + ''')
						--And i.vendorid=1044
						And i.vendorid=^ParamOne^
				    GROUP BY f.MatterOwnerId) a ON  
						(case when a.MatterOwnerId is null then '' '' else a.MatterOwnerId end = case when t.MatterOwnerId is null then '' '' else t.MatterOwnerId end)
WHERE 
	 e.CurrencyCode = ''' + @CurrencyCode + '''
	 and InvoiceStatus IN (''' + @InvoiceStatus + ''')
	 AND (Invoicedate between ''' + @pDateStart + ''' and ''' + @pDateEnd + ''')
	 --And i.vendorid=1044
	 And i.vendorid=^ParamOne^
GROUP BY t.MatterOwnerId, d.FullName, a.Total_Spend, CASE WHEN t.MatterCloseDate  IS NULL THEN ''Active'' Else ''Closed'' End, a.Total_Hours, e.CurrencyCode
ORDER BY SUM (il.Amount) desc, CASE WHEN t.MatterCloseDate  IS NULL THEN ''Active'' Else ''Closed'' End  
'
Print @SQL
EXEC(@SQL)