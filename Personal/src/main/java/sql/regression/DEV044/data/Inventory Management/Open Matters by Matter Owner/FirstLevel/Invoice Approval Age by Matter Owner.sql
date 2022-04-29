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
--SET @pDateStart='2017-01-01';
--SET @pDateEnd ='2017-12-31' ;
--SET @InvoiceStatus ='Paid'',''Processed';



SET @SQL = '
exec as user = ''admin''
SELECT 
MatterOwnerName [Matter Owner], TotalInvoices [Total Invoices], AverageDays [Average Days], MaxDays [Max Days], MinDays [Min Days] FROM 
( SELECT A1.MatterOwnerId, A1.TotalInvoices, A1.AverageDays, B1.MaxDays, B1.MinDays 
FROM (
SELECT MatterOwnerId,COUNT(DISTINCT A.InvoiceId) TotalInvoices, ROUND(CAST(SUM(DateDiff) AS FLOAT)/COUNT(DISTINCT A.InvoiceId),0) AverageDays 
FROM ( 
 SELECT DISTINCT MatterOwnerId, InvoiceId FROM  [dbo].[V_InvoiceSummary] ILI
WHERE Invoiceid IN (
SELECT DISTINCT InvoiceId
FROM
    [dbo].[V_InvoiceSummary] ILI
         INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId
INNER JOIN (
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',-1,0)
) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
WHERE 
    invoiceStatus IN ( ''Paid'',''Processed'' ) 
    and InvoiceDate between '''+@pDateStart+''' AND '''+@pDateEnd+'''
       and InReviewDate IS NOT NULL 
 GROUP BY 
 InvoiceId
HAVING (MAX(DATEDIFF(day,InReviewDate,ApprovedDate))) IS NOT NULL)) A JOIN (

SELECT DISTINCT InvoiceId, MAX(DATEDIFF(day,InReviewDate,ApprovedDate)) DateDiff
FROM
    [dbo].[V_InvoiceSummary] ILI
      INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId
INNER JOIN (
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',-1,0)
) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
WHERE 
    invoiceStatus IN   (''Paid'',''Processed'')
    and InvoiceDate between '''+@pDateStart+''' AND '''+@pDateEnd+'''
	AND MatterOwnerId = ^ParamOne^
	--AND MatterOwnerId = 742378
       and InReviewDate IS NOT NULL 
 GROUP BY 
 InvoiceId) B ON A.InvoiceId = B.InvoiceId
GROUP BY MatterOwnerId) A1   JOIN (


SELECT MatterOwnerId, COUNT (DISTINCT InvoiceID) TotalInvoices, MAX(DATEDIFF(day,InReviewDate,ApprovedDate)) MaxDays, 
MIN(DATEDIFF(day,InReviewDate,ApprovedDate)) MinDays
FROM     [dbo].[V_InvoiceSummary] ILI
       INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId
INNER JOIN (
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',-1,0)
) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
WHERE InvoiceID IN (
SELECT DISTINCT InvoiceId 
FROM
    [dbo].[V_InvoiceSummary] ILI
       INNER JOIN PracticeAreaAndAllDescendants pad ON ili.PracticeAreaId = pad.ChildPracticeAreaId
INNER JOIN (
SELECT 1 PACheck, RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM fn_GetRollupPracticeAreasWithSecurity2 (-1, ''|'',-1,0)
) pa ON pad.PracticeAreaId = pa.RollupPracticeAreaId
       -- ili        join [dbo].[V_MatterOwners] MO on ili.matterownerid = Mo.MatterOwnerName
WHERE 
    invoiceStatus IN  (''Paid'',''Processed'')
    and InvoiceDate between '''+@pDateStart+''' AND '''+@pDateEnd+'''
       and InReviewDate IS NOT NULL 
                

GROUP BY 
 InvoiceId
HAVING (MAX(DATEDIFF(day,InReviewDate,ApprovedDate))) IS NOT NULL)
GROUP BY MatterOwnerId ) B1 ON A1.MatterOwnerId = B1.MatterOwnerId  OR (A1.MatterOwnerId IS NULL AND B1.MatterOwnerId IS NULL)) AS IDS
left JOIN V_MatterOwners MO ON IDS.MatterOwnerId = MO.MatterOwnerId
ORDER BY TotalInvoices DESC

'
print(@SQL)
exec(@SQL)
