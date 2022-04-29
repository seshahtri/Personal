--use C00348_IOD_DataMart;

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
--SET @pDateStart='3/1/2021';
--SET @pDateEnd='2/28/2022';
--SET @InvoiceStatus = 'Paid'',''Processed';

SET @SQL = '
exec as user=''admin''

SELECT 
	--ILI.RoleId, 
	ILI.RoleName, 
	E.CurrencyCode as [Currency Code], 
	SUM(GrossFeeAmountForRates) [Total Fees],
	(SUM(GrossFeeAmountForRates) * 100 / (SELECT 
	SUM(GrossFeeAmountForRates) TotalFee
FROM 
	V_InvoiceTimekeeperSummary ILI
JOIN V_TimekeeperRole TK ON ILI.TimekeeperRoleId = TK.TimekeeperRoleId
 INNER JOIN [dbo].[PracticeAreaAndAllDescendants] P ON [ILI].[PracticeAreaId] = [P].[ChildPracticeAreaId]
  INNER JOIN (
  SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
  FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity] (''-1'', ''|'',-1,0)
) [RollupPracticeAreasWithSecurity] ON ([P].[PracticeAreaId] = [RollupPracticeAreasWithSecurity].[RollupPracticeAreaId])
  INNER JOIN [dbo].[BusinessUnitAndAllDescendants] B ON [ILI].[BusinessUnitId] = B.[ChildBusinessUnitId]
  INNER JOIN (
  SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
  FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''-1'', ''|'',-1,0)
) [RollupBusinessUnitsWithSecurity] ON (B.[BusinessUnitId] = [RollupBusinessUnitsWithSecurity].[RollupBusinessUnitId])
  LEFT JOIN [dbo].[ExchangeRateDim] E ON [ILI].[ExchangeRateDate] = E.[ExchangeRateDate]
left join TimekeeperDim tk1 on ili.matterownerid  = tk1.TimekeeperId 
join vendordim v on v.vendorid=ili.vendorid
WHERE
PaymentDate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
AND InvoiceStatus IN ('''+@InvoiceStatus+''')
--AND Category = ''Fee''
AND ILI.TimekeeperRoleId IS NOT NULL
AND Hours>0
--AND SumRate >0
AND E.CurrencyCode = '''+@CurrencyCode+'''
--AND ili.CurrencyCode = '''+@CurrencyCode+'''
)) as [% of Total Fees],  
	SUM(HoursForRates) Hours, 
	COUNT_BIG(DISTINCT (CASE WHEN ([GrossFeeAmountForRates] > 0) THEN ([MatterId]) ELSE CAST(NULL AS BIGINT) END)) [No Of Matters], 
	SUM(GrossFeeAmountForRates)/ SUM(HoursForRates) [Average Rate]
FROM 
	V_InvoiceTimekeeperSummary ILI
JOIN V_TimekeeperRole TK ON ILI.TimekeeperRoleId = TK.TimekeeperRoleId
 INNER JOIN [dbo].[PracticeAreaAndAllDescendants] P ON [ILI].[PracticeAreaId] = [P].[ChildPracticeAreaId]
  INNER JOIN (
  SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
  FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity] (''-1'', ''|'',-1,0)
) [RollupPracticeAreasWithSecurity] ON ([P].[PracticeAreaId] = [RollupPracticeAreasWithSecurity].[RollupPracticeAreaId])
  INNER JOIN [dbo].[BusinessUnitAndAllDescendants] B ON [ILI].[BusinessUnitId] = B.[ChildBusinessUnitId]
  INNER JOIN (
  SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
  FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''-1'', ''|'',-1,0)
) [RollupBusinessUnitsWithSecurity] ON (B.[BusinessUnitId] = [RollupBusinessUnitsWithSecurity].[RollupBusinessUnitId])
  LEFT JOIN [dbo].[ExchangeRateDim] E ON [ILI].[ExchangeRateDate] = E.[ExchangeRateDate]

left join TimekeeperDim tk1
on ili.matterownerid  = tk1.TimekeeperId 

join vendordim v on v.vendorid=ili.vendorid

WHERE
Paymentdate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
AND InvoiceStatus IN ('''+@InvoiceStatus+''')
--AND Category = ''Fee''
AND ILI.TimekeeperRoleId IS NOT NULL
AND Hours>0
--AND SumRate >0
AND E.CurrencyCode ='''+@CurrencyCode+'''
--AND ili.CurrencyCode = '''+@CurrencyCode+'''

GROUP BY ILI.RoleId,ILI.RoleName,E.CurrencyCode 
ORDER BY [% of Total Fees] DESC
'
print(@SQL)
exec(@SQL);