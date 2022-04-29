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
execute  as user= ''admin''

SELECT RollupPracticeAreasWithSecurity.RollupPracticeAreaName AS PracticeAreaName,
  MIN(ExchangeRateDim.CurrencyCode) AS [Currency Code],
  COUNT(DISTINCT MSS.MatterId) AS Matters,
  SUM((CASE WHEN ( MSS.InvoiceStatus in( '''+@InvoiceStatus+''') ) AND (MSS.InvoiceDate <= '''+@pDateEnd+''') THEN (MSS.Amount * ISNULL(ExchangeRateDim.ExchangeRate, 1)) ELSE CAST(NULL AS FLOAT) END)) AS Spend,
  SUM((CASE WHEN ( MSS.InvoiceStatus in( '''+@InvoiceStatus+''') AND (MSS.InvoiceDate <= '''+@pDateEnd+''')) THEN MSS.Hours ELSE CAST(NULL AS FLOAT) END)) AS [Hours]
  
FROM [dbo].V_MatterSpendSummary MSS

  INNER JOIN [dbo].[BusinessUnitAndAllDescendants] [BusinessUnitAndAllDescendants] ON (MSS.[BusinessUnitId] = [BusinessUnitAndAllDescendants].[ChildBusinessUnitId])
  INNER JOIN (
  SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
  FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (-1, ''|'',-1,0)
) [RollupBusinessUnitsWithSecurity] ON ([BusinessUnitAndAllDescendants].[BusinessUnitId] = [RollupBusinessUnitsWithSecurity].[RollupBusinessUnitId])

  LEFT JOIN [dbo].[ExchangeRateDim] [ExchangeRateDim] ON (MSS.[ExchangeRateDate] = [ExchangeRateDim].[ExchangeRateDate])

  INNER JOIN [dbo].[PracticeAreaAndAllDescendants] [PracticeAreaAndAllDescendants] ON (MSS.[PracticeAreaId] = [PracticeAreaAndAllDescendants].[ChildPracticeAreaId])
  INNER JOIN (
  SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
  --FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',32470,1)
  FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',^ParamOne^,1)
) [RollupPracticeAreasWithSecurity] ON ([PracticeAreaAndAllDescendants].[PracticeAreaId] = [RollupPracticeAreasWithSecurity].[RollupPracticeAreaId])
WHERE 
((((CASE WHEN ([ExchangeRateDim].[CurrencyCode] = '''+@CurrencyCode+''') THEN 1 WHEN NOT ([ExchangeRateDim].[CurrencyCode] = '''+@CurrencyCode+''') THEN 0 ELSE NULL END) IS NULL) OR ([ExchangeRateDim].[CurrencyCode] = '''+@CurrencyCode+''')) 
AND ((CASE WHEN ((CASE WHEN ((MSS.[MatterOpenDate] <= '''+@pDateEnd+''') AND (ISNULL(MSS.[MatterCloseDate], (CASE  WHEN 0 = ISDATE(CAST(''9999-12-31'' AS VARCHAR)) THEN NULL
ELSE DATEADD(day, DATEDIFF(day, 0, CAST(CAST(''9999-12-31'' AS VARCHAR) as datetime)), 0) END)) > '''+@pDateEnd+''')) 
THEN ''Open'' WHEN (MSS.[MatterOpenDate] <= '''+@pDateEnd+''') 
THEN ''Closed'' ELSE CAST(NULL AS NVARCHAR) END) = ''Open'') THEN 1 ELSE 0 END) = 1))
GROUP BY [RollupPracticeAreasWithSecurity].[RollupPracticeAreaName]
order by COUNT_BIG(DISTINCT MSS.MatterId) desc
'
print(@SQL)
exec(@SQL)