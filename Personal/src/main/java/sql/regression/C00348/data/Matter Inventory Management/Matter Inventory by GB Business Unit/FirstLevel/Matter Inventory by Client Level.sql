DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @CurrencyCode varchar (MAX);
DECLARE @InvoiceStatus varchar (MAX);
DECLARE @DateField varchar (MAX);
DECLARE @SQL nVARCHAR(max);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;

--SET @pDateStart='04/1/2021';
--SET @pDateEnd='03/31/2022';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode='USD';  


SET @SQL='
execute  as user= ''admin''

SELECT RollupPracticeAreasWithSecurity.RollupPracticeAreaName AS PracticeAreaName,  
  min(ExchangeRateDim.CurrencyCode) AS [Currency Code],
  COUNT(DISTINCT MSS.MatterId) AS Matters,
  SUM((CASE WHEN ( MSS.InvoiceStatus in( '''+@InvoiceStatus+''') ) AND (MSS.PaymentDate <= '''+@pDateEnd+''') THEN (MSS.Amount * ISNULL(ExchangeRateDim.ExchangeRate, 1)) ELSE CAST(NULL AS FLOAT) END)) AS Spend,
  SUM((CASE WHEN ( MSS.InvoiceStatus in( '''+@InvoiceStatus+''') AND (MSS.PaymentDate <= '''+@pDateEnd+''')) THEN MSS.Hours ELSE CAST(NULL AS FLOAT) END)) AS [Hours]
  
FROM [dbo].V_MatterSpendSummary MSS

  INNER JOIN [dbo].[BusinessUnitAndAllDescendants] [BusinessUnitAndAllDescendants] ON (MSS.[BusinessUnitId] = [BusinessUnitAndAllDescendants].[ChildBusinessUnitId])
  INNER JOIN (
  SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
  --FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (16573, ''|'',-1,0)
  FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (^ParamOne^, ''|'',-1,0)
) [RollupBusinessUnitsWithSecurity] ON ([BusinessUnitAndAllDescendants].[BusinessUnitId] = [RollupBusinessUnitsWithSecurity].[RollupBusinessUnitId])

  LEFT JOIN [dbo].[ExchangeRateDim] [ExchangeRateDim] ON (MSS.[ExchangeRateDate] = [ExchangeRateDim].[ExchangeRateDate])

  INNER JOIN [dbo].[PracticeAreaAndAllDescendants] [PracticeAreaAndAllDescendants] ON (MSS.[PracticeAreaId] = [PracticeAreaAndAllDescendants].[ChildPracticeAreaId])
  INNER JOIN (
  SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
  FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',-1,1)
  
) [RollupPracticeAreasWithSecurity] ON ([PracticeAreaAndAllDescendants].[PracticeAreaId] = [RollupPracticeAreasWithSecurity].[RollupPracticeAreaId])
WHERE 
((((CASE WHEN ([ExchangeRateDim].[CurrencyCode] = '''+@CurrencyCode+''') THEN 1 WHEN NOT ([ExchangeRateDim].[CurrencyCode] = '''+@CurrencyCode+''') THEN 0 ELSE NULL END) IS NULL) OR ([ExchangeRateDim].[CurrencyCode] = '''+@CurrencyCode+''')) 
AND ((CASE WHEN ((CASE WHEN ((MSS.[MatterOpenDate] <= '''+@pDateEnd+''') AND (ISNULL(MSS.[MatterCloseDate], (CASE  WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)) > '''+@pDateEnd+''')) 
THEN ''Open'' WHEN (MSS.[MatterOpenDate] <= '''+@pDateEnd+''') 
THEN ''Closed'' ELSE CAST(NULL AS NVARCHAR) END) = ''Open'') THEN 1 ELSE 0 END) = 1))
GROUP BY [RollupPracticeAreasWithSecurity].[RollupPracticeAreaName]--, ExchangeRateDim.CurrencyCode
order by COUNT_BIG(DISTINCT MSS.MatterId) desc, PracticeAreaName desc
'
print(@SQL)
exec(@SQL)