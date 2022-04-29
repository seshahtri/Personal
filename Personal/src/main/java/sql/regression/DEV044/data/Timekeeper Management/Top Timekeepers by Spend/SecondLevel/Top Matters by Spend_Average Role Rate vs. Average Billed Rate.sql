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
--SET @pDateStart='01/01/2017'; 
--SET @pDateEnd ='12/31/2017';
--SET @InvoiceStatus ='Paid'',''Processed';

SET @SQL = '
execute as user = ''admin''
SELECT
	ili.RoleName as [Role Name],
	ili.CurrencyCode as [Currency Code],
	cast((SUM(ili.Amount)/SUM(ili.Hours)) as FLOAT) as ''Role Rate'',
	CAST(AVG(br.BilledRate) AS FLOAT) AS ''Billed Rate''
	 FROM V_InvoiceLineItemSpendFactWithCurrency ili 
	
	JOIN TimekeeperRoleDim tk on tk.TimekeeperRoleId = ili.TimekeeperRoleId
	JOIN (
			SELECT 
				ili.RoleId,
				ili.TimekeeperRoleId,
				MIN(tk.BillRate) AS BilledRate
			FROM V_InvoiceLineItemSpendFactWithCurrency ili
				JOIN TimekeeperRoleDim tk on tk.TimekeeperRoleId = ili.TimekeeperRoleId
			WHERE
			--ili.TimekeeperId=911971 And ili.MatterId=3686999 
			ili.TimekeeperId=^ParamOne^ And ili.MatterId=^ParamTwo^ 
				AND CurrencyCode = '''+@CurrencyCode+'''
				AND InvoiceStatus in ('''+@InvoiceStatus+''')
				AND InvoiceDate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
				AND Category=''Fee''
				AND Hours > ''0''
				AND ili.TimekeeperId IS NOT NULL
				AND ili.TimekeeperRoleId IS NOT NULL 
				AND SumRate>0
			GROUP BY
				ili.RoleId,
				ili.TimekeeperRoleId
		) br on br.RoleId=ili.RoleId

WHERE --ili.TimekeeperId=911971 And ili.MatterId=3686999 and
ili.TimekeeperId=^ParamOne^ And ili.MatterId=^ParamTwo^ and
	CurrencyCode = '''+@CurrencyCode+'''
	AND InvoiceStatus in ('''+@InvoiceStatus+''')
	--AND YEAR(ili.InvoiceDate) IN (2017)
	AND InvoiceDate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''  
	AND Category=''Fee''
	AND Hours > ''0''
	AND Units >= ''0.001''
	AND ili.TimekeeperId IS NOT NULL
	AND ili.TimekeeperRoleId IS NOT NULL 
	AND SumRate>0
GROUP BY ili.RoleName, ili.CurrencyCode 
ORDER BY 
	ili.RoleName

'
print(@SQL)
EXEC(@SQL)


--select *  FROM V_InvoiceLineItemSpendFactWithCurrency ili where RoleName like '%of%' and  PracticeAreaId=32470 and matterid=5595523 