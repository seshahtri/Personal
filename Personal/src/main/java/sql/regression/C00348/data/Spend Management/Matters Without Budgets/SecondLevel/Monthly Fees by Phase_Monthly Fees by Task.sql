--USE Q5_C00348_IOD_DataMart

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

--SET @pDateStart='1/1/2018';
--SET @pDateEnd='12/31/2021';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';

SET @SQL='
select 
	datepart(year, ifbc.PaymentDate)  AS ''Year'',
	datename(month, ifbc.PaymentDate) AS ''Month'',
	ed.CurrencyCode as ''Currency Code'', 
	UTBMSTaskCode as ''Task Code'',
	Sum(ifbc.GrossFeeAmountForRates*ISNULL(ed.ExchangeRate,1)) as ''Fees''
from V_InvoiceFeeBillCodeSummary ifbc
	join ExchangeRateDim ed on ed.ExchangeRateDate = ifbc.ExchangeRateDate
	INNER JOIN BusinessUnitAndAllDescendants B on b.childbusinessunitid=ifbc.BusinessUnitId
	inner join 
			(SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
			FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (-1, ''|'',-1,0)) ba on ba.RollupBusinessUnitId=b.BusinessUnitId
	INNER JOIN PracticeAreaAndAllDescendants P on P.ChildPracticeAreaId=ifbc.PracticeAreaId
	INNER JOIN 
          (
			SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
			FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',-1,1)) pa on pa.RollupPracticeAreaId=p.PracticeAreaId
WHERE 
	ifbc.InvoiceStatus IN (''' + @InvoiceStatus + ''')
	AND (ifbc.PaymentDate between ''' + @pDateStart + ''' and ''' + @pDateEnd + ''')
	AND ed.CurrencyCode = ''' + @CurrencyCode + '''
	AND ifbc.Category = ''Fee''
	AND hours > 0.01
	--AND PhaseCode is NOT NULL
	AND TimekeeperRoleId IS NOT NULL
	AND MatterId = ^ParamOne^
	And PhaseCode = ^ParamTwo^
Group by UTBMSTaskCode,datepart(year, ifbc.PaymentDate), datename(month, ifbc.PaymentDate), ed.CurrencyCode
ORDER BY UTBMSTaskCode,Year,CASE? 
							   WHEN  datename(month, ifbc.PaymentDate) = ''January'' THEN ''0'' ??
							   WHEN  datename(month, ifbc.PaymentDate) = ''February'' THEN ''1'' 
							   WHEN  datename(month, ifbc.PaymentDate) = ''March'' THEN ''2'' ??
							   WHEN  datename(month, ifbc.PaymentDate) = ''April'' THEN ''3'' 
							   WHEN  datename(month, ifbc.PaymentDate) = ''May'' THEN ''4'' ??
							   WHEN  datename(month, ifbc.PaymentDate) = ''June'' THEN ''5'' 
							   WHEN  datename(month, ifbc.PaymentDate) = ''July'' THEN ''6'' ??
							   WHEN  datename(month, ifbc.PaymentDate) = ''August'' THEN ''7'' 
							   WHEN  datename(month, ifbc.PaymentDate) = ''September'' THEN ''8'' ??
							   WHEN  datename(month, ifbc.PaymentDate) = ''October'' THEN ''9'' 
							   WHEN  datename(month, ifbc.PaymentDate) = ''November'' THEN ''10'' ??
							   WHEN  datename(month, ifbc.PaymentDate) = ''December'' THEN ''11''  
							END
'

Print @SQL
EXEC(@SQL)