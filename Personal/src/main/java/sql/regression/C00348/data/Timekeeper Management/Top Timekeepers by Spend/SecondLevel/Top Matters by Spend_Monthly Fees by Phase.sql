EXEC AS USER ='admin'

 --USE C00348_IOD_DATAMART

DECLARE @pDateStart varchar (50);

DECLARE @pDateEnd varchar (50);

DECLARE @InvoiceStatus nvarchar (1000);

DECLARE @CurrencyCode varchar (50);

DECLARE @SQL VARCHAR(4000);

 

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;

--SET @pDateStart='05/1/2021';
--SET @pDateEnd='04/30/2022';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';  

 

SET @SQL='

select   

       PhaseCode as ''Phase Code'',  

       ed.CurrencyCode as ''Currency Code'',

       datepart(year, ifbc.PaymentDate)  AS ''Year'',  

       datename(month, ifbc.PaymentDate) AS ''Month'', 

       Sum(ifbc.GrossFeeAmountForRates*ISNULL(ed.ExchangeRate,1)) as ''Fees''

       ,COUNT(Distinct ifbc.Matterid) as ''# of Matters''

,COUNT(Distinct ifbc.InvoiceId) as ''Number of Invoices''--,month(ifbc.PaymentDate)

      

from V_InvoiceFeeBillCodeSummary ifbc 

       join ExchangeRateDim ed on ed.ExchangeRateDate = ifbc.ExchangeRateDate 

       INNER JOIN BusinessUnitAndAllDescendants B on b.childbusinessunitid=ifbc.BusinessUnitId 

       inner join (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel 

                           FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (-1, ''|'',-1,0)) ba on ba.RollupBusinessUnitId=b.BusinessUnitId 

       INNER JOIN PracticeAreaAndAllDescendants P on P.ChildPracticeAreaId=ifbc.PracticeAreaId 

       INNER JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel 

                           FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',-1,1)) pa on pa.RollupPracticeAreaId=p.PracticeAreaId    
				--FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',-1,1)) pa on pa.RollupPracticeAreaId=p.PracticeAreaId    

WHERE

       ifbc.InvoiceStatus IN (''' + @InvoiceStatus + ''')

       AND (ifbc.PaymentDate between ''' + @pDateStart + ''' and ''' + @pDateEnd + ''') 

       AND ed.Currencycode = ''' + @CurrencyCode + ''' 

       AND ifbc.Category = ''Fee''

       AND hours > 0.01 

       AND PhaseCode is NOT NULL 

       AND TimekeeperRoleId IS NOT NULL

        
and timekeeperid=^ParamOne^
	AND MatterId = ^ParamTwo^
	--and timekeeperid=1356933
	--AND MatterId = 19078612

 

       Group by PhaseCode,datepart(year, ifbc.PaymentDate), datename(month, ifbc.PaymentDate),month(ifbc.PaymentDate), ed.CurrencyCode 

       --ORDER BY PhaseCode,Year, CASE 

       --                                                     WHEN  datename(month, ifbc.PaymentDate) = ''January'' THEN ''0''              

       --                                                     WHEN  datename(month, ifbc.PaymentDate) = ''February'' THEN ''1''            

       --                                                     WHEN  datename(month, ifbc.PaymentDate) = ''March'' THEN ''2''              

       --                                                     WHEN  datename(month, ifbc.PaymentDate) = ''April'' THEN ''3''             

       --                                                     WHEN  datename(month, ifbc.PaymentDate) = ''May'' THEN ''4''              

       --                                                     WHEN  datename(month, ifbc.PaymentDate) = ''June'' THEN ''5''            

       --                                                     WHEN  datename(month, ifbc.PaymentDate) = ''July'' THEN ''6''              

       --                                                     WHEN  datename(month, ifbc.PaymentDate) = ''August'' THEN ''7''            

       --                                                     WHEN  datename(month, ifbc.PaymentDate) = ''September'' THEN ''8''              

       --                                                     WHEN  datename(month, ifbc.PaymentDate) = ''October'' THEN ''9''            

       --                                                     WHEN  datename(month, ifbc.PaymentDate) = ''November'' THEN ''10''             

       --                                                     WHEN  datename(month, ifbc.PaymentDate) = ''December'' THEN ''11''

       --                                         END

 

       order by datepart(year, ifbc.PaymentDate),month(ifbc.PaymentDate),PhaseCode

'

 

Print @SQL

EXEC(@SQL)

 