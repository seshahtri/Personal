--Base Level: Legal Spend Year to Year by Month

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
	SELECT  
		YEAR (ili.PaymentDate) as ''Year'', 
		DateName(month, DateAdd(month, MONTH(ili.PaymentDate), -1)) as ''Month'', 
		MIN(ex.CurrencyCode) as ''Currency Code'', 
		SUM(Amount) as ''Spend'', 
		SUM(Units) as ''Units''
	FROM V_InvoiceSummary ili   
		INNER JOIN BusinessUnitAndAllDescendants bu ON (ili.BusinessUnitId = bu.ChildBusinessUnitId)   
		INNER JOIN (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel   
	            FROM fn_GetRollupBusinessUnitsWithSecurity (-1, ''|'',-1,0) ) rbu ON (bu.BusinessUnitId = rbu.RollupBusinessUnitId)   
		LEFT JOIN ExchangeRateDim ex ON (ili.ExchangeRateDate = ex.ExchangeRateDate)   
		INNER JOIN PracticeAreaAndAllDescendants pa ON (ili.PracticeAreaId = pa.ChildPracticeAreaId)   
		INNER JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel   
	            FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',-1,1) ) rpa ON (pa.PracticeAreaId = rpa.RollupPracticeAreaId) 
	WHERE 
		ex.CurrencyCode = ''' + @CurrencyCode + ''' 
		AND InvoiceStatus IN (''' + @InvoiceStatus + ''')
	GROUP BY YEAR(PaymentDate), MONTH(PaymentDate), currencycode   
	ORDER BY 1,2'

Print @SQL
EXEC(@SQL)
