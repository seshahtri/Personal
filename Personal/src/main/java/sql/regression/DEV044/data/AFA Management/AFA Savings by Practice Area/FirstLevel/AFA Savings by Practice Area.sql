USE DEV044_IOD_DataMart;
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
--SET @pDateStart='01/01/2017';
--SET @pDateEnd ='12/31/2017';
--SET @InvoiceStatus ='Paid'',''Processed';

SET @SQL = '
				exec as user = ''admin''
	--AFA Savings by Practice Area-- 
	SELECT 
	  DISTINCT af.RollupPracticeAreaName as PracticeArea, 
	  af.[Billed Fees], 
	  af.[AFA Savings] *-1 as [AFA Savings], 
	  (af.[Reviewer Adjustments])*-1 as [Reviewer Adjustments], 
	  CAST(
		(
		  af.allfeeadjustment - af.[AFA Savings] - af.[Reviewer Adjustments]
		)*-1 AS FLOAT
	  ) AS [Other Adjustments], 
	  af.[Paid Fees], 
	  CAST(
		af.[AFA Savings] / NULLIF(af.[Billed Fees], 0)*-1 AS FLOAT
	  )*100 AS [ % AFA Saved], 
	  CAST(
		(af.[Billed Fees] - af.[Paid Fees])/ NULLIF(af.[Billed Fees], 0) AS FLOAT
	  ) AS [ % Overall Saved], 
	  af.[ # Matters] 
	FROM 
	  v_invoicelineitemspendfactwithcurrency ils 
	  Right JOIN [dbo].[PracticeAreaAndAllDescendants] [PracticeAreaAndAllDescendants] ON ils.[PracticeAreaId] = [PracticeAreaAndAllDescendants].[ChildPracticeAreaId]
                       INNER JOIN (
                            SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
	--FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',32477,1)
	FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',^ParamOne^,1)
                           ) [RollupPracticeArea] ON ([PracticeAreaAndAllDescendants].[PracticeAreaId] = [RollupPracticeArea].[RollupPracticeAreaId])
	 -- RIGHT join practiceareadim p2 on  p2.level = ''2'' and [PracticeAreaAndAllDescendants].[path] like p2.[Path] + ''%''
	  RIGHT JOIN (
		SELECT 
		  RollupPracticeAreaName,[PracticeAreaAndAllDescendants].practiceareaid,
		  sum(
			CASE WHEN category = ''ADJUSTMENT'' THEN CAST(netfeeamount AS FLOAT) else 0 END
		  ) AS allfeeadjustment, 
		  CAST(
			(
			  sum(ils.grossfeeamount)
			) AS FLOAT
		  ) AS [Billed Fees], 
		  CAST(
			(
			  sum(ils.afafeeamount)
			) AS FLOAT
		  ) AS [AFA Savings], 
		  CAST(
			(
			  sum(ils.reviewerfeeamount)
			) AS FLOAT
		  ) AS [Reviewer Adjustments], 
		  CAST(
			(
			  sum(ils.netfeeamount)
			) AS FLOAT
		  ) AS [Paid Fees], 
		  count (DISTINCT matterid) AS [ # Matters] 
		FROM 
		  v_invoicelineitemspendfactwithcurrency ils 
		  Right JOIN [dbo].[PracticeAreaAndAllDescendants] [PracticeAreaAndAllDescendants] ON ils.[PracticeAreaId] = [PracticeAreaAndAllDescendants].[ChildPracticeAreaId]
                       INNER JOIN (
                            SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
	--FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',32477,1)
	FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (-1, ''|'',^ParamOne^,1)
                           ) [RollupPracticeArea] ON ([PracticeAreaAndAllDescendants].[PracticeAreaId] = [RollupPracticeArea].[RollupPracticeAreaId])
		 -- inner join practiceareadim p2 on  p2.level = ''2'' and [PracticeAreaAndAllDescendants].[path] like p2.[Path] + ''%''
		WHERE 
	  ils.invoicestatus IN ('''+@InvoiceStatus+''')
	  AND ils.invoicestatusdate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
	  AND ils.currencyid = 1
	  AND ils.afaruletypes IS NOT NULL 
	  AND ils.grossfeeamount IS NOT NULL
		  
		GROUP BY 
		 RollupPracticeAreaName,[PracticeAreaAndAllDescendants].practiceareaid
	  ) AS af ON 1=1 --af.practiceareaid = ils.practiceareaid 
	WHERE 
	  ils.invoicestatus IN ('''+@InvoiceStatus+''')
	  AND ils.invoicestatusdate BETWEEN '''+@pDateStart+''' AND '''+@pDateEnd+'''
	  AND ils.currencyid = 1
	  AND ils.afaruletypes IS NOT NULL 
	  AND ils.grossfeeamount IS NOT NULL
	  

	ORDER BY 
	  [AFA Savings] DESC


				'
PRINT(@SQL)
EXEC(@SQL)

