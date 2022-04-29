--use Q5_C00348_IOD_DataMart

execute as user = 'admin'  

DECLARE @pDateStart varchar (50);
DECLARE @pDateEnd varchar (50);
DECLARE @InvoiceStatus nvarchar (1000);
DECLARE @CurrencyCode varchar (50);
DECLARE @SQL VARCHAR(4000);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;

--SET @pDateStart='1/1/2017';
--SET @pDateEnd='12/31/2017';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';

SET @SQL='
	select    
		UTBMSTaskCode as ''Task Code'',   
		ed.CurrencyCode as ''Currency Code'',    
		datepart(year, ifbc.InvoiceDate)  AS Year,   
		datename(month, ifbc.InvoiceDate) AS Month,   
		Sum(ifbc.GrossFeeAmountForRates*ISNULL(ed.ExchangeRate,1)) as ''Fees''  
	from V_InvoiceFeeBillCodeSummary ifbc  
		join ExchangeRateDim ed on ed.ExchangeRateDate = ifbc.ExchangeRateDate  
		INNER JOIN BusinessUnitAndAllDescendants B on b.childbusinessunitid=ifbc.BusinessUnitId  
		inner join (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel  
					FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (-1, ''|'',-1,0)) ba on ba.RollupBusinessUnitId=b.BusinessUnitId  
		INNER JOIN PracticeAreaAndAllDescendants P on P.ChildPracticeAreaId=ifbc.PracticeAreaId  
		INNER JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel  
					FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',-1,1)) pa on pa.RollupPracticeAreaId=p.PracticeAreaId    
	WHERE ifbc.InvoiceStatus IN (''' + @InvoiceStatus + ''') 
		AND ifbc.InvoiceDate between (''' + @pDateStart + ''') and (''' + @pDateEnd + ''')  
		AND ed.CurrencyCode = ''' + @CurrencyCode + '''  
		AND ifbc.Category = ''Fee'' 
		AND hours > 0.01  
		--AND PhaseCode is NOT NULL  
		AND TimekeeperRoleId IS NOT NULL  
		AND MatterId = ^ParamOne^ 
		--AND MatterId = ''3686999''
		And PhaseCode = ^ParamTwo^
		--And PhaseCode = ''L100''
	Group by UTBMSTaskCode,datepart(year, ifbc.InvoiceDate), datename(month, ifbc.InvoiceDate), ed.CurrencyCode  
	ORDER BY UTBMSTaskCode,Year, 
		CASE  WHEN  datename(month, ifbc.InvoiceDate) = ''January'' THEN ''0''               
			  WHEN  datename(month, ifbc.InvoiceDate) = ''February'' THEN ''1''             
			  WHEN  datename(month, ifbc.InvoiceDate) = ''March'' THEN ''2''               
			  WHEN  datename(month, ifbc.InvoiceDate) = ''April'' THEN ''3''             
			  WHEN  datename(month, ifbc.InvoiceDate) = ''May'' THEN ''4''               
			  WHEN  datename(month, ifbc.InvoiceDate) = ''June'' THEN ''5''            
			  WHEN  datename(month, ifbc.InvoiceDate) = ''July'' THEN ''6''               
			  WHEN  datename(month, ifbc.InvoiceDate) = ''August'' THEN ''7''             
			  WHEN  datename(month, ifbc.InvoiceDate) = ''September'' THEN ''8''               
			  WHEN  datename(month, ifbc.InvoiceDate) = ''October'' THEN ''9''             
			  WHEN  datename(month, ifbc.InvoiceDate) = ''November'' THEN ''10''               
			  WHEN  datename(month, ifbc.InvoiceDate) = ''December'' THEN ''11''  
		END'

Print @SQL
EXEC(@SQL)