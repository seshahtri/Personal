--use C00348_IOD_DataMart;

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
--SET @pDateStart='3/1/2021';
--SET @pDateEnd='2/28/2022';
--SET @InvoiceStatus = 'Paid'',''Processed';


SET @SQL = '
exec as user = ''admin''
IF OBJECT_ID(''tempdb..#KpiDataTest'') IS NOT NULL DROP TABLE #KpiDataTest
	SELECT
	  RoleName as ''Role'',
	  currencycode as ''Currency Code'',
	  Fees as ''Net Fee Amount'',
	  (Units / SUM(Units) OVER (PARTITION BY 1)) * 100 [ % of Total Hours]
	  ,Hours
	  INTO #KpiDataTest
	  from
	(select
		  RoleId as ''RoleId'',
		  roleName as ''RoleName'',
		  sum(grossfeeamountforrates*isnull(exchangerate,1)) as ''Fees'',
		  SUM(FeeUnits) AS Units,
		  ed.CurrencyCode,
		  SUM(hoursforrates) as Hours from
	v_invoicetimekeepersummary its
	JOIN Exchangeratedim ed on ed.ExchangeRateDate = its.ExchangeRateDate
	 JOIN BusinessUnitAndAllDescendants bu on bu.ChildBusinessUnitId=its.BusinessUnitId
                    JOIN (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
                            FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] (''-1'', ''|'',-1,0)) b on bu.BusinessUnitId=b.RollupBusinessUnitId --replace 0 with 1 and apply BU filter
                    JOIN PracticeAreaAndAllDescendants pa on pa.childpracticeareaid=its.practiceareaid
                    JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
                            FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''-1'', ''|'',-1,1)) p on pa.practiceareaid=p.rolluppracticeareaid
	 WHERE
							its.InvoiceStatus IN ('''+@InvoiceStatus+''')
							AND ed.Currencycode = '''+@CurrencyCode+'''
							AND its.PaymentDate between '''+@pDateStart+''' and '''+@pDateEnd+'''
							AND its.TimekeeperRoleId is NOT NULL
							AND its.HOURS > 0.01
							AND its.RoleName is NOT NULL
							and grossfeeamountforrates>0
							--and p.[RollupPracticeAreaName] like ''AAAA Benefit-002361''
--and b.RollupBusinessUnitName like ''%Zone-SOUTHEAST ZONE%''
--and its.Mattername like ''CANO, INES vs. AAAA Benefit-002361'' -- Matter Name
--and its.MatterOwnerName = ''ROSSOW, MADOLORES'' -- Matter Owner Name
--and its.VendorId  = 44224 -- Vendor Filter Use this query to identify vendor id from name (select VendorId from vendordim where vendorname like ''Wilson, Elser, Moskowitz, Edelman & Dicker, LLP---Houston'''')
--and its.VendorType = ''TPA''
--and its.matterdf01 = ''USA'' -- Country
--and its.matterdf02 = ''Unspecified'' -- Coverage Group
--and its.matterdf03 = ''AB'' -- Coverage Type
--and its.matterdf04 = ''AL'' -- Benefit State
--and its.matterdf05 = ''AL''  -- Accident State
--and its.matterdf06 = ''RE'' -- Status Code
--and its.matterdf07 = ''003632421711GB01'' -- Claim Number
--and its.matterdf08 like  ''GB-Houston%'' -- GB Branch Name
--and its.matterdf09 = ''000216'' -- GB Branch Number
   
	GRoup by RoleId, RoleName, currencycode
		   ) s
	select
	  *
	from
	  #KpiDataTest
	order by
	  Hours desc
'
print(@SQL);
exec(@SQL);
 