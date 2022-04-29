--Monthly Fees by Task-
--use [C00348_IOD_DataMart];

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
--SET @pDateEnd='3/31/2021';
--SET @InvoiceStatus = 'Paid'',''Processed';


SET @SQL = '

exec as user = ''admin''
select UtbmsTaskCode,
datepart(year, f.PaymentDate)  AS Year,
datename(month, f.PaymentDate) AS Month,
ed.CurrencyCode as [Currency Code], 
sum(f.amount) as ''Fees''
from V_InvoiceLineItemSpendFactWithCurrency f
join ExchangeRateDim ed on ed.ExchangeRateDate = f.ExchangeRateDate
INNER JOIN PracticeAreaAndAllDescendants pa ON f.PracticeAreaId = pa.ChildPracticeAreaId
  INNER JOIN (
  SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
  FROM dbo.fn_GetRollupPracticeAreasWithSecurity (''-1'', ''|'',-1,0)
) p ON pa.PracticeAreaId = p.RollupPracticeAreaId
  INNER JOIN dbo.BusinessUnitAndAllDescendants ba ON (f.BusinessUnitId = ba.ChildBusinessUnitId)
  INNER JOIN (
  SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
  FROM dbo.fn_GetRollupBusinessUnitsWithSecurity (''-1'', ''|'',-1,0)
) b ON (ba.BusinessUnitId = b.RollupBusinessUnitId)
  INNER JOIN dbo.CostCenterAndAllDescendants ca ON (f.CostCenterId = ca.ChildCostCenterId)
  INNER JOIN (
  SELECT RollupCostCenterId, RollupCostCenterName, RollupCostCenterPath, RollupCostCenterDisplayPath, RollupCostCenterLevel
  FROM dbo.fn_GetRollupCostCenters (''-1'', ''|'',-1,0)
) c ON (ca.CostCenterId = c.RollupCostCenterId) 
where  UtbmsTaskCode is not null 
and phasecode is not null 
AND phasecode=''L100''
and f.InvoiceStatus in ('''+@InvoiceStatus+''')
and Paymentdate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
AND CATEGORY=''Fee''
and TimekeeperRoleId is not null
and (hours)>0
and sumrate>0
and f.CurrencyCode='''+@CurrencyCode+'''
and ed.CurrencyCode='''+@CurrencyCode+'''
Group by UtbmsTaskCode,datepart(year, f.PaymentDate), datename(month, f.PaymentDate), ed.CurrencyCode
order by UtbmsTaskCode,YEAR ASC,
 CASE  WHEN  datename(month, f.PaymentDate) = ''January'' THEN ''0''
							   WHEN  datename(month, f.PaymentDate) = ''February'' THEN ''1'' 
							   WHEN  datename(month, f.PaymentDate) = ''March'' THEN ''2''
							   WHEN  datename(month, f.PaymentDate) = ''April'' THEN ''3'' 
							   WHEN  datename(month, f.PaymentDate) = ''May'' THEN ''4''
							   WHEN  datename(month, f.PaymentDate) = ''June'' THEN ''5'' 
							   WHEN  datename(month, f.PaymentDate) = ''July'' THEN ''6''
							   WHEN  datename(month, f.PaymentDate) = ''August'' THEN ''7'' 
							   WHEN  datename(month, f.PaymentDate) = ''September'' THEN ''8''
							   WHEN  datename(month, f.PaymentDate) = ''October'' THEN ''9'' 
							   WHEN  datename(month, f.PaymentDate) = ''November'' THEN ''10''
  						       WHEN  datename(month, f.PaymentDate) = ''December'' THEN ''11''  END  DESC
'
print(@SQL);
exec(@SQL);