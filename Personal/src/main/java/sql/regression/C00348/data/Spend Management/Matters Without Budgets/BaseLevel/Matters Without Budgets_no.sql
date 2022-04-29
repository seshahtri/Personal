--Base Level: Matters Without Budgets

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

--SET @pDateStart='1/1/2020';
--SET @pDateEnd='12/31/2020';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';

SET @SQL='
SELECT 
	DISTINCT top 1000
    --MSS.MatterId as ''Matter Id'',
	MSS.MatterName as ''Matter Name'',
    MSS.MatterDF03 as ''Coverage Type'',
    MSS.MatterNumber as ''Matter Number'',
    MSS.MatterDF07 as ''Claim Number'',
    MSS.MatterDF08 as ''GB Branch Name'',
    MSS.MatterDF09 as ''GB Branch Number'',
    p.RollupPracticeAreaName as ''GB Client'',
    MSS.matterownername as ''Matter Owner Name'',
    MSS.MatterDF06 as ''Status Code'',
    MSS.MatterStatus as ''Matter Status'',
    inn.currencycode as ''Currency Code'',
    inn.Amount as ''Spend''
FROM V_MatterSpendSummary MSS
	inner join BusinessUnitAndAllDescendants bu on bu.ChildBusinessUnitId=MSS.BusinessUnitId
	inner join (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
				FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (-1, ''|'',-1,0)) b on bu.BusinessUnitId=b.RollupBusinessUnitId --replace 0 with 1 and apply BU filter
	inner join PracticeAreaAndAllDescendants pa on pa.childpracticeareaid=MSS.practiceareaid
	inner join (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
				FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',-1,1)) p on pa.practiceareaid=p.rolluppracticeareaid
	LEFT JOIN V_MATTERBUDGETINFO VM ON VM.MATTERID = MSS.MATTERID
	LEFT JOIN (
                SELECT DISTINCT
                    ili.MatterId,
                    ed.currencycode,
                    p.[RollupPracticeAreaName],
                    SUM(ili.Amount* ISNULL(ed.[ExchangeRate], 1)) Amount
                FROM
                    V_MatterSpendSummary ili
					JOIN Exchangeratedim ed on ed.ExchangeRateDate = ili.ExchangeRateDate
					JOIN BusinessUnitAndAllDescendants bu on bu.ChildBusinessUnitId=ili.BusinessUnitId
					JOIN (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
						  FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (-1, ''|'',-1,0)) b on bu.BusinessUnitId=b.RollupBusinessUnitId --replace 0 with 1 and apply BU filter
					JOIN PracticeAreaAndAllDescendants pa on pa.childpracticeareaid=ili.practiceareaid
					JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
                          FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',-1,1)) p on pa.practiceareaid=p.rolluppracticeareaid
                WHERE
                    InvoiceStatus IN (''' + @InvoiceStatus + ''') 
                    AND CurrencyCode = ''' + @CurrencyCode + '''
					AND (PaymentDate >= ''' + @pDateStart + ''' AND PaymentDate<= ''' + @pDateEnd + ''')
				GROUP BY ili.MatterId, ed.currencycode, p.[RollupPracticeAreaName], ili.MatterDF06
                 ) inn on inn.MatterId=mss.MatterId AND inn.[RollupPracticeAreaName] = p.[RollupPracticeAreaName]
WHERE 
	mss.MatterOpenDate <= ''' + @pDateEnd + '''
	AND (mss.MatterCloseDate >= ''' + @pDateEnd + '''   OR mss.MatterCloseDate IS NULL) and -- Newly added to return only Open Matters data
	vm.matterid is NULL
	order by inn.amount desc, MSS.MatterNumber desc
'

Print @SQL 
EXEC(@SQL)