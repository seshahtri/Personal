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
DECLARE @MatterDF01 varchar (1000);
DECLARE @MatterDF02 varchar (1000);
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

exec as user=''admin''
SELECT DATEPART(year,convert(DATE,T.TimePeriodLongFullName)) Year,DATENAME(month,convert(DATE,T.TimePeriodLongFullName)) Month,
ROUND(AVG(CAST(DATEDIFF(DAY,v.MatterOpenDate,CASE WHEN ISNULL(v.MatterCloseDate,convert(DATETIME,''9999-12-31'')) > TimePeriodEndDate THEN TimePeriodEndDate ELSE v.MatterCloseDate END)AS FLOAT) ),2)  [Average Age],
COUNT(CASE WHEN CAST(DATEDIFF(DAY,v.MatterOpenDate,CASE WHEN ISNULL(v.MatterCloseDate,convert(DATETIME,''9999-12-31'')) > TimePeriodEndDate THEN TimePeriodEndDate ELSE v.MatterCloseDate END)AS FLOAT)  <=30 THEN v.MatterId END) [# of Matters Less than 30 Days],
COUNT(CASE WHEN (CAST(DATEDIFF(DAY,v.MatterOpenDate,CASE WHEN ISNULL(v.MatterCloseDate,convert(DATETIME,''9999-12-31'')) > TimePeriodEndDate THEN TimePeriodEndDate ELSE v.MatterCloseDate END)AS FLOAT)  >=31) AND
(CAST(DATEDIFF(DAY,v.MatterOpenDate,CASE WHEN ISNULL(v.MatterCloseDate,convert(DATETIME,''9999-12-31'')) > TimePeriodEndDate THEN TimePeriodEndDate ELSE v.MatterCloseDate END)AS FLOAT)  <=90)
THEN v.MatterId END) [# of Matters Between 31 and 90 days],
COUNT(CASE WHEN (CAST(DATEDIFF(DAY,v.MatterOpenDate,CASE WHEN ISNULL(v.MatterCloseDate,convert(DATETIME,''9999-12-31'')) > TimePeriodEndDate THEN TimePeriodEndDate ELSE v.MatterCloseDate END)AS FLOAT)  >=91) AND
(CAST(DATEDIFF(DAY,v.MatterOpenDate,CASE WHEN ISNULL(v.MatterCloseDate,convert(DATETIME,''9999-12-31'')) > TimePeriodEndDate THEN TimePeriodEndDate ELSE v.MatterCloseDate END)AS FLOAT)  <=180)
THEN v.MatterId END) [# of Matters Between 91 and 180 days],
COUNT(CASE WHEN (CAST(DATEDIFF(DAY,v.MatterOpenDate,CASE WHEN ISNULL(v.MatterCloseDate,convert(DATETIME,''9999-12-31'')) > TimePeriodEndDate THEN TimePeriodEndDate ELSE v.MatterCloseDate END)AS FLOAT)  >=181) AND
(CAST(DATEDIFF(DAY,v.MatterOpenDate,CASE WHEN ISNULL(v.MatterCloseDate,convert(DATETIME,''9999-12-31'')) > TimePeriodEndDate THEN TimePeriodEndDate ELSE v.MatterCloseDate END)AS FLOAT)  <=360)
THEN v.MatterId END) [# of Matters Between 181 and 360 days],
COUNT(CASE WHEN CAST(DATEDIFF(DAY,v.MatterOpenDate,CASE WHEN ISNULL(v.MatterCloseDate,convert(DATETIME,''9999-12-31'')) > TimePeriodEndDate THEN TimePeriodEndDate ELSE v.MatterCloseDate END)AS FLOAT)  >360 THEN v.MatterId END) [# of Matters > 360 days]
FROM V_MatterSummary V



INNER JOIN BusinessUnitAndAllDescendants B on b.childbusinessunitid=v.BusinessUnitId
inner join 
(SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM [dbo].[fn_GetRollupBusinessUnitsWithSecurity] ('''+ @BusinessUnitId +''', ''|'',-1,0)) ba on ba.RollupBusinessUnitId=b.BusinessUnitId
INNER JOIN PracticeAreaAndAllDescendants P on P.ChildPracticeAreaId=V.PracticeAreaId

INNER JOIN 
(
SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM [dbo].[fn_GetRollupPracticeAreasWithSecurity2] (''' + @PracticeAreaId +''', ''|'',-1,1)) pa on pa.RollupPracticeAreaId=p.PracticeAreaId
INNER JOIN 
(SELECT [TimePeriodId],
       [TimePeriodName],
       [TimePeriodShortFullName],
       [TimePeriodLongFullName],
       [TimePeriodStartDate],
       [TimePeriodEndDate],
       [TimePeriodType]

FROM dbo.[fn_TimePeriodList](''Month'', '''+@pDateStart+''','''+@pDateEnd+''')) T on 1=1 -- Date Range


WHERE CASE WHEN v.MatterOpenDate<=TimePeriodEndDate AND (v.MatterCloseDate IS NULL OR v.MatterCloseDate>TimePeriodStartDate) THEN 1 ELSE 0 END =1

AND (ISNULL('''+@MatterName +''', ''-1'') = ''-1'' OR v.MatterName='''+ @MatterName +''')
AND (ISNULL('''+@MatterNumber +''', ''-1'') = ''-1'' OR v.MatterNumber='''+ @MatterNumber +''')
AND (ISNULL('''+@MatterOwnerId +''', ''-1'') = ''-1'' OR v.MatterownerId='''+ @MatterOwnerId +''')

AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR MatterDF01=''' + @MatterDynamicField1 + ''')
AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR MatterDF02=''' + @MatterDynamicField2 + ''')





GROUP BY  DATEPART(year,convert(DATE,T.TimePeriodLongFullName)),DATENAME(month,convert(DATE,T.TimePeriodLongFullName)),DATEPART(month,convert(DATE,T.TimePeriodLongFullName))
order by DATEPART(year,convert(DATE,T.TimePeriodLongFullName)),DATEPART(month,convert(DATE,T.TimePeriodLongFullName)) 
'
print(@SQL)
exec(@SQL)