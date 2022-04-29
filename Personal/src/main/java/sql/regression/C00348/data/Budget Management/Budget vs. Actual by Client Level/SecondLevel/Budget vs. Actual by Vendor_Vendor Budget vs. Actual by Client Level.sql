DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @CurrencyCode  varchar (50);
DECLARE @CurrencyId  varchar;
DECLARE @InvoiceStatus varchar (MAX); 

SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
SET @CurrencyCode= ^Currency^;
--SET @InvoiceStatus= ^InvoiceStatus^;
set @CurrencyId= (select CurrencyId from v_currency where currencycode=@CurrencyCode)

--SET @pDateStart='1/1/2021'; 
--SET @pDateEnd='08/31/2021';
--SET @CurrencyCode ='USD';
SET @InvoiceStatus ='Paid'''',''''Processed';
set @CurrencyId= (select CurrencyId from v_currency where currencycode=@CurrencyCode)
SET @SQL='
 

EXEC AS USER = ''admin''
SELECT
Budget.rolluppracticeareaname AS [Client Level],
Budget.CurrencyCode as  [Currency Code],
spend,
Sum(budgetamount)AS [Total Budget],
spend / NULLIF(Sum(budgetamount), 0) * 100 [Percent of Budget consumed],
CASE
  WHEN ( spend / NULLIF(Sum(budgetamount), 0) ) < 1 THEN ( 1 - ( spend / NULLIF(Sum(budgetamount), 0) ) ) * 100
  ELSE 0
END                                        AS [Percent of Budget Remaining],
Sum(budgetamount) - spend                  [Budget Remaining]
FROM   (SELECT rolluppracticeareaid,
               rolluppracticeareaname,
               vendorid,
               matterid,
               Min(budgetamount) BudgetAmount,
               vbi.CurrencyCode
        FROM   v_vendorbudgetinfo VBI(nolock)
               JOIN practiceareaandalldescendants PAD(nolock)
                 ON VBI.practiceareaid = PAD.childpracticeareaid
               JOIN (SELECT rolluppracticeareaid,
                            rolluppracticeareaname,
                            rolluppracticeareapath,
                            rolluppracticeareadisplaypath,
                            rolluppracticearealevel
                     FROM   Fn_getrolluppracticeareaswithsecurity (''-1'', ''|'', ^ParamOne^, 1)) PASEC
					 --FROM   Fn_getrolluppracticeareaswithsecurity (''-1'', ''|'', 42406, 1)) PASEC
                 ON PAD.practiceareaid = PASEC.rolluppracticeareaid
        WHERE  VBI.currencyid ='+@CurrencyId+'
		       AND vbi.vendorid = ^ParamTwo^
			   --AND vbi.vendorid = 72861
               AND vbi.vendorname IN ( Select distinct vendorname from v_vendorbudgetinfo where vendorid = ^ParamTwo^ )
			   --AND vbi.vendorname IN ( Select distinct vendorname from v_vendorbudgetinfo where vendorid = 72861 )
               AND ( ( VBI.budgetperiodstartdate >= cast('''+@pDateStart+'''as date)
                       AND VBI.budgetperiodenddate <= cast('''+@pDateEnd+'''as date) )
                      OR ( VBI.budgetperiodstartdate <= cast('''+@pDateStart+'''as date)
                           AND VBI.budgetperiodenddate >= cast('''+@pDateEnd+'''as date) )
                      OR ( VBI.budgetperiodstartdate <= cast('''+@pDateStart+'''as date)
                           AND VBI.budgetperiodenddate >= cast('''+@pDateEnd+'''as date) )
                      OR ( VBI.budgetperiodstartdate >= cast('''+@pDateStart+'''as date)
                           AND VBI.budgetperiodstartdate <= cast('''+@pDateEnd+'''as date)
                           AND VBI.budgetperiodenddate >= cast('''+@pDateEnd+'''as date) ) )
               AND ( CASE
                       WHEN islom = 1 THEN( CASE
                                              WHEN ( ( ( VBI.matteropendate <= cast('''+@pDateEnd+'''as date) )
                                                       AND Isnull(VBI.matterclosedate, {d ''9999-12-31'' }) > cast('''+@pDateEnd+'''as date) )
                                                      OR ( ( VBI.matteropendate <= cast('''+@pDateEnd+'''as date) )
                                                           AND Datediff(month, Isnull(VBI.matterclosedate, {d ''9999-12-31'' }), cast('''+@pDateEnd+'''as date)) <= 12 ) ) THEN 1
                                              ELSE 0
                                            END )
                       ELSE 0
                     END ) = 1
        GROUP  BY PASEC.rolluppracticeareaid,
                  PASEC.rolluppracticeareaname,
                  vendorid,
                  matterid,
                   vbi.CurrencyCode) Budget
       JOIN (SELECT rolluppracticeareaid,
                    rolluppracticeareaname,
                    Sum(amount) Spend
             FROM   v_vendorbudgetinfo VBI (nolock)
                    JOIN practiceareaandalldescendants PAD(nolock)
                      ON VBI.practiceareaid = PAD.childpracticeareaid
                    JOIN (SELECT rolluppracticeareaid,
                                 rolluppracticeareaname,
                                 rolluppracticeareapath,
                                 rolluppracticeareadisplaypath,
                                 rolluppracticearealevel
                          FROM   Fn_getrolluppracticeareaswithsecurity (''-1'', ''|'', ^ParamOne^, 1)) PASEC
						  --FROM   Fn_getrolluppracticeareaswithsecurity (''-1'', ''|'', 42406, 1)) PASEC
                      ON PAD.practiceareaid = PASEC.rolluppracticeareaid
                    LEFT JOIN (SELECT ILI.*
                               FROM   v_invoicelineitemspendfactwithcurrency ILI (nolock)
                               WHERE  currencyid ='+@CurrencyId+'
                                      AND invoicestatus IN ( ''Paid'', ''Processed'' )) AS Spend
                           ON VBI.budgetperiodid = Spend.budgetperiodid
                              AND VBI.matterid = Spend.matterid
                              AND Spend.vendorid = VBI.vendorid
             WHERE  VBI.currencyid ='+@CurrencyId+'
			        AND vbi.vendorid = ^ParamTwo^
					--AND vbi.vendorid = 72861
                    AND vbi.vendorname IN ( Select distinct vendorname from v_vendorbudgetinfo where vendorid = ^ParamTwo^ )
					--AND vbi.vendorname IN ( Select distinct vendorname from v_vendorbudgetinfo where vendorid = 72861 )
                    AND ( ( VBI.budgetperiodstartdate >= cast('''+@pDateStart+'''as date)
                            AND VBI.budgetperiodenddate <= cast('''+@pDateEnd+'''as date) )
                           OR ( VBI.budgetperiodstartdate <= cast('''+@pDateStart+'''as date)
                                AND VBI.budgetperiodenddate >= cast('''+@pDateEnd+'''as date) )
                           OR ( VBI.budgetperiodstartdate <= cast('''+@pDateStart+'''as date)
                                AND VBI.budgetperiodenddate >= cast('''+@pDateStart+'''as date) )
                           OR ( VBI.budgetperiodstartdate >= cast('''+@pDateStart+'''as date)
                                AND VBI.budgetperiodstartdate <= cast('''+@pDateEnd+'''as date)
                                AND VBI.budgetperiodenddate >= cast('''+@pDateEnd+'''as date) ) )
                    AND ( CASE
                            WHEN islom = 1 THEN( CASE
                                                   WHEN ( ( ( VBI.matteropendate <= cast('''+@pDateEnd+'''as date) )
                                                            AND Isnull(VBI.matterclosedate, {d ''9999-12-31'' }) > cast('''+@pDateEnd+'''as date) )
                                                           OR ( ( VBI.matteropendate <= cast('''+@pDateEnd+'''as date) )
                                                                AND Datediff(month, Isnull(VBI.matterclosedate, {d ''9999-12-31'' }), cast('''+@pDateEnd+'''as date)) <= 12 ) ) THEN 1
                                                   ELSE 0
                                                 END )
                            ELSE 0
                          END ) = 1
             GROUP  BY rolluppracticeareaid,
                       rolluppracticeareaname) Spend
         ON Budget.rolluppracticeareaid = Spend.rolluppracticeareaid
GROUP  BY --Budget.rolluppracticeareaid,
Budget.rolluppracticeareaname,
--ili.currencycode,
spend,
Budget.CurrencyCode
ORDER  BY spend DESC '
Print (@SQL)
EXEC(@SQL)