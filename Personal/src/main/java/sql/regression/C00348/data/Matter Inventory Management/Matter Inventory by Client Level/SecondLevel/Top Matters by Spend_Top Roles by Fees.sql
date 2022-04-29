--USE C00348_IOD_DataMart

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

--SET @pDateStart='04/1/2021';
--SET @pDateEnd='03/31/2022';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';   

SET @SQL='
	SELECT 
		ILI.RoleName, 
		E.currencycode as [Currency Code], 
		SUM(NetFeeAmount) TotalFees,
		(SUM(NetFeeAmount) * 100 / (SELECT 
		SUM(NetFeeAmount) TotalFees
	FROM 
		V_InvoiceLineItemSpendFactWithCurrency ILI
	JOIN V_TimekeeperRole TK ON ILI.TimekeeperRoleId = TK.TimekeeperRoleId
	 INNER JOIN [dbo].[PracticeAreaAndAllDescendants] P ON [ILI].[PracticeAreaId] = [P].[ChildPracticeAreaId]
	  INNER JOIN (
	  SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
	  FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity] (-1, ''|'',^ParamOne^,0)
	) [RollupPracticeAreasWithSecurity] ON ([P].[PracticeAreaId] = [RollupPracticeAreasWithSecurity].[RollupPracticeAreaId])
	  INNER JOIN [dbo].[BusinessUnitAndAllDescendants] B ON [ILI].[BusinessUnitId] = B.[ChildBusinessUnitId]
	  INNER JOIN (
	  SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
	  FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (-1, ''|'',-1,0)
	) [RollupBusinessUnitsWithSecurity] ON (B.[BusinessUnitId] = [RollupBusinessUnitsWithSecurity].[RollupBusinessUnitId])
	  LEFT JOIN [dbo].[ExchangeRateDim] E ON [ILI].[ExchangeRateDate] = E.[ExchangeRateDate]
	left join TimekeeperDim tk1 on ili.matterownerid  = tk1.TimekeeperId 
	join vendordim v on v.vendorid=ili.vendorid
	WHERE

	PaymentDate BETWEEN ''' + @pDateStart + ''' AND ''' + @pDateEnd + '''

	AND InvoiceStatus IN (''' + @InvoiceStatus + ''')
	AND MatterId = ^ParamTwo^
	AND Category = ''Fee''
	AND ILI.TimekeeperRoleId IS NOT NULL
	AND Hours>0
	AND SumRate >0
	AND E.CurrencyId =1
	AND ili.CurrencyId = 1)) as [% of Total Fees],  
		SUM(Units) Hours, 
		COUNT(DISTINCT MatterId) NoOfMatters, 
		SUM(Amount)/ SUM(Hours)  AverageRate
	FROM 
		V_InvoiceLineItemSpendFactWithCurrency ILI
	JOIN V_TimekeeperRole TK ON ILI.TimekeeperRoleId = TK.TimekeeperRoleId
	 INNER JOIN [dbo].[PracticeAreaAndAllDescendants] P ON [ILI].[PracticeAreaId] = [P].[ChildPracticeAreaId]
	  INNER JOIN (
	  SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
	  FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity] (-1, ''|'',^ParamOne^,0)
	) [RollupPracticeAreasWithSecurity] ON ([P].[PracticeAreaId] = [RollupPracticeAreasWithSecurity].[RollupPracticeAreaId])
	  INNER JOIN [dbo].[BusinessUnitAndAllDescendants] B ON [ILI].[BusinessUnitId] = B.[ChildBusinessUnitId]
	  INNER JOIN (
	  SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
	  FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (-1, ''|'',-1,0)
	) [RollupBusinessUnitsWithSecurity] ON (B.[BusinessUnitId] = [RollupBusinessUnitsWithSecurity].[RollupBusinessUnitId])
	  LEFT JOIN [dbo].[ExchangeRateDim] E ON [ILI].[ExchangeRateDate] = E.[ExchangeRateDate]

	left join TimekeeperDim tk1
	on ili.matterownerid  = tk1.TimekeeperId 

	join vendordim v on v.vendorid=ili.vendorid

	WHERE
	PaymentDate BETWEEN ''' + @pDateStart + ''' AND ''' + @pDateEnd + '''

	AND InvoiceStatus IN (''' + @InvoiceStatus + ''')
	AND MatterId = ^ParamTwo^
	AND Category = ''Fee''
	AND ILI.TimekeeperRoleId IS NOT NULL
	AND Hours>0
	AND SumRate >0
	AND E.CurrencyId =1
	AND ili.CurrencyId = 1

	GROUP BY ILI.RoleId,ILI.RoleName,E.currencycode 
	ORDER BY [% of Total Fees] DESC'
Print @SQL
EXEC(@SQL)
