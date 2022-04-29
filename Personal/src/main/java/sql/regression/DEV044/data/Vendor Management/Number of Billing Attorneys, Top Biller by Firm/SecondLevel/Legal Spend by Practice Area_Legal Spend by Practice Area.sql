--USE DEV044_IOD_DataMart

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

--SET @pDateStart='1/1/2017';
--SET @pDateEnd='12/31/2017';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';

SET @SQL='
Select 
	pa.RollupPracticeAreaName as ''Practice Area '',
	ed.CurrencyCode as ''Currency Code'', 
	Sum(invs.Amount*ISNULL(ed.ExchangeRate,1)) as ''Total Spend''
from V_InvoiceSummary invs
	join ExchangeRateDim ed on ed.ExchangeRateDate = invs.ExchangeRateDate
	INNER JOIN BusinessUnitAndAllDescendants B on b.childbusinessunitid=invs.BusinessUnitId
	INNER JOIN 
			  (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
			   FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (-1, ''|'',-1,0)) ba on ba.RollupBusinessUnitId=b.BusinessUnitId
	INNER JOIN PracticeAreaAndAllDescendants P on P.ChildPracticeAreaId=invs.PracticeAreaId
	INNER JOIN 
			 (
			  SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
		      --FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',32475,1)) pa on pa.RollupPracticeAreaId=p.PracticeAreaId
			  FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',^ParamTwo^,1)) pa on pa.RollupPracticeAreaId=p.PracticeAreaId
WHERE 
    invs.InvoiceStatus IN (''' + @InvoiceStatus + ''')
	--And vendorId=1044
	And vendorId=^ParamOne^
	AND (invs.Invoicedate between ''' + @pDateStart + ''' and ''' + @pDateEnd + ''')
	AND ed.CurrencyCode = ''' + @CurrencyCode + '''
GROUP BY pa.RollupPracticeAreaName,ed.CurrencyCode
ORDER BY [Total Spend] desc
'
Print @SQL
EXEC(@SQL)