--use DEV044_IOD_DataMart;

DECLARE @CurrencyCode varchar (50);
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
pa.RollupPracticeAreaName as ''Practice Area'',
ili.RoleName as [Role Name],
ili.CurrencyCode as [Currency Code],
count(distinct ili.Timekeeperid) as [Number of Timekeepers],
cast((SUM(ili.Amount)/SUM(ili.Hours)) as FLOAT) as ''Avg.Billed Rate''
FROM V_InvoiceLineItemSpendFactWithCurrency ili
JOIN TimekeeperRoleDim tk on tk.TimekeeperRoleId = ili.TimekeeperRoleId
inner join PracticeAreaAndAllDescendants p on ili.PracticeAreaId=p.ChildPracticeAreaId
inner join
(
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',-1,1)
) pa on pa.rolluppracticeareaid=p.practiceareaid
JOIN (
SELECT
ili.RoleId,
ili.TimekeeperRoleId,
MIN(tk.BillRate) AS BilledRate
FROM V_InvoiceLineItemSpendFactWithCurrency ili
JOIN TimekeeperRoleDim tk on tk.TimekeeperRoleId = ili.TimekeeperRoleId
inner join PracticeAreaAndAllDescendants p on ili.PracticeAreaId=p.ChildPracticeAreaId
inner join
(
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',-1,1)
) pa on pa.rolluppracticeareaid=p.practiceareaid
WHERE
CurrencyCode = '''+@CurrencyCode+'''
AND InvoiceStatus in ('''+@InvoiceStatus+''')
AND InvoiceDate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
AND Category=''Fee''
AND Hours > ''0''
AND ili.TimekeeperId IS NOT NULL
AND ili.TimekeeperRoleId IS NOT NULL
AND SumRate>0
--AND ili.VendorId =''1047''
AND ili.VendorId = ^ParamOne^
--AND ili.RoleId = 23
AND ili.RoleId = ^ParamTwo^
GROUP BY
ili.RoleId,
ili.TimekeeperRoleId
) br on br.RoleId=ili.RoleId
WHERE
CurrencyCode = '''+@CurrencyCode+'''
AND InvoiceStatus in ('''+@InvoiceStatus+''')
AND InvoiceDate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
AND Category=''Fee''
AND Hours > ''0''
--AND Units >= ''0.001''
AND ili.TimekeeperId IS NOT NULL
AND ili.TimekeeperRoleId IS NOT NULL
AND SumRate>0
--AND ili.VendorId =''1047''
AND ili.VendorId = ^ParamOne^
--AND ili.RoleId = 23
AND ili.RoleId = ^ParamTwo^
GROUP BY pa.RollupPracticeAreaName,ili.RoleName, ili.CurrencyCode
ORDER BY
pa.RollupPracticeAreaName'
print(@SQL)
EXEC(@SQL)

