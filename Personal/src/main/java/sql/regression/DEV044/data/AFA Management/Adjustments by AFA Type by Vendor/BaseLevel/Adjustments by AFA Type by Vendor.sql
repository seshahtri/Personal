DECLARE @pDateStart varchar (50);
DECLARE @pDateEnd varchar (50);
DECLARE @InvoiceStatus nvarchar (1000);
DECLARE @CurrencyCode varchar (50);
DECLARE @SQL VARCHAR(4000);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;

--SET @pDateStart='1/1/2017';
--SET @pDateEnd='12/31/2017';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';

SET @SQL='

EXEC AS USER =''admin''
--Adjustments by AFA Type by Vendor--
SELECT
   v.vendorname as [Vendor Name],
   ils.AfaRuleTypes as ''AFA Type'',
   CAST( sum(ils.AfaFeeAmount * - 1) AS FLOAT ) as ''AFA Adjustments'',
   COUNT(distinct ils.matterid) as ''# Matters'' 
FROM
   V_InvoiceLineItemSpendFactWithCurrency ils 
   JOIN
      vendordim v 
      on v.vendorid = ils.vendorid 
   JOIN
      costcenterdim c 
      on c.costcenterid = ils.costcenterid 		
      LEFT 
   JOIN
      (
         SELECT
            top 100000 v.vendorid,
            v.vendorname,
            CAST( sum(ils.AfaFeeAmount * - 1) AS FLOAT ) as ''Adjustments'' 
         FROM
            V_InvoiceLineItemSpendFactWithCurrency ils 
            JOIN
               vendordim v 
               on v.vendorid = ils.vendorid 
            JOIN
               costcenterdim c 
               on c.costcenterid = ils.costcenterid 					
         WHERE
            ils.InvoiceStatus IN ('''+@InvoiceStatus+''')
            AND ils.InvoiceStatusDate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
            AND ils.currencycode = '''+@CurrencyCode+''' 		
            AND ils.AfaRuleTypes IS NOT NULL 
         group by
            v.vendorid,
            v.vendorname 
         order by
            Adjustments desc 
      )
      ad 
      on ad.vendorid = ils.vendorid 
WHERE
   ils.InvoiceStatus IN ('''+@InvoiceStatus+''')
   AND ils.InvoiceStatusDate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+''' 
   AND ils.currencycode = '''+@CurrencyCode+'''
   AND ils.AfaRuleTypes IS NOT NULL 
   AND ad.adjustments IS NOT NULL 	
group by
   v.vendorname,
   ils.AfaRuleTypes,
   ad.adjustments 
order by
   ad.adjustments desc'

Print @SQL
EXEC(@SQL)