--use DEV044_IOD_DataMart;

DECLARE @pDateStart varchar (MAX);
DECLARE @pDateEnd varchar (MAX);
DECLARE @DateField varchar (MAX);
DECLARE @InvoiceStatus nvarchar (MAX);
DECLARE @CurrencyCode varchar (MAX);
DECLARE @SQL VARCHAR(MAX);
DECLARE @MatterName varchar (MAX);
DECLARE @MatterNumber varchar (MAX);
DECLARE @MatterStatus varchar (MAX);
DECLARE @MatterOwnerName varchar (MAX);
DECLARE @VendorName varchar (MAX);
DECLARE @VendorType varchar (MAX);
DECLARE @PracticeAreaName varchar (MAX);
DECLARE @PracticeAreaId varchar(MAX);
DECLARE @BusinessUnitName varchar (MAX);
DECLARE @BusinessUnitId varchar(MAX);
DECLARE @MatterDynamicField1 varchar(MAX);
DECLARE @MatterDynamicField2 varchar(MAX);
DECLARE @MatterVendorDynamicField1 varchar(MAX);
DECLARE @MatterVendorDynamicField2 varchar(MAX);
DECLARE @MatterownerId varchar(MAX);



SET @pDateStart= ^StartDate^;
SET @pDateEnd= ^EndDate^;
--SET @InvoiceStatus= ^InvoiceStatus^;
SET @CurrencyCode= ^Currency^;
SET @DateField=^InvoiceDate^;
SET @MatterName=^MatterName^;
SET @MatterNumber=^MatterNumber^;
SET @MatterStatus=^MatterStatus^;
SET @MatterOwnerName =^MatterOwner^;;
SET @VendorName=^VendorName^;
SET @VendorType =^VendorType^;
SET @PracticeAreaName =^PracticeArea^;
SET @BusinessUnitName=^BusinessUnit^;
SET @MatterDynamicField1=^DFMatterDynamicField1^;
SET @MatterDynamicField2=^DFMatterDynamicField2^;
SET @MatterVendorDynamicField1=^DFMatterVendorDynamicField1^;
SET @MatterVendorDynamicField2=^DFMatterVendorDynamicField2^;

--SET @pDateStart= '1/1/2017';
--SET @pDateEnd= '12/31/2017';
SET @InvoiceStatus= '''Paid'',''Processed''';
--SET @CurrencyCode= 'USD';
--SET @DateField='InvoiceDate';
--SET @MatterName='-1';--'Matter 3686999';
--SET @MatterNumber='-1';
--SET @MatterStatus='-1';
--SET @MatterOwnerName ='-1';--'Katsopolis, Jesse';
--SET @VendorName='-1';--'Caron & Landry LLP';
--SET @VendorType ='-1';--'Law Firm';
--SET @PracticeAreaName ='-1'; -- --Employment and Labor --Consumer Finance
--SET @BusinessUnitName='-1';--'NorthEast';--'NorthEast';
--SET @MatterDynamicField1='-1';--'Unspecified';
--SET @MatterDynamicField2='-1';
--SET @MatterVendorDynamicField1='-1';--'Unspecified';
--SET @MatterVendorDynamicField2='-1';



SET @PracticeAreaId = ISNULL((SELECT TOP 1 p.PracticeAreaId FROM PracticeAreaDim p WHERE p.PracticeAreaName = @PracticeAreaName),-1)
SET @BusinessUnitId = ISNULL((SELECT TOP 1 b.BusinessUnitId FROM BusinessUnitDim b where b.BusinessUnitName = @BusinessUnitName),-1)
SET @MatterownerId = ISNULL((SELECT TOP 1 d.timekeeperid FROM timekeeperdim d WHERE d.fullname = @MatterOwnerName),-1)

SET @SQL='

EXEC AS USER = ''admin''

IF OBJECT_ID(''tempdb..#MatterStatusHistory'') IS NOT NULL DROP TABLE #MatterStatusHistory

  SELECT MatterId, ''Open'' MatterHistoryStatus, MatterOpenDate StartDate, ''3000-01-01 00:00:00.000'' EndDate
   INTO #MatterStatusHistory
  from MatterDim M
  JOIN BusinessUnitAndAllDescendants BAD ON M.BusinessUnitId = BAD.ChildBusinessUnitId
JOIN (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM fn_GetRollupBusinessUnitsWithSecurity (''' + @BusinessUnitId + ''', ''|'',-1,0)) BUS ON BAD.BusinessUnitId = BUS.RollupBusinessUnitId
JOIN PracticeAreaAndAllDescendants PAD ON M.PracticeAreaId = PAD.ChildPracticeAreaId
JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM fn_GetRollupPracticeAreasWithSecurity2 (''' + @PracticeAreaId + ''', ''|'',-1,0)) PAS ON PAD.PracticeAreaId = PAS.RollupPracticeAreaId
  WHERE MatterStatus = ''Open''
  AND (ISNULL(''' + @MatterName + ''', ''-1'') = ''-1'' OR MatterName=''' + @MatterName + ''')
AND (ISNULL(''' + @MatterNumber + ''', ''-1'') = ''-1'' OR MatterNumber=''' + @MatterNumber + ''')
AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR
CASE WHEN MatterCloseDate IS NULL THEN ''Open''
WHEN MatterCloseDate > ''' + @pDateEnd + ''' THEN ''Open''
ELSE ''Closed'' END =''' + @MatterStatus + ''')
AND (ISNULL('''+@MatterOwnerId +''', ''-1'') = ''-1'' OR MatterownerId='''+ @MatterOwnerId +''')
--AND (ISNULL(''' + @MatterOwnerName + ''', ''-1'') = ''-1'' OR MatterOwnerName=''' + @MatterOwnerName + ''')
--AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR MatterDF01=''' + @MatterDynamicField1 + ''')
--AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR MatterDF02=''' + @MatterDynamicField2 + ''')
--AND (ISNULL(''' + @MatterVendorDynamicField1 + ''', ''-1'') = ''-1'' OR MatterVendorDF01=''' + @MatterVendorDynamicField1 + ''')
--AND (ISNULL(''' + @MatterVendorDynamicField2 + ''', ''-1'') = ''-1'' OR MatterVendorDF02=''' + @MatterVendorDynamicField2 + ''')
--AND (ISNULL(''' + @VendorName + ''', ''-1'') = ''-1'' OR VendorName=''' + @VendorName + ''')
--AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR VendorType=''' + @VendorType + ''')
  
  UNION ALL
  
  SELECT MatterId, ''Open'', MatterOpenDate StartDate, MatterCloseDate EndDate
  from MatterDim M
  JOIN BusinessUnitAndAllDescendants BAD ON M.BusinessUnitId = BAD.ChildBusinessUnitId
JOIN (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM fn_GetRollupBusinessUnitsWithSecurity (''' + @BusinessUnitId + ''', ''|'',-1,0)) BUS ON BAD.BusinessUnitId = BUS.RollupBusinessUnitId
JOIN PracticeAreaAndAllDescendants PAD ON M.PracticeAreaId = PAD.ChildPracticeAreaId
JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM fn_GetRollupPracticeAreasWithSecurity2 (''' + @PracticeAreaId + ''', ''|'',-1,0)) PAS ON PAD.PracticeAreaId = PAS.RollupPracticeAreaId
  WHERE MatterStatus = ''Closed''
  AND (ISNULL(''' + @MatterName + ''', ''-1'') = ''-1'' OR MatterName=''' + @MatterName + ''')
AND (ISNULL(''' + @MatterNumber + ''', ''-1'') = ''-1'' OR MatterNumber=''' + @MatterNumber + ''')
AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR
CASE WHEN MatterCloseDate IS NULL THEN ''Open''
WHEN MatterCloseDate > ''' + @pDateEnd + ''' THEN ''Open''
ELSE ''Closed'' END =''' + @MatterStatus + ''')
AND (ISNULL('''+@MatterOwnerId +''', ''-1'') = ''-1'' OR MatterownerId='''+ @MatterOwnerId +''')
--AND (ISNULL(''' + @MatterOwnerName + ''', ''-1'') = ''-1'' OR MatterOwnerName=''' + @MatterOwnerName + ''')
--AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR MatterDF01=''' + @MatterDynamicField1 + ''')
--AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR MatterDF02=''' + @MatterDynamicField2 + ''')
--AND (ISNULL(''' + @MatterVendorDynamicField1 + ''', ''-1'') = ''-1'' OR MatterVendorDF01=''' + @MatterVendorDynamicField1 + ''')
--AND (ISNULL(''' + @MatterVendorDynamicField2 + ''', ''-1'') = ''-1'' OR MatterVendorDF02=''' + @MatterVendorDynamicField2 + ''')
--AND (ISNULL(''' + @VendorName + ''', ''-1'') = ''-1'' OR VendorName=''' + @VendorName + ''')
--AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR VendorType=''' + @VendorType + ''')
  
  UNION ALL
  
  SELECT MatterId, ''Closed'', MatterCloseDate  StartDate, ''3000-01-01 00:00:00.000'' EndDate
  from MatterDim M
  JOIN BusinessUnitAndAllDescendants BAD ON M.BusinessUnitId = BAD.ChildBusinessUnitId
JOIN (SELECT RollupBusinessUnitId, RollupBusinessUnitName, RollupBusinessUnitPath, RollupBusinessUnitDisplayPath, RollupBusinessUnitLevel
FROM fn_GetRollupBusinessUnitsWithSecurity (''' + @BusinessUnitId + ''', ''|'',-1,0)) BUS ON BAD.BusinessUnitId = BUS.RollupBusinessUnitId
JOIN PracticeAreaAndAllDescendants PAD ON M.PracticeAreaId = PAD.ChildPracticeAreaId
JOIN (SELECT RollupPracticeAreaId, RollupPracticeAreaName, RollupPracticeAreaPath, RollupPracticeAreaDisplayPath, RollupPracticeAreaLevel
FROM fn_GetRollupPracticeAreasWithSecurity2 (''' + @PracticeAreaId + ''', ''|'',-1,0)) PAS ON PAD.PracticeAreaId = PAS.RollupPracticeAreaId
  WHERE MatterStatus = ''Closed''
  AND (ISNULL(''' + @MatterName + ''', ''-1'') = ''-1'' OR MatterName=''' + @MatterName + ''')
AND (ISNULL(''' + @MatterNumber + ''', ''-1'') = ''-1'' OR MatterNumber=''' + @MatterNumber + ''')
AND (ISNULL(''' + @MatterStatus + ''', ''-1'') = ''-1'' OR
CASE WHEN MatterCloseDate IS NULL THEN ''Open''
WHEN MatterCloseDate > ''' + @pDateEnd + ''' THEN ''Open''
ELSE ''Closed'' END =''' + @MatterStatus + ''')
AND (ISNULL('''+@MatterOwnerId +''', ''-1'') = ''-1'' OR MatterownerId='''+ @MatterOwnerId +''')
--AND (ISNULL(''' + @MatterOwnerName + ''', ''-1'') = ''-1'' OR MatterOwnerName=''' + @MatterOwnerName + ''')
--AND (ISNULL(''' + @MatterDynamicField1 + ''', ''-1'') = ''-1'' OR MatterDF01=''' + @MatterDynamicField1 + ''')
--AND (ISNULL(''' + @MatterDynamicField2 + ''', ''-1'') = ''-1'' OR MatterDF02=''' + @MatterDynamicField2 + ''')
--AND (ISNULL(''' + @MatterVendorDynamicField1 + ''', ''-1'') = ''-1'' OR MatterVendorDF01=''' + @MatterVendorDynamicField1 + ''')
--AND (ISNULL(''' + @MatterVendorDynamicField2 + ''', ''-1'') = ''-1'' OR MatterVendorDF02=''' + @MatterVendorDynamicField2 + ''')
--AND (ISNULL(''' + @VendorName + ''', ''-1'') = ''-1'' OR VendorName=''' + @VendorName + ''')
--AND (ISNULL(''' + @VendorType + ''', ''-1'') = ''-1'' OR VendorType=''' + @VendorType + ''')


IF OBJECT_ID(''tempdb..#MatterCounts'') IS NOT NULL DROP TABLE #MatterCounts
SELECT 
SUM(CAST((CASE WHEN (mh.MatterHistoryStatus = ''Open'') THEN 1 WHEN NOT (mh.MatterHistoryStatus = ''Open'') THEN 0 ELSE NULL END) as BIGINT)) - SUM(CAST((CASE WHEN (mh.MatterHistoryStatus = ''Closed'') THEN 1 WHEN NOT (mh.MatterHistoryStatus = ''Closed'') THEN 0 ELSE NULL END) as BIGINT)) AS Delta,
SUM(CAST((CASE WHEN ((mh.MatterHistoryStatus = ''Open'') AND (mh.StartDate >= '''+@pDateStart+''')) THEN 1 WHEN NOT ((mh.MatterHistoryStatus = ''Open'') AND (mh.StartDate >= '''+@pDateStart+''')) THEN 0 ELSE NULL END) as BIGINT)) AS OpenMatters,
SUM(CAST((CASE WHEN ((mh.MatterHistoryStatus = ''Closed'') AND (mh.StartDate >= '''+@pDateStart+''')) THEN 1 WHEN NOT ((mh.MatterHistoryStatus = ''Closed'') AND (mh.StartDate >= '''+@pDateStart+''')) THEN 0 ELSE NULL END) as BIGINT)) AS ClosedMatters,
DATEPART(year,(CASE WHEN (mh.StartDate >= '''+@pDateStart+''') THEN mh.StartDate WHEN NOT (mh.StartDate >= '''+@pDateStart+''') THEN '''+@pDateStart+''' ELSE NULL END)) AS MHYear,
DATEPART(Month,(CASE WHEN (mh.StartDate >= '''+@pDateStart+''') THEN mh.StartDate WHEN NOT (mh.StartDate >= '''+@pDateStart+''') THEN '''+@pDateStart+''' ELSE NULL END)) AS MHMonth
--,PracticeAreaId AS PracticeArea   -- Comment/Uncomment to filter based on Practice Area Name--
, ''Calculation'' running
INTO #MatterCounts
FROM #MatterStatusHistory mh
GROUP BY 
DATEPART(year,(CASE WHEN (mh.StartDate >= '''+@pDateStart+''') THEN mh.StartDate WHEN NOT (mh.StartDate >= '''+@pDateStart+''') THEN '''+@pDateStart+''' ELSE NULL END)),
DATEPART(Month,(CASE WHEN (mh.StartDate >= '''+@pDateStart+''') THEN mh.StartDate WHEN NOT (mh.StartDate >= '''+@pDateStart+''') THEN '''+@pDateStart+''' ELSE NULL END))
--,PracticeAreaId                 -- Comment/Uncomment to filter based on Practice Area Name--
--HAVING count (PracticeAreaId) >= 0  -- Comment/Uncomment to filter based on Practice Area Name--
ORDER BY  mhyear

--GO

SELECT 
--mc.MHYear,
--mc.MHMonth,
case 
when mc.MHMonth = 1 then ''January ''+ cast(mc.MHYear as varchar)
when mc.MHMonth = 2 then ''February ''+ cast(mc.MHYear as varchar)
when mc.MHMonth = 3 then ''March ''+ cast(mc.MHYear as varchar)
when mc.MHMonth = 4 then ''April ''+ cast(mc.MHYear as varchar)
when mc.MHMonth = 5 then ''May ''+ cast(mc.MHYear as varchar)
when mc.MHMonth = 6 then ''June ''+ cast(mc.MHYear as varchar)
when mc.MHMonth = 7 then ''July ''+ cast(mc.MHYear as varchar)
when mc.MHMonth = 8 then ''August ''+ cast(mc.MHYear as varchar)
when mc.MHMonth = 9 then ''September ''+ cast(mc.MHYear as varchar)
when mc.MHMonth = 10 then ''October ''+ cast(mc.MHYear as varchar)
when mc.MHMonth = 11 then ''November ''+ cast(mc.MHYear as varchar)
when mc.MHMonth = 12 then ''December ''+ cast(mc.MHYear as varchar)
end as Month,
mc.ClosedMatters as [Closed Matters],
mc.OpenMatters as [Open Matters],
--mc.PracticeArea,    -- Comment/Uncomment to filter based on Practice Area Name--
--pa.PracticeAreaName,  -- Comment/Uncomment to filter based on Practice Area Name--
--mc.running,
--SUM(mc.ClosedMatters) OVER (PARTITION BY mc.PracticeArea ORDER BY MHYear,MHMonth RANGE UNBOUNDED PRECEDING) as RunningTotalClosedMatters,    -- Comment/Uncomment to filter based on Practice Area Name-- 
--SUM(mc.OpenMatters) OVER (PARTITION BY mc.PracticeArea ORDER BY MHYear,MHMonth RANGE UNBOUNDED PRECEDING) as RunningTotalOpenMatters     -- Comment/Uncomment to filter based on Practice Area Name--    
SUM(mc.ClosedMatters) OVER (PARTITION BY running ORDER BY MHYear,MHMonth RANGE UNBOUNDED PRECEDING) as [Running Sum of Closed Matters], 
SUM(mc.OpenMatters) OVER (PARTITION BY running ORDER BY MHYear,MHMonth RANGE UNBOUNDED PRECEDING) as [Running Sum of Open Matters]
FROM #MatterCounts mc 
--join PracticeAreaDim pa on pa.PracticeAreaId = mc.PracticeArea  -- Comment/Uncomment to filter based on Practice Area Name--
--where pa.PracticeAreaName = ''Administrative Agency'' -- Comment/Uncomment to filter based on Practice Area Name--


ORDER BY 
--pa.PracticeAreaName,  -- Comment/Uncomment to filter based on Practice Area Name--
mc.MHYear, mc.MHMonth desc
'
print(@SQL)
exec(@SQL)
