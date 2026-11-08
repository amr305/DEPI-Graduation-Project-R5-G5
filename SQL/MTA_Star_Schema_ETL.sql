USE MTA_DB;
GO

-- 1. Reset Tables (Prevents duplicate object errors on rerun)
IF OBJECT_ID('Fact_DailyRidership', 'U') IS NOT NULL DROP TABLE Fact_DailyRidership;
IF OBJECT_ID('Dim_Date', 'U') IS NOT NULL DROP TABLE Dim_Date;
IF OBJECT_ID('Dim_Agency', 'U') IS NOT NULL DROP TABLE Dim_Agency;
GO

-- 2. Create Star Schema Tables (DDL)
CREATE TABLE Dim_Date (
    DateKey INT PRIMARY KEY,
    FullDate DATE NOT NULL,
    Year INT NOT NULL,
    Month INT NOT NULL,
    MonthName VARCHAR(20) NOT NULL,
    Day INT NOT NULL,
    DayOfWeek VARCHAR(20) NOT NULL,
    IsWeekend BIT NOT NULL
);

CREATE TABLE Dim_Agency (
    AgencyID INT PRIMARY KEY,
    AgencyName VARCHAR(50) NOT NULL
);

CREATE TABLE Fact_DailyRidership (
    FactID BIGINT IDENTITY(1,1) PRIMARY KEY,
    DateKey INT NOT NULL FOREIGN KEY REFERENCES Dim_Date(DateKey),
    AgencyID INT NOT NULL FOREIGN KEY REFERENCES Dim_Agency(AgencyID),
    RidershipCount BIGINT NOT NULL,
    PrePandemicPct INT NOT NULL
);
GO

-- 3. Populate Dim_Date from Staging_MTA
INSERT INTO Dim_Date (DateKey, FullDate, Year, Month, MonthName, Day, DayOfWeek, IsWeekend)
SELECT DISTINCT
    CONVERT(INT, FORMAT([Date], 'yyyyMMdd')) AS DateKey,
    [Date] AS FullDate,
    [Year],
    [Month],
    MonthName,
    [Day],
    DayOfWeek,
    IsWeekend
FROM Staging_MTA;

-- 4. Populate Dim_Agency
INSERT INTO Dim_Agency (AgencyID, AgencyName) VALUES
(1, 'Subways'),
(2, 'Buses'),
(3, 'LIRR'),
(4, 'Metro-North'),
(5, 'Access-A-Ride'),
(6, 'Bridges and Tunnels'),
(7, 'Staten Island Railway');

-- 5. Populate Fact_DailyRidership from Staging_MTA
INSERT INTO Fact_DailyRidership (DateKey, AgencyID, RidershipCount, PrePandemicPct)
SELECT CONVERT(INT, FORMAT([Date], 'yyyyMMdd')), 1, Subways_Ridership, Subways_PrePandemicPct FROM Staging_MTA UNION ALL
SELECT CONVERT(INT, FORMAT([Date], 'yyyyMMdd')), 2, Buses_Ridership, Buses_PrePandemicPct FROM Staging_MTA UNION ALL
SELECT CONVERT(INT, FORMAT([Date], 'yyyyMMdd')), 3, LIRR_Ridership, LIRR_PrePandemicPct FROM Staging_MTA UNION ALL
SELECT CONVERT(INT, FORMAT([Date], 'yyyyMMdd')), 4, MetroNorth_Ridership, MetroNorth_PrePandemicPct FROM Staging_MTA UNION ALL
SELECT CONVERT(INT, FORMAT([Date], 'yyyyMMdd')), 5, AccessARide_Trips, AccessARide_PrePandemicPct FROM Staging_MTA UNION ALL
SELECT CONVERT(INT, FORMAT([Date], 'yyyyMMdd')), 6, Bridges_and_Tunnels_Traffic, Bridges_and_Tunnels_PrePandemicPct FROM Staging_MTA UNION ALL
SELECT CONVERT(INT, FORMAT([Date], 'yyyyMMdd')), 7, Staten_Island_Railway_Ridership, Staten_Island_Railway_PrePandemicPct FROM Staging_MTA;
GO