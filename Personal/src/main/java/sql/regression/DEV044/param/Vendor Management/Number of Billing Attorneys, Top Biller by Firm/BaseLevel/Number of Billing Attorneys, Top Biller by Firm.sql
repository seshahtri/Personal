DECLARE @pDateStart varchar (MAX);
DECLARE @pDateEnd  varchar (MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @CurrencyCode varchar (50);
DECLARE @CurrencyId varchar;
DECLARE @InvoiceStatus varchar (MAX);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @CurrencyCode= ^Currency^;
--SET @InvoiceStatus= ^InvoiceStatus^;

--SET @pDateStart='01/01/2017';
--SET @pDateEnd ='12/31/2017';
--SET @CurrencyCode ='USD';
SET @InvoiceStatus ='''Paid'',''Processed''';

SET @SQL=
'

	EXECUTE AS USER=''Admin''
	SELECT Top 1
	V.vendorId as [Law FirmId],       
    V.vendorname as [Law Firm],
    a.FullName as [Top Billing Attorney],
	E.CurrencyCode as [Currency Code],
    CAST(a.TopBillingAttorneyFees AS FLOAT) as [Top Billing Attorney Fees],
    CAST(CAST(a.TopBillingAttorneyFees AS FLOAT)/CAST(SUM(NetFeeAmount) AS FLOAT) AS FLOAT)*100 [Top Billing Attorney % of Law Firm Fees],
    Count (DISTINCT il.timekeeperid) as [Number of Attorneys Billing],
    CAST(SUM(NetFeeAmount) AS FLOAT) as [Law Firm Fees]
FROM  invoicedim i
JOIN ExchangeRateDim E ON CAST(I.ExchangeRateDate AS DATE) = E.ExchangeRateDate  
JOIN invoicelineitemfact il on il.invoiceid= i.invoiceid
JOIN Vendordim V on V.vendorid = il.vendorid
JOIN  BillCodeDim BC ON BC.BillCodeId = il.BillCodeId 
JOIN TimekeeperDim tk on tk.TimekeeperId=il.TimekeeperId  LEFT JOIN (
       SELECT 
              tk.TimekeeperId,
              tk.FullName,
              il.VendorId,
              CAST(SUM(il.NetFeeAmount) AS FLOAT) TopBillingAttorneyFees,
        ROW_NUMBER() OVER (PARTITION BY il.VendorId ORDER BY SUM(il.NetFeeAmount) DESC) AS RowNumber
       FROM invoicedim i
JOIN ExchangeRateDim E ON CAST(I.ExchangeRateDate AS DATE) = E.ExchangeRateDate  
JOIN invoicelineitemfact il on il.invoiceid= i.invoiceid
JOIN  BillCodeDim BC ON BC.BillCodeId = il.BillCodeId 
JOIN TimekeeperDim tk on tk.TimekeeperId=il.TimekeeperId
       WHERE 
              E.CurrencyId = 1
              AND i.InvoiceStatus in ('+@InvoiceStatus+')
               AND i.InvoiceDate between '''+@pDateStart+''' AND '''+@pDateEnd+'''
			 --AND InvoiceDate>=(select DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-11, 0) ) and InvoiceDate<= (SELECT CAST(eomonth(GETDATE()) AS datetime))
			 AND BC.Category = ''Fee''
              AND tk.TimekeeperId is not null              
   GROUP BY tk.TimekeeperId,
              tk.FullName,
              il.VendorId
              ) a on a.VendorId=il.VendorId
WHERE 
       E.CurrencyId = 1
       AND i.InvoiceStatus in ('+@InvoiceStatus+')
       AND i.InvoiceDate between '''+@pDateStart+''' AND '''+@pDateEnd+'''
	   --AND InvoiceDate>=(select DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-11, 0) ) and InvoiceDate<= (SELECT CAST(eomonth(GETDATE()) AS datetime))
       AND BC.Category = ''Fee''
       AND tk.TimekeeperId is not null    
       AND a.RowNumber=1
GROUP BY
	   V.vendorId,
       V.vendorname,
       a.FullName,	
       a.TopBillingAttorneyFees,
	   E.CurrencyCode
ORDER BY [Number of Attorneys Billing] Desc

'
PRINT (@SQL)
EXEC(@SQL)