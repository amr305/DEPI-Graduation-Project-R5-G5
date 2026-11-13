-- ============================================================================
-- Script 04: Data Warehouse Validation & Analytical Queries
-- ============================================================================

USE MTA_Transit_DW;
GO

-- ============================================================================
-- 1. STAR SCHEMA ROW COUNT AUDIT
-- ============================================================================
SELECT 'Dim_Date' AS TableName, COUNT(*) AS TotalRows FROM dw.Dim_Date
UNION ALL SELECT 'Dim_Agency', COUNT(*) FROM dw.Dim_Agency
UNION ALL SELECT 'Dim_Location', COUNT(*) FROM dw.Dim_Location
UNION ALL SELECT 'Dim_Service_Details', COUNT(*) FROM dw.Dim_Service_Details
UNION ALL SELECT 'Dim_Incident_Category', COUNT(*) FROM dw.Dim_Incident_Category
UNION ALL SELECT 'Fact_Ridership_Actuals', COUNT(*) FROM dw.Fact_Ridership_Actuals
UNION ALL SELECT 'Fact_Operations_Financials', COUNT(*) FROM dw.Fact_Operations_Financials
UNION ALL SELECT 'Fact_Incidents', COUNT(*) FROM dw.Fact_Incidents
UNION ALL SELECT 'Fact_Ridership_Forecast', COUNT(*) FROM dw.Fact_Ridership_Forecast;
GO

-- ============================================================================
-- 2. STAGING VS. DATA WAREHOUSE RECONCILIATION AUDIT
-- ============================================================================
SELECT 
    'Ridership' AS Dataset,
    (SELECT COUNT(*) FROM stg.MTA_Ridership_Cleaned) AS StagingRows,
    (SELECT COUNT(*) FROM dw.Fact_Ridership_Actuals) AS FactRows
UNION ALL
SELECT 
    'Financials',
    (SELECT COUNT(*) FROM stg.MTA_Financials_Cleaned),
    (SELECT COUNT(*) FROM dw.Fact_Operations_Financials)
UNION ALL
SELECT 
    'Incidents',
    (SELECT COUNT(*) FROM stg.MTA_Incidents_Cleaned),
    (SELECT COUNT(*) FROM dw.Fact_Incidents)
UNION ALL
SELECT 
    'Forecast (180 days x 7 agencies)',
    (SELECT COUNT(*) * 7 FROM stg.MTA_180Day_Forecast),
    (SELECT COUNT(*) FROM dw.Fact_Ridership_Forecast);
GO

-- ============================================================================
-- 3. ANALYTICAL QUERY 1: Ridership & Pre-Pandemic Recovery by Agency & Year
-- ============================================================================
SELECT 
    d.[Year],
    a.AgencyName,
    a.ModeCategory,
    SUM(r.EstimatedRidership) AS TotalRidership,
    ROUND(AVG(r.PctPrePandemic), 2) AS AvgPrePandemicRecoveryPct
FROM dw.Fact_Ridership_Actuals r
JOIN dw.Dim_Date d ON r.DateKey = d.DateKey
JOIN dw.Dim_Agency a ON r.AgencyKey = a.AgencyKey
GROUP BY d.[Year], a.AgencyName, a.ModeCategory
ORDER BY d.[Year], TotalRidership DESC;
GO

-- ============================================================================
-- 4. ANALYTICAL QUERY 2: Financial Efficiency & On-Time Performance by Agency
-- ============================================================================
SELECT 
    a.AgencyName,
    SUM(f.ScheduledTrips) AS TotalScheduledTrips,
    ROUND(SUM(f.GrossFareRevenueUSD), 2) AS TotalRevenueUSD,
    ROUND(SUM(f.OperatingExpenseUSD), 2) AS TotalExpenseUSD,
    ROUND(SUM(f.GrossFareRevenueUSD) - SUM(f.OperatingExpenseUSD), 2) AS NetOperatingBalanceUSD,
    ROUND(AVG(f.OnTimePerformancePct), 2) AS AvgOnTimePerformancePct
FROM dw.Fact_Operations_Financials f
JOIN dw.Dim_Agency a ON f.AgencyKey = a.AgencyKey
GROUP BY a.AgencyName
ORDER BY TotalRevenueUSD DESC;
GO

-- ============================================================================
-- 5. ANALYTICAL QUERY 3: Top Incident Categories by Delay Impact & Repair Cost
-- ============================================================================
SELECT 
    ic.IncidentCategory,
    a.AgencyName,
    COUNT(i.IncidentFactID) AS IncidentCount,
    SUM(i.DelayImpactMinutes) AS TotalDelayMinutes,
    ROUND(SUM(i.EstimatedRepairCostUSD), 2) AS TotalRepairCostUSD
FROM dw.Fact_Incidents i
JOIN dw.Dim_Incident_Category ic ON i.IncidentCategoryKey = ic.IncidentCategoryKey
JOIN dw.Dim_Agency a ON i.AgencyKey = a.AgencyKey
GROUP BY ic.IncidentCategory, a.AgencyName
ORDER BY TotalRepairCostUSD DESC;
GO

-- ============================================================================
-- 6. ANALYTICAL QUERY 4: Monthly 180-Day Prophet Forecast Summary
-- ============================================================================
SELECT 
    d.[Year],
    d.[Month],
    d.MonthName,
    a.AgencyName,
    ROUND(SUM(fc.PredictedRidership), 0) AS ProjectedMonthlyRidership,
    ROUND(SUM(fc.LowerBound), 0) AS ProjectedLowerBound95,
    ROUND(SUM(fc.UpperBound), 0) AS ProjectedUpperBound95
FROM dw.Fact_Ridership_Forecast fc
JOIN dw.Dim_Date d ON fc.DateKey = d.DateKey
JOIN dw.Dim_Agency a ON fc.AgencyKey = a.AgencyKey
GROUP BY d.[Year], d.[Month], d.MonthName, a.AgencyName
ORDER BY a.AgencyName, d.[Year], d.[Month];
GO