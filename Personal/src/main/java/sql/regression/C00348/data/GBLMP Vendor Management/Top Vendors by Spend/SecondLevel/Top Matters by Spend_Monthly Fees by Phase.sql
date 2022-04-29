DECLARE @pDateStart varchar (50);
DECLARE @pDateEnd varchar (50);
DECLARE @InvoiceStatus nvarchar (1000);
DECLARE @CurrencyCode varchar (50);
DECLARE @SQL VARCHAR(4000);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;

--SET @pDateStart='05/01/2021';
--SET @pDateEnd='04/30/2022';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';

SET @SQL='
EXEC AS USER =''admin''
select
datepart(year, ifbc.PaymentDate) AS ''Year'',
datename(month, ifbc.PaymentDate) AS ''Month'',
PhaseCode as ''Phase Code'',
ed.CurrencyCode as ''Currency Code'',
Sum(ifbc.GrossFeeAmountForRates*ISNULL(ed.ExchangeRate,1)) as ''Fees'',
count(distinct matterid) as ''# of Matters'',
count(distinct invoiceid) as ''# of Invoices''


from V_InvoiceFeeBillCodeSummary ifbc
join ExchangeRateDim ed on ed.ExchangeRateDate = ifbc.ExchangeRateDate
INNER JOIN BusinessUnitAndAllDescendants B on b.childbusinessunitid=ifbc.BusinessUnitId
inner join
(SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (-1, ''|'',-1,0)) ba on ba.RollupBusinessUnitId=b.BusinessUnitId
INNER JOIN PracticeAreaAndAllDescendants P on P.ChildPracticeAreaId=ifbc.PracticeAreaId
INNER JOIN
(SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',-1,1)) pa on pa.RollupPracticeAreaId=p.PracticeAreaId
WHERE
ifbc.InvoiceStatus IN (''' + @InvoiceStatus + ''')
AND (ifbc.PaymentDate between ''' + @pDateStart + ''' and ''' + @pDateEnd + ''')
AND ed.CurrencyCode = ''' + @CurrencyCode + '''
AND ifbc.Category = ''Fee''
AND hours > 0.01
AND PhaseCode is NOT NULL
AND TimekeeperRoleId IS NOT NULL
--and vendorid=''70237'' And MatterId=''19124324''
and vendorid=''^ParamOne^'' And MatterId=''^ParamTwo^''
Group by PhaseCode,datepart(year, ifbc.PaymentDate), datename(month, ifbc.PaymentDate), ed.CurrencyCode
ORDER BY PhaseCode,Year, CASE  WHEN datename(month, ifbc.PaymentDate) = ''January'' THEN ''0''  
WHEN datename(month, ifbc.PaymentDate) = ''February'' THEN ''1''
WHEN datename(month, ifbc.PaymentDate) = ''March'' THEN ''2''  
WHEN datename(month, ifbc.PaymentDate) = ''April'' THEN ''3''
WHEN datename(month, ifbc.PaymentDate) = ''May'' THEN ''4''  
WHEN datename(month, ifbc.PaymentDate) = ''June'' THEN ''5''
WHEN datename(month, ifbc.PaymentDate) = ''July'' THEN ''6'' 
WHEN datename(month, ifbc.PaymentDate) = ''August'' THEN ''7''
WHEN datename(month, ifbc.PaymentDate) = ''September'' THEN ''8'' 
WHEN datename(month, ifbc.PaymentDate) = ''October'' THEN ''9''
WHEN datename(month, ifbc.PaymentDate) = ''November'' THEN ''10'' 
WHEN datename(month, ifbc.PaymentDate) = ''December'' THEN ''11''
END
'
Print @SQL
EXEC(@SQL)