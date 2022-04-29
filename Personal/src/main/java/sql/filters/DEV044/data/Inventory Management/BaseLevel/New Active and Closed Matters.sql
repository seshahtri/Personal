
--use DEV044_IOD_DataMart;
DECLARE @CurrencyCode varchar (50);
DECLARE @pDateStart varchar(MAX);
DECLARE @pDateEnd varchar(MAX);
DECLARE @DateField varchar(MAX);
DECLARE @SQL nVARCHAR(max);
DECLARE @InvoiceStatus varchar (MAX);
DECLARE @MatterName varchar (1000);
DECLARE @MatterOwnerName varchar (1000);
DECLARE @MatterNumber varchar (1000);
DECLARE @MatterStatus varchar (1000);
DECLARE @PracticeAreaName varchar (1000);
DECLARE @PracticeAreaId varchar(1000);
DECLARE @BusinessUnitName varchar (1000);
DECLARE @BusinessUnitId varchar(100);
DECLARE @MatterDynamicField1 varchar (1000);
DECLARE @MatterDynamicField2 varchar (1000);
DECLARE @MatterVendorDynamicField1 varchar (1000);
DECLARE @MatterVendorDynamicField2 varchar (1000);
DECLARE @DynamicFieldName1 varchar (1000);
DECLARE @DynamicFieldName2 varchar (1000);
DECLARE @MatterownerId varchar (1000);
DECLARE @VendorName varchar (1000);
DECLARE @VendorType varchar (1000);

SET @pDateStart=^StartDate^;
SET @pDateEnd=^EndDate^;
SET @InvoiceStatus=^InvoiceStatus^;
SET @CurrencyCode=^Currency^;
SET @DateField=^InvoiceDate^;
SET @MatterName=^MatterName^;
SET @MatterNumber=^MatterNumber^;
SET @MatterStatus=^MatterStatus^;
SET @MatterOwnerName=^MatterOwner^;;
SET @PracticeAreaName=^PracticeArea^;
SET @BusinessUnitName=^BusinessUnit^;
SET @MatterDynamicField1= ^DFMatterDynamicField1^;
SET @MatterDynamicField2= ^DFMatterDynamicField2^;
SET @MatterVendorDynamicField1=^DFMatterVendorDynamicField1^;
SET @MatterVendorDynamicField2=^DFMatterVendorDynamicField2^;
SET @VendorName= ^VendorName^;
SET @VendorType= ^VendorType^;


--SET @CurrencyCode ='USD';
--SET @pDateStart='2017-01-01';
--SET @pDateEnd ='2017-12-31';
--SET @InvoiceStatus ='Paid'''',''''Processed';
--SET @MatterName='-1';
--SET @MatterNumber='-1';
--SET @MatterOwnerName='-1';
--SET @MatterDynamicField1='-1';
--SET @MatterDynamicField2='-1';
--SET @MatterStatus='-1';
--SET @PracticeAreaName ='-1';
--SET @BusinessUnitName='-1';
--SET @MatterName='Matter 3686999';
--SET @MatterStatus='Closed';
--SET @PracticeAreaName ='Employment and Labor';
--SET @BusinessUnitName='International';
--SET @MatterNumber='1155280';
--SET @MatterOwnerName='Halpert, Jim'
--SET @MatterDynamicField1='Unspecified';
--SET @MatterDynamicField2='Unspecified';

SET @PracticeAreaId = ISNULL((SELECT TOP 1 p.PracticeAreaId FROM PracticeAreaDim p WHERE p.PracticeAreaName = @PracticeAreaName),-1)
SET @BusinessUnitId = ISNULL((SELECT TOP 1 b.BusinessUnitId FROM BusinessUnitDim b where b.BusinessUnitName = @BusinessUnitName),-1)
SET @MatterownerId = ISNULL((SELECT TOP 1 d.timekeeperid FROM timekeeperdim d WHERE d.fullname = @MatterOwnerName),-1)


SET @SQL = '
exec as user = ''admin''



SELECT
t.YearId as Year,
DateName(month,DateAdd(month, t.monthID , 0) -1) Month,
count(case when [MatterOpenDate]<=t.MonthEndDateTime AND [MatterOpenDate]>=t.MonthStartDateTime THEN [MatterId] else null end) as newmatters,
count(case when [MatterCloseDate]<=t.MonthEndDateTime AND [MatterCloseDate]>=t.MonthStartDateTime THEN [MatterId] else null end) as closedmatters,
count(CASE WHEN [MatterOpenDate]<=t.MonthEndDateTime AND ([MatterCloseDate]>=t.MonthEndDateTime OR [MatterCloseDate] is null) THEN [MatterId] else null end) as Activematters
FROM
V_MatterSummary m cross

join (
SELECT
DISTINCT YearId,
MonthStartDateTime,
month(MonthEndDateTime) monthID,
MonthEndDateTime
FROM
DateDim
WHERE
DayEndTime > = '''+@pDateStart+''' -- Month Start Date
AND DayEndTime <= '''+@pDateEnd+''' -- Month End Date
) t

JOIN BusinessUnitAndAllDescendants BAD ON M.BusinessUnitId = BAD.ChildBusinessUnitId
JOIN (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM fn_GetRollupBusinessUnitsWithSecurity ('''+ @BusinessUnitId +''', ''|'',-1,0)) BUS ON BAD.BusinessUnitId = BUS.RollupBusinessUnitId
INNER JOIN [dbo].[PracticeAreaAndAllDescendants] [PracticeAreaAndAllDescendants] ON (m.[PracticeAreaId] = [PracticeAreaAndAllDescendants].[ChildPracticeAreaId])
INNER JOIN (
SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''' + @PracticeAreaId +''', ''|'',-1,0)
) [RollupPracticeAreasWithSecurity] ON ([PracticeAreaAndAllDescendants].[PracticeAreaId] = [RollupPracticeAreasWithSecurity].[RollupPracticeAreaId])

where 
   (ISNULL('''+@MatterName +''', ''-1'') = ''-1'' OR MatterName='''+ @MatterName +''')
	    
	  AND (ISNULL('''+@MatterNumber +''', ''-1'') = ''-1'' OR MatterNumber='''+ @MatterNumber +''')
AND (ISNULL('''+@MatterOwnerId +''', ''-1'') = ''-1'' OR MatterownerId='''+ @MatterOwnerId +''')
AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR MatterDF01=''' + @MatterDynamicField1 + ''')
AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR MatterDF02=''' + @MatterDynamicField2 + ''')




group by
t.YearId,
t.monthID

  '
  print(@SQL)
  exec(@SQL)
