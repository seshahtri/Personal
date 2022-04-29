--use DEV044_IOD_DataMart;

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
--SET @pDateStart='2017-01-01 00:00:00.00'; 
--SET @pDateEnd ='2017-12-31 23:59:59.99';
--SET @InvoiceStatus ='Paid'',''Processed';

SET @SQL = '


IF OBJECT_ID(''tempdb..#KpiDataTest'') IS NOT NULL DROP TABLE #KpiDataTest
--drop table #KpiDataTest 
  exec as user = ''admin'' 
SELECT 
 
  RoleName, 
  currencycode as [Currency Code],
   Fees as [Total Fees], 
  (
    Fees / SUM(Fees) OVER (PARTITION BY 1)
  ) * 100 [ % of Total Fees], 
  Hours, 
  Matterid as [ # of Matters]
  , 
  Fees / Units as [Average Rate] INTO #KpiDataTest
from 
  (
    select 
      roleId as ''RoleId'', 
      roleName as ''RoleName'',  c.CurrencyCode,
      sum(netfeeamount) as ''Fees'', 
      SUM(Units) AS Units, 
      SUM(hours) as Hours, 
      count(distinct matterid) Matterid 
    from 
      V_InvoiceLineItemPostReviewFact [V_InvoiceLineItemSpendFactWithCurrency] 
      INNER JOIN dbo.Currency C ON C.CurrencyCode = '''+@CurrencyCode+''' 
    WHERE 
      (
        ([V_InvoiceLineItemSpendFactWithCurrency].[InvoiceStatus] in ('''+@InvoiceStatus+'''))
		and [V_InvoiceLineItemSpendFactWithCurrency].[MatterID]=^ParamOne^
		--and [V_InvoiceLineItemSpendFactWithCurrency].[MatterID]=''3686999''
        AND ([V_InvoiceLineItemSpendFactWithCurrency].[Category] = ''Fee'') 
        AND (NOT ([V_InvoiceLineItemSpendFactWithCurrency].[TimekeeperRoleId] IS NULL)
        ) 
        AND ([V_InvoiceLineItemSpendFactWithCurrency].[Hours] > 0.01) 
        AND ((CASE WHEN (([V_InvoiceLineItemSpendFactWithCurrency].[InvoiceDate] >=  '''+@pDateStart+''' ) 
              AND ([V_InvoiceLineItemSpendFactWithCurrency].[InvoiceDate] <= DATEADD(second,-1,DATEADD(day, 1, CAST('''+@pDateEnd+''' as datetime)
                  )
                )
              )
            ) THEN 1 ELSE 0 END
          ) = 1
        ) 
        
      ) 
    GROUP BY 
      c.[CurrencySymbol], c.CurrencyCode,
      [V_InvoiceLineItemSpendFactWithCurrency].[RoleId], 
      rolename
  ) s 
select 
  * 
from 
  #KpiDataTest
  order by [Total Fees] desc
  '
  print(@SQL)
  EXEC(@SQL)