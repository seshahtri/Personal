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
--SET @pDateStart='2017-01-01'; 
--SET @pDateEnd ='2017-12-31';
--SET @InvoiceStatus ='Paid'',''Processed';

set @pDateStart= DATEADD(year, -2, @pDateStart)

SET @SQL = '
exec as user = ''admin''
SELECT
	ili.RoleName as [Role Name],
	ili.CurrencyCode as [Currency Code],
	YEAR (ili.InvoiceDate) as ''Year'',
	CAST(SUM(ili.Amount) AS FLOAT) / CAST(SUM(ili.Hours) AS FLOAT) as ''Avg.Blended Rate'',
	COUNT (DISTINCT ili.TimekeeperId) as ''Number of Timekeepers''
	
FROM V_InvoiceLineItemSpendFactWithCurrency ili
	JOIN TimekeeperRoleDim tk on tk.TimekeeperRoleId = ili.TimekeeperRoleId
WHERE 
	CurrencyCode = '''+@CurrencyCode+'''
	AND InvoiceStatus in ('''+@InvoiceStatus+''')
	--AND YEAR(ili.InvoiceDate) IN (2015,2016,2017)
	AND InvoiceDate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''   
	AND Category=''Fee''
	AND Hours >= ''0.001''
	AND ili.TimekeeperRoleId IS NOT NULL 
	AND SumRate>0

GROUP BY ili.RoleName, ili.CurrencyCode ,YEAR (ili.InvoiceDate)
ORDER BY 
	CASE WHEN ili.RoleName = ''Partner'' THEN ''1''
		WHEN ili.RoleName = ''Associate'' THEN ''2''
		WHEN ili.RoleName = ''Paralegal'' THEN ''4''
		WHEN ili.RoleName = ''Of Counsel'' THEN ''3''
		WHEN ili.RoleName = ''Support'' THEN ''5''
		WHEN ili.RoleName = ''Other'' THEN ''6''
		ELSE ili.RoleName END ASC
	, ''Year'' DESC

'
print(@SQL)
exec(@SQL)