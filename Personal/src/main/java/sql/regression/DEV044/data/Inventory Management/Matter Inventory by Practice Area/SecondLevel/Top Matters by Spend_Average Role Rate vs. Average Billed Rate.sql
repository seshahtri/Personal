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
			ili.matterid=5595523
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
		INNER JOIN (
  SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
  FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (32470, ''|'',-1,1)
  --FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (^ParamOne^, ''|'',-1,1)
) [RollupPracticeAreasWithSecurity] ON (ili.[PracticeAreaId] = [RollupPracticeAreasWithSecurity].[RollupPracticeAreaId])
WHERE 
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