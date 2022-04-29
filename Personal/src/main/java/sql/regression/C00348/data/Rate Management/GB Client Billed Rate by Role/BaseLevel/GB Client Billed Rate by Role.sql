--use C00348_IOD_DataMart

DECLARE @CurrencyCode  varchar (50);
DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @InvoiceStatus varchar (MAX);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;

--SET @pDateStart='03/1/2021';
--SET @pDateEnd='02/28/2022';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';

SET @SQL = 
'
exec as user = ''admin''
Select
Rpad.RollupPracticeAreaName as [Practice Area Name],
ili.RoleName as [Role Name],
e.CurrencyCode as [Currency Code],
COUNT (DISTINCT (CASE WHEN (ili.GrossFeeAmountForRates > 0) then ili.TimekeeperId Else Null End)) as ''Number of Timekeepers'',
SUM(GrossFeeAmountForRates * isnull(e.exchangerate,1))/ SUM(Nullif([HoursForRates],0)) as ''Avg. Billed Rate''
FROM
V_InvoiceTimekeeperSummary ili
INNER JOIN PracticeAreaAndAllDescendants pad ON (ili.PracticeAreaId = pad.ChildPracticeAreaId)
INNER JOIN (
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',-1,1)
) Rpad ON (pad.PracticeAreaId = Rpad.RollupPracticeAreaId)
INNER JOIN [dbo].[BusinessUnitAndAllDescendants] ba ON (ili.BusinessUnitId = ba.ChildBusinessUnitId)
INNER JOIN (
SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''-1'', ''|'',-1,0)
) rba ON (ba.BusinessUnitId = rba.RollupBusinessUnitId)
inner join ExchangeRateDim e on e.exchangeRateDate=ili.exchangeRatedate
where
ili.InvoiceStatus IN (''' + @InvoiceStatus + ''') 
and E.CurrencyCode = ''' + @CurrencyCode + '''
AND (ili.PaymentDate >= ''' + @pDateStart + ''' AND ili.PaymentDate<= ''' + @pDateEnd + ''')  
AND [FeeUnits] >= 0.01
group by
Rpad.RollupPracticeAreaName,
e.CurrencyCode,
ili.rolename
order by Rpad.RollupPracticeAreaName,
 CASE WHEN ili.rolename = ''Associate'' THEN ''1'' 
		WHEN ili.rolename = ''Legal Assistant'' THEN ''2'' 
		WHEN ili.rolename = ''Of Counsel'' THEN ''3''
		WHEN ili.rolename = ''other'' THEN ''4'' 
		WHEN ili.rolename = ''Other - Temporary Staffing Service'' THEN ''5'' 
		WHEN ili.rolename = ''Paralegal'' THEN ''6''
		WHEN ili.rolename = ''Partner'' THEN ''7'' ELSE ili.rolename END ASC
	
'
Print @SQL
EXEC(@SQL)
