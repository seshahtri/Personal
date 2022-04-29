---use Q5_C00348_IOD_DataMart

DECLARE @pDateStart varchar (MAX);
DECLARE @pDateEnd varchar (MAX);
DECLARE @InvoiceStatus nvarchar (MAX);
DECLARE @CurrencyCode  varchar (50);
DECLARE @SQL VARCHAR(MAX);

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;

--SET @pDateStart='1/1/2021';
--SET @pDateEnd='12/31/2021';
--SET @InvoiceStatus = 'Paid'',''Processed';
--SET @CurrencyCode ='USD';

SET @SQL='
EXEC AS USER = ''admin''

 
SELECT distinct MatterName as [Matter Name],
     Vendorname as [Vendor Name],
    [Currency Code] as [Currency Code],
	City,
	StateProvCode as [State],
    Spend, 
    TotalBudget, 
    [Percent of Budget consumed]
from (SELECT 
     MatterName,
	 Vendorname,
     Budget.[Currency Code],
	 City,
	 StateProvCode,
    Spend, 
    SUM(BudgetAmount) TotalBudget, 
    Spend/NULLIF(SUM(BudgetAmount),0) *100 [Percent of Budget consumed]
FROM 
    (    SELECT 
            VBI.BudgetPeriodId, VBI.BudgetPeriodName, MatterId, VendorId,  MIN(BudgetAmount) BudgetAmount,VBI.vendorname,
            VBI.MatterDF07 as [ClaimNumber],VBI.MatterDF08 as [GBBranchName],VBI.MatterDF09 as [GBBranchNumber],VBI.CurrencyCode as[Currency Code],MatterOwnerId --Anand
        FROM 
            V_VendorBudgetInfo VBI
            JOIN PracticeAreaAndAllDescendants PAD ON VBI.PracticeAreaId = PAD.ChildPracticeAreaId
        WHERE
		   VBI.MatterId = ^ParamOne^
          AND  VBI.CurrencyCode = ''' + @CurrencyCode + '''
            AND ((VBI.BudgetPeriodStartDate >= cast('''+@pDateStart+'''as date) AND VBI.BudgetPeriodEndDate <= cast('''+@pDateEnd+'''as date)) 
            OR (VBI.BudgetPeriodStartDate <= cast('''+@pDateStart+'''as date) AND VBI.BudgetPeriodEndDate >= cast('''+@pDateEnd+'''as date))
            OR (VBI.BudgetPeriodStartDate <= cast('''+@pDateStart+'''as date) AND VBI.BudgetPeriodEndDate >= cast('''+@pDateStart+'''as date)) 
            OR (VBI.BudgetPeriodStartDate >= cast('''+@pDateStart+'''as date) AND VBI.BudgetPeriodStartDate <= cast('''+@pDateEnd+'''as date) AND VBI.BudgetPeriodEndDate >= cast('''+@pDateEnd+'''as date)))
            AND ( CASE    WHEN IsLOM = 1 THEN( CASE WHEN (((VBI.MatterOpenDate <= cast('''+@pDateEnd+'''as date)) AND ISNULL(VBI.MatterCloseDate, {d ''9999-12-31'' })> cast('''+@pDateEnd+'''as date)) 
                OR ((VBI.MatterOpenDate <= cast('''+@pDateEnd+'''as date)) AND DATEDIFF(month, ISNULL(VBI.MatterCloseDate, {d ''9999-12-31'' }), cast('''+@pDateEnd+'''as date)) <= 12)) 
            THEN 1 ELSE 0 END) ELSE 0 END )= 1
        GROUP BY 
            VBI.BudgetPeriodId, VBI.BudgetPeriodName, MatterId, VendorId,
            VBI.MatterDF07,VBI.MatterDF08,VBI.MatterDF09,Currencycode,MatterOwnerId,VendorName ) Budget
JOIN 
    (SELECT 
        VBI.MatterId, VBI.MatterName, SUM(Amount) Spend,City,StateProvCode,
        VBI.MatterDF07 as [ClaimNumber],VBI.MatterDF08 as [GBBranchName],VBI.MatterDF09 as [GBBranchNumber],VBI.CurrencyCode as[Currency Code],VBI.MatterOwnerId
    FROM 
        V_VendorBudgetInfo VBI 
        JOIN PracticeAreaAndAllDescendants PAD ON VBI.PracticeAreaId = PAD.ChildPracticeAreaId
        JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
                FROM fn_GetRollupPracticeAreasWithSecurity (''-1'', ''|'',-1,0)) PASEC ON PAD.PracticeAreaId = PASEC.RollupPracticeAreaId
        LEFT JOIN ( SELECT  ILI.* ,INS.City,INS.StateProvCode
                    FROM 
                        V_InvoiceLineItemSpendFactWithCurrency ILI
						Left join V_InvoiceSummary INS on ILI.invoiceid = INS.InvoiceId
                    WHERE
                        CurrencyCode = ''' + @CurrencyCode + '''
                        AND ili.InvoiceStatus IN  (''' + @InvoiceStatus + ''') ) AS Spend ON VBI.BudgetPeriodId = Spend.BudgetPeriodId AND VBI.MatterId = Spend.MatterId AND Spend.VendorId = VBI.VendorId
    WHERE
        VBI.CurrencyId = 1
	 AND VBI.MatterId = ^ParamOne^
        AND ((VBI.BudgetPeriodStartDate >= cast('''+@pDateStart+'''as date) AND VBI.BudgetPeriodEndDate <= cast('''+@pDateEnd+'''as date)) 
            OR (VBI.BudgetPeriodStartDate <= cast('''+@pDateStart+'''as date) AND VBI.BudgetPeriodEndDate >= cast('''+@pDateEnd+'''as date))
            OR (VBI.BudgetPeriodStartDate <= cast('''+@pDateStart+'''as date) AND VBI.BudgetPeriodEndDate >= cast('''+@pDateStart+'''as date)) 
            OR (VBI.BudgetPeriodStartDate >= cast('''+@pDateStart+'''as date) AND VBI.BudgetPeriodStartDate <= cast('''+@pDateEnd+'''as date) AND VBI.BudgetPeriodEndDate >= cast('''+@pDateEnd+'''as date)))
        AND ( CASE    WHEN IsLOM = 1 THEN( CASE WHEN (((VBI.MatterOpenDate <= cast('''+@pDateEnd+'''as date)) AND ISNULL(VBI.MatterCloseDate, {d ''9999-12-31'' })> cast('''+@pDateEnd+'''as date)) 
                OR ((VBI.MatterOpenDate <= cast('''+@pDateEnd+'''as date)) AND DATEDIFF(month, ISNULL(VBI.MatterCloseDate, {d ''9999-12-31'' }), cast('''+@pDateEnd+'''as date)) <= 12)) 
            THEN 1 ELSE 0 END) ELSE 0 END )= 1
    GROUP BY 
        VBI.MatterId, VBI.MatterName,
        VBI.MatterDF07,VBI.MatterDF08,VBI.MatterDF09,VBI.CurrencyCode,VBI.MatterOwnerId,City,StateProvCode) Spend ON Budget.MatterId = Spend.MatterId
GROUP BY 
     MatterName,Budget.ClaimNumber,Budget.GBBranchName,Budget.GBBranchNumber,Budget.[Currency Code],Spend,Budget.vendorname,City,StateProvCode) a,
     v_Matterowners b
ORDER BY Spend DESC'
Print @SQL
EXEC(@SQL)