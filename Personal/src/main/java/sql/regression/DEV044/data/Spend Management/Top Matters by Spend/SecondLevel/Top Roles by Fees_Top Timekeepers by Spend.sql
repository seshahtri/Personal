--use DEV044_IOD_DataMart

DECLARE @CurrencyCode  varchar (50);
DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @InvoiceStatus varchar (MAX);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @CurrencyCode= ^Currency^;
SET @InvoiceStatus= ^InvoiceStatus^;

--SET @CurrencyCode ='USD';
--SET @pDateStart='2017-01-01'; 
--SET @pDateEnd ='2017-12-31';
--SET @InvoiceStatus ='Paid'',''Processed';

SET @SQL = '
exec as user=''admin''
SELECT
   
    MIN(TimekeeperName) AS [Timekeeper Name],
min( VendorParentName) as [Vendor Name] ,
min( RoleName) AS [Role Name],
min( ER.CurrencyCode) AS [Currency Code],
    SUM(GrossFeeAmountForRates * ISNULL(ExchangeRate, 1)) AS [Fees],
    SUM(HoursForRates) AS [Hours ],
    COUNT_BIG(DISTINCT MatterId) AS [Matters],
    SUM(GrossFeeAmountForRates * ISNULL(ExchangeRate,1 ))/SUM(HoursForRates) AS [Fee Rate]  
FROM
    V_InvoiceTimeKeeperSummary ITS
JOIN PracticeAreaAndAllDescendants PAD ON ITS.PracticeAreaId = PAD.ChildPracticeAreaId
JOIN (SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',-1,0)) PAS ON PAD.PracticeAreaID = PAS.RollupPracticeAreaId
JOIN BusinessUnitAndAllDescendants BAD ON ITS.BusinessUnitId = BAD.ChildBusinessUnitId
JOIN ( SELECT 1 BUCheck, RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''-1'', ''|'',''-1'',0)) BAS ON BAD.BusinessUnitId = BAS.RollupBusinessUnitId
JOIN ExchangeRateDim ER ON ITS.ExchangeRateDate = ER.ExchangeRateDate
WHERE
    TimeKeeperRoleID <> -1
	and  its.MatterID = ^ParamOne^
  --and its.MatterID = ''3686999''
    and RoleId = ^Paramtwo^
    --and RoleId = 24
    AND InvoiceStatus IN ('''+@InvoiceStatus+''')
   --AND InvoiceDate>=(select DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-11, 0) )
   --AND InvoiceDate<= (SELECT CAST(eomonth(GETDATE()) AS datetime))
    AND InvoiceDate between '''+@pDateStart+''' and '''+@pDateEnd+'''
    AND ER.CurrencyCode = '''+@CurrencyCode+'''
    AND Hours >0
    AND FeeRate >0
GROUP BY
    TimekeeperROLeid--,VendorParentName, RoleName, ER.CurrencyCode
HAVING
    SUM(HoursForRates) > 0.001
ORDER BY Fees DESC
'
print(@SQL)
EXEC(@SQL)