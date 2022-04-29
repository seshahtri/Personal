--Use C00348_IOD_DataMart;

DECLARE @CurrencyCode varchar (50);
DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @InvoiceStatus varchar (MAX);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @CurrencyCode= ^Currency^;
SET @InvoiceStatus= ^InvoiceStatus^;

--SET @CurrencyCode ='USD';
--SET @pDateStart='3/1/2021';
--SET @pDateEnd='2/28/2022';
--SET @InvoiceStatus = 'Paid'',''Processed';


SET @SQL = '
execute as user = ''admin''
select
datepart(year, ifbc.PaymentDate)  AS Year , 
datename(month, ifbc.PaymentDate) AS Month,
PhaseCode as [Phase Code],
ed.CurrencyCode as [Currency Code], 
Sum(ifbc.GrossFeeAmountForRates*ISNULL(ed.ExchangeRate,1)) as ''Fees'',
count(distinct(matterId)) as ''# of Matters'',
count(distinct(invoiceId)) as ''# of Invoices''
from V_InvoiceFeeBillCodeSummary ifbc
join ExchangeRateDim ed on ed.ExchangeRateDate = ifbc.ExchangeRateDate
INNER JOIN BusinessUnitAndAllDescendants B on b.childbusinessunitid=ifbc.BusinessUnitId
inner join 
(SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''-1'', ''|'',-1,0)) ba on ba.RollupBusinessUnitId=b.BusinessUnitId
INNER JOIN PracticeAreaAndAllDescendants P on P.ChildPracticeAreaId=ifbc.PracticeAreaId
INNER JOIN 
(
SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',-1,1)) pa on pa.RollupPracticeAreaId=p.PracticeAreaId

WHERE ifbc.InvoiceStatus IN ('''+@InvoiceStatus+''')
AND ifbc.PaymentDate BETWEEN  '''+@pDateStart+''' AND '''+@pDateEnd+'''
AND ed.CurrencyCode = '''+@CurrencyCode+'''
AND ifbc.Category =''Fee''
--AND hours > 0.01
AND PhaseCode is NOT NULL
AND TimekeeperRoleId IS NOT NULL
--AND ifbc.PracticeAreaId in (select PracticeAreaId from PracticeAreaDim where Path like ''%36377%'')
--AND ifbc.BusinessUnitId in (select BusinessUnitId from BusinessUnitDim where Path like ''%16621%'') 
--AND ifbc.MatterStatus = ''Closed''
--AND ifbc.MatterId = 15866978
--AND ifbc.MatterOwnerId = 1147300
--AND ifbc.VendorId = 44228
--AND ifbc.VendorType = ''Law Firm''
--and ifbc.matterdf01 = ''USA'' -- Country
--and ifbc.matterdf02 = ''Unspecified'' -- Coverage Group
--and ifbc.matterdf03 = ''AB'' -- Coverage Type
--and ifbc.matterdf04 = ''AL'' -- Benefit State
--and ifbc.matterdf05 = ''AL''  -- Accident State
--and ifbc.matterdf06 = ''RE'' -- Status Code
--and ifbc.matterdf07 = ''003632421711GB01'' -- Claim Number
--and ifbc.matterdf08 like  ''GB-Houston%'' -- GB Branch Name
--and ifbc.matterdf09 = ''000216'' -- GB Branch Number
Group by    PhaseCode,datepart(year, ifbc.PaymentDate), datename(month, ifbc.PaymentDate), ed.CurrencyCode
ORDER BY  year,CASE  WHEN  datename(month, ifbc.PaymentDate) = ''January'' THEN ''1''   
                               WHEN  datename(month, ifbc.PaymentDate) = ''February'' THEN ''2'' 
                               WHEN  datename(month, ifbc.PaymentDate) = ''March'' THEN ''3''   
                               WHEN  datename(month, ifbc.PaymentDate) = ''April'' THEN ''4'' 
                               WHEN  datename(month, ifbc.PaymentDate) = ''May'' THEN ''5''   
                               WHEN  datename(month, ifbc.PaymentDate) = ''June'' THEN ''6'' 
                               WHEN  datename(month, ifbc.PaymentDate) = ''July'' THEN ''7''   
                               WHEN  datename(month, ifbc.PaymentDate) = ''August'' THEN ''8'' 
                               WHEN  datename(month, ifbc.PaymentDate) = ''September'' THEN ''9''   
                               WHEN  datename(month, ifbc.PaymentDate) = ''October'' THEN ''10'' 
                               WHEN  datename(month, ifbc.PaymentDate) = ''November'' THEN ''11''   
                               WHEN  datename(month, ifbc.PaymentDate) = ''December'' THEN ''12''  END, PhaseCode
'
print(@SQL);
exec(@SQL);