-- ============================================================================
-- Script 01: Create Database and Schemas
-- Project: MTA Transit Ridership, Operations & 180-Day Forecast Data Warehouse
-- ============================================================================

CREATE DATABASE MTA_Transit_DW;
GO

USE MTA_Transit_DW;
GO

-- Staging schema for raw flat-file imports
CREATE SCHEMA stg;
GO

-- Data Warehouse schema for Star Schema Dimensions and Facts
CREATE SCHEMA dw;
GO