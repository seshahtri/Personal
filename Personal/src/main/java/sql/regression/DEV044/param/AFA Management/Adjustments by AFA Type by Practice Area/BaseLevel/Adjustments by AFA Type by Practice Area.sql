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
SELECT top 1
ils.PracticeAreaId,
  P2.PracticeAreaName as ''PracticeArea'', 
  ils.AfaRuleTypes as ''AFA Types'', 
  sum(ils.AfaFeeAmount *-1) as ''AFA Adjustments'', 
  COUNT(distinct ils.matterid) as ''# Matter'' 
FROM 
  V_InvoiceLineItemSpendFactWithCurrency ils 
  JOIN PracticeAreaDIM P ON ILs.PracticeAreaId = P.PracticeAreaId 
  inner join practiceareadim p2 on  p2.level = ''2'' 
  and P.[path] like p2.[Path] + ''%''   
  JOIN (
    SELECT 
      TOP 10000 P2.PracticeAreaName as ''PracticeArea'', 
      sum(ils.AfaFeeAmount *-1) as [AFA Adjustments Order] 
    FROM 
      V_InvoiceLineItemSpendFactWithCurrency ils 
      JOIN PracticeAreaDIM P ON ILs.PracticeAreaId = P.PracticeAreaId 
      inner join practiceareadim p2 on  p2.level = ''2'' 
      and P.[path] like p2.[Path] + ''%''   
    WHERE 
                  ils.InvoiceStatus IN ('''+@InvoiceStatus+''')             
      AND ils.InvoiceStatusDate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
	  AND ils.CurrencyCode = '''+@CurrencyCode+'''              
      AND ils.AfaRuleTypes IS NOT NULL              
                  
    group by 
      P2.PracticeAreaName             
    order by 
      [AFA Adjustments Order] desc
  ) od ON P2.PracticeAreaName = od.PracticeArea 
WHERE 
              ils.InvoiceStatus IN ('''+@InvoiceStatus+''')             
  AND ils.InvoiceStatusDate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
  AND ils.CurrencyCode = '''+@CurrencyCode+'''            
  AND ils.AfaRuleTypes IS NOT NULL            
              
group by 
ils.PracticeAreaId,
  P2.PracticeAreaName, 
  ils.AfaRuleTypes, 
  [AFA Adjustments Order] 
order by 
  PracticeArea, 
  [Afa Types]
'

Print @SQL
EXEC(@SQL)