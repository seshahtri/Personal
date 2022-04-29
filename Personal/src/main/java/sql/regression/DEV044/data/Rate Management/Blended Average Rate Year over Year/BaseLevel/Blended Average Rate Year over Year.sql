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

set @pDateStart= DATEADD(year, -2, @pDateStart)
SET @SQL = '
execute as user = ''admin''
SELECT
	ili.RoleName as [Role Name],
	FORMAT(ili.InvoiceDate, ''yyyy'') as ''Year '',
	ili.CurrencyCode as [Currency Code],
	CAST(SUM(ili.Amount) AS FLOAT) / CAST(SUM(ili.Hours) AS FLOAT) as ''Blended Avg. Rate'',
	COUNT (DISTINCT ili.TimekeeperId) as ''Number of Timekeepers''
FROM V_InvoiceLineItemSpendFactWithCurrency ili
	JOIN TimekeeperRoleDim tk on tk.TimekeeperRoleId = ili.TimekeeperRoleId
WHERE 
	CurrencyCode = '''+@CurrencyCode+'''
	AND InvoiceStatus in ('''+@InvoiceStatus+''')
	--AND YEAR(ili.InvoiceDate) IN (2017)
	AND InvoiceDate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''   
	AND Category=''Fee''
	AND Hours > ''0''
	AND SumRate > ''0''
	AND ili.TimekeeperRoleId IS NOT NULL 
	AND ili.RoleName=''Partner''
GROUP BY ili.RoleName, FORMAT(ili.InvoiceDate, ''yyyy''), ili.CurrencyCode 
ORDER BY ''Year ''
'
print(@SQL)
Exec(@SQL)