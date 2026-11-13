-- ============================================================================
-- Script 02: Create Constellation Star Schema Tables (Dimensions & Facts)
-- Prerequisite: Run 01_create_database_and_schemas.sql and import CSVs to stg
-- ============================================================================

USE MTA_Transit_DW;
GO

-- ============================================================================
-- 1. DIMENSION TABLES
-- ============================================================================

-- Date Dimension (Smart Key: YYYYMMDD)
CREATE TABLE dw.Dim_Date (
    DateKey INT PRIMARY KEY,
    FullDate DATE NOT NULL UNIQUE,
    [Year] INT NOT NULL,
    [Quarter] INT NOT NULL,
    [Month] INT NOT NULL,
    MonthName VARCHAR(15) NOT NULL,
    DayOfWeek INT NOT NULL,
    DayName VARCHAR(15) NOT NULL,
    IsWeekend BIT NOT NULL
);

-- Agency Dimension (7 MTA Transit & Vehicular Agencies)
CREATE TABLE dw.Dim_Agency (
    AgencyKey INT IDENTITY(1,1) PRIMARY KEY,
    AgencyName NVARCHAR(100) NOT NULL UNIQUE,
    ModeCategory VARCHAR(50) NOT NULL,
    UnitOfMeasure VARCHAR(30) NOT NULL
);

-- Location Dimension (Stations, Boroughs, Coordinates & Accessibility)
CREATE TABLE dw.Dim_Location (
    LocationKey INT IDENTITY(1,1) PRIMARY KEY,
    Borough NVARCHAR(100) NOT NULL,
    StationComplex NVARCHAR(255) NOT NULL,
    Latitude FLOAT NULL,
    Longitude FLOAT NULL,
    LineCount INT NULL,
    ADAAccessible BIT NULL,
    CONSTRAINT UQ_Location UNIQUE (Borough, StationComplex)
);

-- Service Details Dimension (Time Shift & Payment Type)
CREATE TABLE dw.Dim_Service_Details (
    ServiceDetailKey INT IDENTITY(1,1) PRIMARY KEY,
    TimeShift NVARCHAR(50) NOT NULL,
    PaymentType NVARCHAR(50) NOT NULL,
    CONSTRAINT UQ_ServiceDetails UNIQUE (TimeShift, PaymentType)
);

-- Incident Category Dimension
CREATE TABLE dw.Dim_Incident_Category (
    IncidentCategoryKey INT IDENTITY(1,1) PRIMARY KEY,
    IncidentCategory NVARCHAR(100) NOT NULL UNIQUE
);

-- ============================================================================
-- 2. FACT TABLES
-- ============================================================================

-- Fact 1: Daily Ridership Actuals
CREATE TABLE dw.Fact_Ridership_Actuals (
    RidershipFactID BIGINT IDENTITY(1,1) PRIMARY KEY,
    DateKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Date(DateKey),
    AgencyKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Agency(AgencyKey),
    LocationKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Location(LocationKey),
    ServiceDetailKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Service_Details(ServiceDetailKey),
    EstimatedRidership BIGINT NULL,
    PctPrePandemic FLOAT NULL,
    IsZeroRidership BIT NOT NULL DEFAULT 0,
    AbovePrePandemic BIT NOT NULL DEFAULT 0
);

-- Fact 2: Operations & Financials
CREATE TABLE dw.Fact_Operations_Financials (
    FinancialFactID BIGINT IDENTITY(1,1) PRIMARY KEY,
    DateKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Date(DateKey),
    AgencyKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Agency(AgencyKey),
    ServiceDetailKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Service_Details(ServiceDetailKey),
    ScheduledTrips INT NULL,
    TotalSeatCapacity INT NULL,
    GrossFareRevenueUSD FLOAT NULL,
    OperatingExpenseUSD FLOAT NULL,
    TotalDelayMinutes INT NULL,
    OnTimePerformancePct FLOAT NULL,
    IsZeroFareRevenue BIT NOT NULL DEFAULT 0
);

-- Fact 3: Incidents & Service Disruptions
CREATE TABLE dw.Fact_Incidents (
    IncidentFactID BIGINT IDENTITY(1,1) PRIMARY KEY,
    IncidentID NVARCHAR(50) NOT NULL,
    DateKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Date(DateKey),
    AgencyKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Agency(AgencyKey),
    LocationKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Location(LocationKey),
    ServiceDetailKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Service_Details(ServiceDetailKey),
    IncidentCategoryKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Incident_Category(IncidentCategoryKey),
    DelayImpactMinutes INT NULL,
    EstimatedRepairCostUSD FLOAT NULL
);

-- Fact 4: 180-Day Prophet Ridership Forecast
CREATE TABLE dw.Fact_Ridership_Forecast (
    ForecastFactID BIGINT IDENTITY(1,1) PRIMARY KEY,
    DateKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Date(DateKey),
    AgencyKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Agency(AgencyKey),
    PredictedRidership FLOAT NOT NULL,
    LowerBound FLOAT NULL,
    UpperBound FLOAT NULL
);
GO