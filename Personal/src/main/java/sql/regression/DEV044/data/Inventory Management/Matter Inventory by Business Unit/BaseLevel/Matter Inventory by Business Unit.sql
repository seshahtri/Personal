--use DEV044_IOD_DataMart;

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
--SET @pDateStart='1/1/2017';
--SET @pDateEnd='12/31/2017';
--SET @InvoiceStatus = 'Paid'',''Processed';

SET @SQL='

EXEC AS USER = ''admin''

SELECT 
       tm.RollupBusinessUnitName as [Business Unit],
          buu.CurrencyCode as [Currency Code],
       tm.TotalMatters as [Matters],
       buu.TotalAmount as [Spend], 
          buu.TotalHours as [Hours]
FROM V_MatterSpendSummary m
       INNER JOIN dbo.fn_GetBusinessUnitsWithChildrenWithRollupFields(-1, ''|'',-1, 1) bu ON m.BusinessUnitId = bu.ChildBusinessUnitId
       JOIN(
              SELECT bu.RollupBusinessUnitName, COUNT(DISTINCT m.MatterId) TotalMatters
              FROM V_MatterWithSecurity m
              INNER JOIN dbo.fn_GetBusinessUnitsWithChildrenWithRollupFields(-1, ''|'',-1, 1) bu ON m.BusinessUnitId = bu.ChildBusinessUnitId
              WHERE m.MatterOpenDate <= '''+@pDateEnd+'''
			  AND (m.MatterCloseDate > '''+@pDateEnd+''' OR MatterCloseDate IS NULL)   -- Newly added to return only Open Matters data
			               GROUP BY bu.RollupBusinessUnitName
              ) tm on tm.RollupBusinessUnitName=bu.RollupBusinessUnitName
       LEFT JOIN (
       SELECT bu.RollupBusinessUnitName, SUM(ili.Amount) TotalAmount, SUM(ili.hours) TotalHours, MAX(ili.CurrencyCode) CurrencyCode
              FROM V_MatterWithSecurity m
              INNER JOIN dbo.fn_GetBusinessUnitsWithChildrenWithRollupFields(-1, ''|'',-1, 1) bu ON m.BusinessUnitId = bu.ChildBusinessUnitId
              LEFT JOIN (
                     SELECT DISTINCT
                     ili.MatterId,
                     SUM(ili.Amount) Amount, 
                     SUM(ili.hours) hours,
                                  ili.currencycode
                     FROM V_InvoiceLineItemSpendFactWithCurrency ili
                     WHERE 
                     InvoiceStatus IN ('''+@InvoiceStatus+''') 
					 AND CurrencyCode='''+@CurrencyCode+'''
                     AND InvoiceDate <= '''+@pDateEnd+'''
                     GROUP BY ili.MatterId, ili.currencycode
                     ) ili on ili.MatterId=m.MatterId
              WHERE m.MatterOpenDate <= '''+@pDateEnd+'''
			 AND (m.MatterCloseDate > '''+@pDateEnd+''' OR MatterCloseDate IS NULL) -- Newly added to return only Open Matters data
			 GROUP BY bu.RollupBusinessUnitName--, ili.CurrencyCode
			 
       ) buu on buu.RollupBusinessUnitName=bu.RollupBusinessUnitName --where buu.TotalAmount is not null
GROUP BY
       tm.RollupBusinessUnitName,
          buu.CurrencyCode,
       buu.TotalAmount, buu.TotalHours, tm.TotalMatters
ORDER BY
tm.TotalMatters desc
'
print(@SQL)
exec(@SQL)
