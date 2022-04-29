EXEC AS USER = 'admin'
--use C00348_IOD_DataMart;

DECLARE @pDateStart varchar (MAX);
DECLARE @pDateEnd varchar (MAX);
DECLARE @DateField varchar (MAX);
DECLARE @InvoiceStatus nvarchar (MAX);
DECLARE @CurrencyCode varchar (MAX);
DECLARE @SQL VARCHAR(MAX);



SET @pDateStart=^StartDate^;
SET @pDateEnd=^EndDate^;
SET @InvoiceStatus=^InvoiceStatus^;
SET @CurrencyCode=^Currency^;
SET @DateField='PaymentDate';

--SET @pDateStart='04/1/2021';
--SET @pDateEnd='03/31/2022';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode= 'USD';
--SET @DateField='PaymentDate';




Set @SQL = 
'
SELECT
bu.RollupBusinessUnitName as [GB Client],
--min(ex.CurrencyCode) as [Currency Code],
case when min(ex.currencycode) is  null then '''' else min(ex.currencycode) end as [Currency Code],
count(distinct(m.matterid)) as [Matters],
sum(case when InvoiceStatus in ('''+@InvoiceStatus+''') and '+@DateField+' <= '''+@pDateEnd+''' then m.Amount * isnull(ex.ExchangeRate,1) ELSE CAST(NULL AS FLOAT) END) as [Spend],
sum(case when InvoiceStatus in ('''+@InvoiceStatus+''') and '+@DateField+' <= '''+@pDateEnd+''' then m.hours ELSE CAST(NULL AS FLOAT) END) as [Hours]
FROM V_MatterSpendSummary m
INNER JOIN [dbo].BusinessUnitAndAllDescendants bud ON (m.BusinessUnitId = bud.ChildBusinessUnitId)
INNER JOIN ( SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel

  FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''-1'', ''|'',-1,1)


) bu ON (bud.BusinessUnitId = bu.RollupBusinessUnitId)
LEFT JOIN [dbo].ExchangeRateDim ex ON (m.ExchangeRateDate = ex.ExchangeRateDate)
INNER JOIN [dbo].PracticeAreaAndAllDescendants pad ON (m.PracticeAreaId = pad.ChildPracticeAreaId)
INNER JOIN (
SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (^ParamOne^, ''|'',^ParamTwo^,0)
  --FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (42406, ''|'',42318,0)
) pa ON (pad.PracticeAreaId = pa.RollupPracticeAreaId)
where (((CASE WHEN (ex.CurrencyCode = '''+@CurrencyCode+''') THEN 1 WHEN NOT (ex.CurrencyCode = '''+@CurrencyCode+''') THEN 0 ELSE NULL END) IS NULL)
OR (ex.CurrencyCode = '''+@CurrencyCode+'''))
and m.MatterOpenDate <= '''+@pDateEnd+'''
AND (m.MatterCloseDate > '''+@pDateEnd+''' OR MatterCloseDate IS NULL)


GROUP BY bu.RollupBusinessUnitName,bu.RollupBusinessUnitId
ORDER BY
Matters desc
'
print(@SQL)
EXEC(@SQL)