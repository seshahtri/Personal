DECLARE @pDateStart varchar (50);
DECLARE @pDateEnd varchar (50);
DECLARE @InvoiceStatus nvarchar (1000);
DECLARE @CurrencyCode varchar (50);
DECLARE @SQL VARCHAR(4000);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;

--SET @pDateStart='03/01/2021';
--SET @pDateEnd='02/28/2022';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD'; 

SET @SQL='

EXECUTE AS USER=''admin''
	SELECT  
		  
		MIN(ili.TimekeeperName) as ''Timekeeper Name'',   
		MIN(ili.VendorParentName) as ''Vendor Name'',   
		MIN(ili.RoleName) as ''Role Name'',   
		MIN(ex.CurrencyCode) as ''Currency Code'',   
		SUM(ili.HoursForRates) as Hours,   
		SUM(ili.GrossFeeAmountForRates * ISNULL(ex.ExchangeRate, 1)) as ''Fees''
	FROM V_InvoiceTimekeeperSummary ili  
		INNER JOIN PracticeAreaAndAllDescendants pad 
		ON ili.PracticeAreaId = pad.ChildPracticeAreaId  
		INNER JOIN (SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel   
					FROM fn_GetRollupPracticeAreasWithSecurity (-1, ''|'',-1,0)) pa 
					ON pad.PracticeAreaId = pa.RollupPracticeAreaId  
		INNER JOIN BusinessUnitAndAllDescendants bud 
		ON ili.BusinessUnitId = bud.ChildBusinessUnitId  
		INNER JOIN (SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel   
					FROM fn_GetRollupBusinessUnitsWithSecurity2 (-1, ''|'',-1,0)) bu 
					ON bud.BusinessUnitId = bu.RollupBusinessUnitId  
		INNER JOIN ExchangeRateDim ex 
		ON ili.ExchangeRateDate = ex.ExchangeRateDate  
	WHERE ili.InvoiceStatus IN (''' + @InvoiceStatus + ''') 
		AND ex.CurrencyCode = ''' + @CurrencyCode + '''
		--AND ex.CurrencyId = 1    
		AND (ili.PaymentDate >= ''' + @pDateStart + ''' AND ili.PaymentDate<= ''' + @pDateEnd + ''')  
		AND ili.HoursForRates>0   
		--AND ili.vendorid = 70237      
		AND ili.vendorid = ^ParamOne^ 
		--AND ili.roleid = 30648
	    AND ili.roleid = ^ParamTwo^
	GROUP BY ili.TimekeeperId,   
		ili.TimekeeperRoleId  
	ORDER BY SUM(ili.HoursForRates) desc'

Print @SQL
EXEC(@SQL)