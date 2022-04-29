--use Q5_C00348_IOD_DATAMART
DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @CurrencyCode  varchar (50);
DECLARE @InvoiceStatus varchar (MAX);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @CurrencyCode= ^Currency^;
--SET @InvoiceStatus= ^InvoiceStatus^;

--SET @pDateStart='1/1/2021'; 
--SET @pDateEnd='12/31/2021';
--SET @CurrencyCode ='USD';
SET @InvoiceStatus ='Paid'',''Processed';

SET @SQL='

EXEC AS USER = ''admin'' 
SELECT 
     MatterName as [Matter Name],
    ClaimNumber as [Claim Number],
    b.MatterOwnerName as [Matter Owner],
    GBBranchName as [GB Branch Name],
    GBBranchNumber as [GB Branch Number],
    [Currency Code] as [Currency Code],
    Spend, 
    TotalBudget, 
    [Percent of Budget consumed], 
    [Percent of Budget Remaining],
    [Budget Remaining]
from (SELECT 
     MatterName,
    Budget.ClaimNumber,
    Budget.MatterOwnerId,
    Budget.GBBranchName,
    Budget.GBBranchNumber,
    Budget.[Currency Code],
    Spend, 
    SUM(BudgetAmount) TotalBudget, 
    Spend/NULLIF(SUM(BudgetAmount),0) *100 [Percent of Budget consumed], 
    CASE 
        WHEN 
            (Spend/NULLIF(SUM(BudgetAmount),0) ) <1
        THEN 
           ( 1 - (Spend/NULLIF(SUM(BudgetAmount),0) ))*100
        ELSE 
            0 
        END AS  [Percent of Budget Remaining],
    SUM(BudgetAmount) - Spend [Budget Remaining]
FROM 
    (    SELECT 
            VBI.BudgetPeriodId, VBI.BudgetPeriodName, MatterId, VendorId,  MIN(BudgetAmount) BudgetAmount,
            VBI.MatterDF07 as [ClaimNumber],VBI.MatterDF08 as [GBBranchName],VBI.MatterDF09 as [GBBranchNumber],VBI.CurrencyCode as[Currency Code],MatterOwnerId --Anand
        FROM 
            V_VendorBudgetInfo VBI
            JOIN PracticeAreaAndAllDescendants PAD ON VBI.PracticeAreaId = PAD.ChildPracticeAreaId
        WHERE
		  VBI.VendorId = ^ParamTwo^
		  --VBI.vendorid=72861
          AND  VBI.CurrencyCode =''' + @CurrencyCode + '''
            AND ((VBI.BudgetPeriodStartDate >= ''' + @pDateStart + ''' AND VBI.BudgetPeriodEndDate <= ''' + @pDateEnd + ''') 
            OR (VBI.BudgetPeriodStartDate <= ''' + @pDateStart + ''' AND VBI.BudgetPeriodEndDate >= ''' + @pDateEnd + ''')
            OR (VBI.BudgetPeriodStartDate <= ''' + @pDateStart + ''' AND VBI.BudgetPeriodEndDate >= ''' + @pDateStart + ''') 
            OR (VBI.BudgetPeriodStartDate >= ''' + @pDateStart + ''' AND VBI.BudgetPeriodStartDate <= ''' + @pDateEnd + ''' AND VBI.BudgetPeriodEndDate >= cast('''+@pDateEnd+'''as date)))
            AND ( CASE    WHEN IsLOM = 1 THEN( CASE WHEN (((VBI.MatterOpenDate <= cast('''+@pDateEnd+'''as date)) AND ISNULL(VBI.MatterCloseDate, {d ''9999-12-31'' })> cast('''+@pDateEnd+'''as date)) 
                OR ((VBI.MatterOpenDate <= cast('''+@pDateEnd+'''as date)) AND DATEDIFF(month, ISNULL(VBI.MatterCloseDate, {d ''9999-12-31'' }), cast('''+@pDateEnd+'''as date)) <= 12)) 
            THEN 1 ELSE 0 END) ELSE 0 END )= 1
        GROUP BY 
            VBI.BudgetPeriodId, VBI.BudgetPeriodName, MatterId, VendorId,
            VBI.MatterDF07,VBI.MatterDF08,VBI.MatterDF09,Currencycode,MatterOwnerId ) Budget
JOIN	
    (SELECT 
        VBI.MatterId, VBI.MatterName, SUM(Amount) Spend,
        VBI.MatterDF07 as [ClaimNumber],VBI.MatterDF08 as [GBBranchName],VBI.MatterDF09 as [GBBranchNumber],VBI.CurrencyCode as[Currency Code],VBI.MatterOwnerId --Anand
    FROM 
        V_VendorBudgetInfo VBI	
        JOIN PracticeAreaAndAllDescendants PAD ON VBI.PracticeAreaId = PAD.ChildPracticeAreaId
        JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
                FROM fn_GetRollupPracticeAreasWithSecurity (^ParamOne^, ''|'',-1,0)) PASEC ON PAD.PracticeAreaId = PASEC.RollupPracticeAreaId
				--FROM fn_GetRollupPracticeAreasWithSecurity (''42406'', ''|'',-1,0)) PASEC ON PAD.PracticeAreaId = PASEC.RollupPracticeAreaId
        LEFT JOIN ( SELECT  ILI.* 
                    FROM 
                        V_InvoiceLineItemSpendFactWithCurrency ILI
                    WHERE
                        CurrencyCode =''' + @CurrencyCode + '''
                        AND InvoiceStatus IN  (''' + @InvoiceStatus + ''') ) AS Spend ON VBI.BudgetPeriodId = Spend.BudgetPeriodId AND VBI.MatterId = Spend.MatterId AND Spend.VendorId = VBI.VendorId
    WHERE
        VBI.CurrencyCode = ''' + @CurrencyCode + '''
		AND VBI.vendorid= ^ParamTwo^
	      --AND VBI.vendorid=72861
          AND ((VBI.BudgetPeriodStartDate >= ''' + @pDateStart + ''' AND VBI.BudgetPeriodEndDate <= ''' + @pDateEnd + ''') 
            OR (VBI.BudgetPeriodStartDate <= ''' + @pDateStart + ''' AND VBI.BudgetPeriodEndDate >= ''' + @pDateEnd + ''')
            OR (VBI.BudgetPeriodStartDate <= ''' + @pDateStart + ''' AND VBI.BudgetPeriodEndDate >= ''' + @pDateStart + ''') 
            OR (VBI.BudgetPeriodStartDate >= ''' + @pDateStart + ''' AND VBI.BudgetPeriodStartDate <= ''' + @pDateEnd + ''' AND VBI.BudgetPeriodEndDate >= ''' + @pDateEnd + '''))
        AND ( CASE    WHEN IsLOM = 1 THEN( CASE WHEN (((VBI.MatterOpenDate <= cast('''+@pDateEnd+'''as date)) AND ISNULL(VBI.MatterCloseDate, {d ''9999-12-31'' })> ''' + @pDateEnd + ''') 
                OR ((VBI.MatterOpenDate <= cast('''+@pDateEnd+'''as date)) AND DATEDIFF(month, ISNULL(VBI.MatterCloseDate, {d ''9999-12-31'' }), cast('''+@pDateEnd+'''as date)) <= 12)) 
            THEN 1 ELSE 0 END) ELSE 0 END )= 1
    GROUP BY 
        VBI.MatterId, VBI.MatterName,
        VBI.MatterDF07,VBI.MatterDF08,VBI.MatterDF09,VBI.CurrencyCode,VBI.MatterOwnerId  ) Spend ON Budget.MatterId = Spend.MatterId
GROUP BY 
     MatterName,Budget.ClaimNumber,Budget.GBBranchName,Budget.GBBranchNumber,Budget.[Currency Code],Spend,Budget.MatterOwnerId) a,
     v_Matterowners b
where    a.MatterOwnerId = b.MatterOwnerId
ORDER BY Spend DESC'

print(@SQL)
exec(@SQL)