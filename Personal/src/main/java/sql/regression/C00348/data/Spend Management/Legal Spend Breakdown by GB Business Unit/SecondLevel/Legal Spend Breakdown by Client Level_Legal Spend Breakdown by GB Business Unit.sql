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
	    bu.RollupBusinessUnitName, ed.CurrencyCode as ''Currency Code'', 
	    Sum(invs.Amount*ISNULL(ed.ExchangeRate,1)) as ''Total Spend'', 
	    Sum(invs.Amount*ISNULL(ed.ExchangeRate,1))/overall.OverallSpend * 100 as ''% Of Total'', 
	    Sum(invs.NetFeeAmount*ISNULL(ed.ExchangeRate,1)) as ''Fees'',
	    Sum(invs.NetExpAmount*ISNULL(ed.ExchangeRate,1)) as ''Expenses''
	from V_InvoiceSummary invs
	    join ExchangeRateDim ed on ed.ExchangeRateDate = invs.ExchangeRateDate
	    INNER JOIN BusinessUnitAndAllDescendants bud ON invs.BusinessUnitId = bud.ChildBusinessUnitId
	    INNER JOIN (
	        SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
	        FROM fn_GetRollupBusinessUnitsWithSecurity (-1, ''|'',^ParamOne^,1)
	                ) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
	    INNER JOIN PracticeAreaAndAllDescendants P on P.ChildPracticeAreaId=invs.PracticeAreaId
	        INNER JOIN 
	        (
	        SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
	        FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',^ParamTwo^,0)
	        ) pa on pa.RollupPracticeAreaId=p.PracticeAreaId
	    INNER JOIN (
	        SELECT
	            Sum(invs.Amount*ISNULL(ed.ExchangeRate,1)) OverallSpend
	        FROM V_InvoiceSummary invs
	            join ExchangeRateDim ed on ed.ExchangeRateDate = invs.ExchangeRateDate
	            INNER JOIN BusinessUnitAndAllDescendants bud ON invs.BusinessUnitId = bud.ChildBusinessUnitId
	            INNER JOIN (
	                SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
	                FROM fn_GetRollupBusinessUnitsWithSecurity (-1, ''|'',^ParamOne^,0)
	                        ) bu ON bud.BusinessUnitId = bu.RollupBusinessUnitId
	            INNER JOIN PracticeAreaAndAllDescendants P on P.ChildPracticeAreaId=invs.PracticeAreaId
	                INNER JOIN 
	                (
	                SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
					FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',^ParamTwo^,0)
	                ) pa on pa.RollupPracticeAreaId=p.PracticeAreaId
	        WHERE 
	            invs.InvoiceStatus IN (''' + @InvoiceStatus + ''')
	            AND (invs.PaymentDate between ''' + @pDateStart + ''' and ''' + @pDateEnd + ''')
	            AND ed.CurrencyCode = ''' + @CurrencyCode + '''
	    )overall on 1=1
	    
	WHERE 
	    invs.InvoiceStatus IN (''' + @InvoiceStatus + ''')
	    AND (invs.PaymentDate between ''' + @pDateStart + ''' and ''' + @pDateEnd + ''')
	    AND ed.CurrencyCode = ''' + @CurrencyCode + '''
	Group by    bu.RollupBusinessUnitName,ed.CurrencyCode,overall.OverallSpend
	ORDER BY [Total Spend] desc'

Print @SQL
EXEC(@SQL)