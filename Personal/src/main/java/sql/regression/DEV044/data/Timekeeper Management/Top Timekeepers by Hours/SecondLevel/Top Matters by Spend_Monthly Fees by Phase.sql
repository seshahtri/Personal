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
--SET @pDateStart='01/01/2017'; 
--SET @pDateEnd ='12/31/2017';
--SET @InvoiceStatus ='Paid'',''Processed';

SET @SQL = '
			EXECUTE AS USER = ''admin''

			;WITH T AS
					(
					SELECT DISTINCT 
						PhaseCode,
						YEAR(ifbc.invoiceDate) Year,
						mon.MonthID,
						mon.month Month,
						ed.CurrencyCode as [Currency Code]
					FROM 
						V_InvoiceFeeBillCodeSummary ifbc
						JOIN ExchangeRateDim ed on ed.ExchangeRateDate = ifbc.ExchangeRateDate
						CROSS JOIN  
							(
							SELECT DISTINCT
								MONTH(ifbc.Invoicedate) MonthId,
								DATENAME(month, ifbc.Invoicedate) Month 
							FROM 
								V_InvoiceFeeBillCodeSummary ifbc
								join ExchangeRateDim ed on ed.ExchangeRateDate = ifbc.ExchangeRateDate
							WHERE 
							--ifbc.TimekeeperId=912067 And ifbc.MatterId=1683928 
							ifbc.TimekeeperId=^ParamOne^ And ifbc.MatterId=^ParamTwo^ 
								AND ifbc.invoiceDate BETWEEN  '''+@pDateStart+''' AND '''+@pDateEnd+'''
								AND ifbc.InvoiceStatus IN ('''+@InvoiceStatus+''')
								AND ed.CurrencyCode = '''+@CurrencyCode+'''
								AND ifbc.Category =''Fee''
								AND hours > 0.01
								AND PhaseCode is NOT NULL
								AND TimekeeperRoleId IS NOT NULL
							) mon
					WHERE 
						ifbc.invoiceDate BETWEEN  '''+@pDateStart+''' AND '''+@pDateEnd+'''
						AND ifbc.InvoiceStatus IN ('''+@InvoiceStatus+''') and
						---ifbc.TimekeeperId=912067 And ifbc.MatterId=1683928 
						ifbc.TimekeeperId=^ParamOne^ And ifbc.MatterId=^ParamTwo^ 
						AND ed.CurrencyCode = '''+@CurrencyCode+'''
						AND ifbc.Category =''Fee''
						AND hours > 0.01
						AND PhaseCode is NOT NULL
						AND TimekeeperRoleId IS NOT NULL
					)
			SELECT 
				T.PhaseCode as [Phase Code],
				T.Year,
				T.Month,
				T.[Currency Code],
				fees.Fees
			FROM T
				LEFT JOIN (
					SELECT PhaseCode, DATEPART(YEAR, ifbc.Invoicedate)  AS Year , DATENAME(MONTH, ifbc.Invoicedate) AS Month, ed.CurrencyCode as [Currency Code],
						SUM(ifbc.GrossFeeAmountForRates*ISNULL(ed.ExchangeRate,1)) as ''Fees''
					FROM V_InvoiceFeeBillCodeSummary ifbc
						JOIN ExchangeRateDim ed on ed.ExchangeRateDate = ifbc.ExchangeRateDate
						INNER JOIN BusinessUnitAndAllDescendants B on b.childbusinessunitid=ifbc.BusinessUnitId
						INNER JOIN
							(SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
						FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''-1'', ''|'',-1,0)) ba on ba.RollupBusinessUnitId=b.BusinessUnitId
						INNER JOIN PracticeAreaAndAllDescendants P on P.ChildPracticeAreaId=ifbc.PracticeAreaId
						INNER JOIN 
							(
							SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
							FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',-1,1)
							) pa on pa.RollupPracticeAreaId=p.PracticeAreaId
					WHERE ifbc.InvoiceStatus IN ('''+@InvoiceStatus+''') and
						--ifbc.TimekeeperId=912067 And ifbc.MatterId=1683928 
						ifbc.TimekeeperId=^ParamOne^ And ifbc.MatterId=^ParamTwo^ 
						AND ifbc.invoiceDate BETWEEN  '''+@pDateStart+''' AND '''+@pDateEnd+'''
						AND ed.CurrencyCode = '''+@CurrencyCode+'''
						AND ifbc.Category =''Fee''
						AND hours > 0.01
						AND PhaseCode is NOT NULL
						AND TimekeeperRoleId IS NOT NULL
					GROUP BY  PhaseCode, DATEPART(YEAR, ifbc.Invoicedate), DATENAME(MONTH, ifbc.Invoicedate), ed.CurrencyCode
						) fees on fees.Month=T.Month and fees.Year=T.Year and fees.PhaseCode=T.PhaseCode
				ORDER BY [Phase Code], T.Year, T.MonthId desc
'
Print(@SQL)
EXEC(@SQL)
