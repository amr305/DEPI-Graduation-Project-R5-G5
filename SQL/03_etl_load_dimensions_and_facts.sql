-- ============================================================================
-- Script 03: ETL - Populate Dimension and Fact Tables from Staging
-- Prerequisite: Run 02_create_star_schema_tables.sql with populated stg tables
-- ============================================================================

USE MTA_Transit_DW;
GO

-- ============================================================================
-- 1. POPULATE DIMENSIONS
-- ============================================================================

-- 1A. Populate Dim_Date (Continuous calendar: 2020-01-01 to 2026-12-31)
WITH DateSequence AS (
    SELECT CAST('2020-01-01' AS DATE) AS FullDate
    UNION ALL
    SELECT DATEADD(DAY, 1, FullDate)
    FROM DateSequence
    WHERE FullDate < '2026-12-31'
)
INSERT INTO dw.Dim_Date (DateKey, FullDate, [Year], [Quarter], [Month], MonthName, DayOfWeek, DayName, IsWeekend)
SELECT 
    CAST(FORMAT(FullDate, 'yyyyMMdd') AS INT) AS DateKey,
    FullDate,
    YEAR(FullDate),
    DATEPART(QUARTER, FullDate),
    MONTH(FullDate),
    DATENAME(MONTH, FullDate),
    DATEPART(WEEKDAY, FullDate),
    DATENAME(WEEKDAY, FullDate),
    CASE WHEN DATEPART(WEEKDAY, FullDate) IN (1, 7) THEN 1 ELSE 0 END
FROM DateSequence
OPTION (MAXRECURSION 3000);
GO

-- 1B. Populate Dim_Agency
INSERT INTO dw.Dim_Agency (AgencyName, ModeCategory, UnitOfMeasure)
SELECT DISTINCT 
    Agency AS AgencyName,
    CASE 
        WHEN Agency LIKE '%Bridge%' OR Agency LIKE '%Tunnel%' THEN 'Vehicular'
        WHEN Agency LIKE '%Bus%' THEN 'Bus'
        WHEN Agency LIKE '%Access%' THEN 'Paratransit'
        ELSE 'Rail'
    END AS ModeCategory,
    CASE 
        WHEN Agency LIKE '%Bridge%' OR Agency LIKE '%Tunnel%' THEN 'Vehicles'
        ELSE 'Riders'
    END AS UnitOfMeasure
FROM (
    SELECT Agency FROM stg.MTA_Ridership_Cleaned
    UNION
    SELECT Agency FROM stg.MTA_Financials_Cleaned
    UNION
    SELECT Agency FROM stg.MTA_Incidents_Cleaned
) a
WHERE Agency IS NOT NULL;
GO

-- 1C. Populate Dim_Location (Merge Stations, Ridership, and Incidents)
INSERT INTO dw.Dim_Location (Borough, StationComplex, Latitude, Longitude, LineCount, ADAAccessible)
SELECT DISTINCT
    ISNULL(Borough, 'Not Applicable'),
    LEFT(ISNULL(Station_Complex, 'Not Applicable'), 255),
    Latitude,
    Longitude,
    Line_Count,
    ADA_Accessible
FROM stg.MTA_Stations_Cleaned;

INSERT INTO dw.Dim_Location (Borough, StationComplex)
SELECT DISTINCT
    ISNULL(r.Borough, 'Not Applicable'),
    LEFT(ISNULL(r.Station_Complex, 'Not Applicable'), 255)
FROM stg.MTA_Ridership_Cleaned r
WHERE NOT EXISTS (
    SELECT 1 FROM dw.Dim_Location l
    WHERE l.Borough = ISNULL(r.Borough, 'Not Applicable')
      AND l.StationComplex = LEFT(ISNULL(r.Station_Complex, 'Not Applicable'), 255)
);

INSERT INTO dw.Dim_Location (Borough, StationComplex)
SELECT DISTINCT
    'Not Applicable',
    LEFT(ISNULL(i.Station_Complex, 'Not Applicable'), 255)
FROM stg.MTA_Incidents_Cleaned i
WHERE NOT EXISTS (
    SELECT 1 FROM dw.Dim_Location l
    WHERE l.StationComplex = LEFT(ISNULL(i.Station_Complex, 'Not Applicable'), 255)
);
GO

-- 1D. Populate Dim_Service_Details
INSERT INTO dw.Dim_Service_Details (TimeShift, PaymentType)
SELECT DISTINCT
    ISNULL(Time_Shift, 'Not Applicable'),
    ISNULL(Payment_Type, 'Not Applicable')
FROM (
    SELECT Time_Shift, Payment_Type FROM stg.MTA_Ridership_Cleaned
    UNION
    SELECT Time_Shift, 'Not Applicable' FROM stg.MTA_Financials_Cleaned
    UNION
    SELECT Time_Shift, 'Not Applicable' FROM stg.MTA_Incidents_Cleaned
) s;
GO

-- 1E. Populate Dim_Incident_Category
INSERT INTO dw.Dim_Incident_Category (IncidentCategory)
SELECT DISTINCT ISNULL(Incident_Category, 'Uncategorized')
FROM stg.MTA_Incidents_Cleaned;
GO

-- ============================================================================
-- 2. POPULATE FACT TABLES
-- ============================================================================

-- 2A. Populate Fact_Ridership_Actuals
INSERT INTO dw.Fact_Ridership_Actuals (
    DateKey, AgencyKey, LocationKey, ServiceDetailKey,
    EstimatedRidership, PctPrePandemic, IsZeroRidership, AbovePrePandemic
)
SELECT 
    d.DateKey,
    a.AgencyKey,
    l.LocationKey,
    sd.ServiceDetailKey,
    r.Estimated_Ridership,
    r.Pct_Pre_Pandemic,
    ISNULL(CAST(r.Is_Zero_Ridership AS BIT), 0),
    ISNULL(r.Above_Pre_Pandemic, 0)
FROM stg.MTA_Ridership_Cleaned r
JOIN dw.Dim_Date d ON r.[Date] = d.FullDate
JOIN dw.Dim_Agency a ON r.Agency = a.AgencyName
JOIN dw.Dim_Location l 
    ON ISNULL(r.Borough, 'Not Applicable') = l.Borough 
   AND LEFT(ISNULL(r.Station_Complex, 'Not Applicable'), 255) = l.StationComplex
JOIN dw.Dim_Service_Details sd 
    ON ISNULL(r.Time_Shift, 'Not Applicable') = sd.TimeShift 
   AND ISNULL(r.Payment_Type, 'Not Applicable') = sd.PaymentType;
GO

-- 2B. Populate Fact_Operations_Financials
INSERT INTO dw.Fact_Operations_Financials (
    DateKey, AgencyKey, ServiceDetailKey,
    ScheduledTrips, TotalSeatCapacity, GrossFareRevenueUSD,
    OperatingExpenseUSD, TotalDelayMinutes, OnTimePerformancePct, IsZeroFareRevenue
)
SELECT 
    d.DateKey,
    a.AgencyKey,
    sd.ServiceDetailKey,
    f.Scheduled_Trips,
    f.Total_Seat_Capacity,
    f.Gross_Fare_Revenue_USD,
    f.Operating_Expense_USD,
    f.Total_Delay_Minutes,
    f.On_Time_Performance_Pct,
    ISNULL(CAST(f.Is_Zero_Fare_Revenue AS BIT), 0)
FROM stg.MTA_Financials_Cleaned f
JOIN dw.Dim_Date d ON f.[Date] = d.FullDate
JOIN dw.Dim_Agency a ON f.Agency = a.AgencyName
JOIN dw.Dim_Service_Details sd 
    ON ISNULL(f.Time_Shift, 'Not Applicable') = sd.TimeShift 
   AND sd.PaymentType = 'Not Applicable';
GO

-- 2C. Populate Fact_Incidents
INSERT INTO dw.Fact_Incidents (
    IncidentID, DateKey, AgencyKey, LocationKey, ServiceDetailKey, IncidentCategoryKey,
    DelayImpactMinutes, EstimatedRepairCostUSD
)
SELECT 
    ISNULL(i.Incident_ID, 'Unknown'),
    d.DateKey,
    a.AgencyKey,
    l.LocationKey,
    sd.ServiceDetailKey,
    ic.IncidentCategoryKey,
    i.Delay_Impact_Minutes,
    i.Estimated_Repair_Cost_USD
FROM stg.MTA_Incidents_Cleaned i
JOIN dw.Dim_Date d ON i.[Date] = d.FullDate
JOIN dw.Dim_Agency a ON i.Agency = a.AgencyName
OUTER APPLY (
    SELECT TOP 1 LocationKey 
    FROM dw.Dim_Location loc 
    WHERE loc.StationComplex = LEFT(ISNULL(i.Station_Complex, 'Not Applicable'), 255)
    ORDER BY CASE WHEN loc.Borough <> 'Not Applicable' THEN 0 ELSE 1 END
) l
JOIN dw.Dim_Service_Details sd 
    ON ISNULL(i.Time_Shift, 'Not Applicable') = sd.TimeShift 
   AND sd.PaymentType = 'Not Applicable'
JOIN dw.Dim_Incident_Category ic 
    ON ISNULL(i.Incident_Category, 'Uncategorized') = ic.IncidentCategory;
GO

-- 2D. Populate Fact_Ridership_Forecast (Unpivoted from Wide Staging Format)
WITH UnpivotedForecast AS (
    SELECT [Date], 'Subways' AS AgencyMatch, Subways_Ridership_Forecast AS Forecast, Subways_Ridership_Lower AS LowerB, Subways_Ridership_Upper AS UpperB FROM stg.MTA_180Day_Forecast
    UNION ALL
    SELECT [Date], 'Buses', Buses_Ridership_Forecast, Buses_Ridership_Lower, Buses_Ridership_Upper FROM stg.MTA_180Day_Forecast
    UNION ALL
    SELECT [Date], 'LIRR', LIRR_Ridership_Forecast, LIRR_Ridership_Lower, LIRR_Ridership_Upper FROM stg.MTA_180Day_Forecast
    UNION ALL
    SELECT [Date], 'Metro-North', MetroNorth_Ridership_Forecast, MetroNorth_Ridership_Lower, MetroNorth_Ridership_Upper FROM stg.MTA_180Day_Forecast
    UNION ALL
    SELECT [Date], 'Access-A-Ride', AccessARide_Ridership_Forecast, AccessARide_Ridership_Lower, AccessARide_Ridership_Upper FROM stg.MTA_180Day_Forecast
    UNION ALL
    SELECT [Date], 'Bridges and Tunnels', Bridges_Tunnels_Ridership_Forecast, Bridges_Tunnels_Ridership_Lower, Bridges_Tunnels_Ridership_Upper FROM stg.MTA_180Day_Forecast
    UNION ALL
    SELECT [Date], 'Staten Island Railway', StatenIsland_Ridership_Forecast, StatenIsland_Ridership_Lower, StatenIsland_Ridership_Upper FROM stg.MTA_180Day_Forecast
)
INSERT INTO dw.Fact_Ridership_Forecast (DateKey, AgencyKey, PredictedRidership, LowerBound, UpperBound)
SELECT 
    d.DateKey,
    a.AgencyKey,
    u.Forecast,
    u.LowerB,
    u.UpperB
FROM UnpivotedForecast u
JOIN dw.Dim_Date d ON u.[Date] = d.FullDate
JOIN dw.Dim_Agency a ON a.AgencyName LIKE '%' + u.AgencyMatch + '%'
WHERE u.Forecast IS NOT NULL;
GO