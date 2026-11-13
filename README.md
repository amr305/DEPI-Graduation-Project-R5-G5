# 🗽 NYC MTA Transit Ridership, Operations & 180-Day Predictive Forecasting
**DEPI Graduation Project | Data Analyst Track — Round 5 (Group 5)**

An end-to-end data engineering, time-series forecasting, and data warehousing pipeline analyzing New York City Metropolitan Transportation Authority (MTA) daily ridership, station infrastructure, operational financials, and incident logs (2020–2024). The project encompasses multi-source data sanitization, temporal and operational feature engineering, an enterprise **Galaxy (Constellation) Schema** built in Microsoft SQL Server, **180-day multi-agency Prophet forecasting models**, and executive business intelligence dashboards.

---

## 📌 Project Architecture & Workflow

```text
Raw Multi-Source CSV Data (2020–2024) 
   │
   ├──▶ [Python / Jupyter] ─────▶ Multi-Source Cleaning & Feature Engineering
   │                                 └──▶ Meta Prophet Time-Series Models (180-Day Forecast)
   │
   ├──▶ [SQL Server (SSMS)] ────▶ Staging Ingestion (stg) ──▶ Galaxy Schema ETL (dw)
   │                                                           ├── 5 Conformed Dimensions (Dim_Date, Dim_Agency, Dim_Location, Dim_Service_Details, Dim_Incident_Category)
   │                                                           └── 4 Fact Tables (Actuals: 450,384 | Financials: 47,768 | Incidents: 18,500 | Forecast: 1,260)
   │
   └──▶ [Business Intelligence] ─▶ Advanced T-SQL Analytical Queries & Power BI
```

---

## ✅ Project Milestones & Roadmap

- **Phase 1: Multi-Source Data Preprocessing & Sanitization (Python)**
  - Cleaned, standardized, and validated 5 core operational datasets into uniform `snake_case`: `MTA_Ridership_Cleaned.csv` (`450,384` records), `MTA_Financials_Cleaned.csv` (`47,768` records), `MTA_Incidents_Cleaned.csv` (`18,500` records), and `MTA_Stations_Cleaned.csv` (`30` station complexes).
  - Resolved missing values, standardized agency and station identifiers, parsed ISO date formats, and engineered binary operational flags (`Is_Zero_Ridership`, `Above_Pre_Pandemic`, `Is_Zero_Fare_Revenue`).
- **Phase 2: Time-Series Forecasting with Meta Prophet (Python)**
  - Built and trained 7 independent **Prophet** time-series models tailored to each MTA transit sector (`Subways`, `Buses`, `LIRR`, `Metro-North`, `Access-A-Ride`, `Bridges and Tunnels`, `Staten Island Railway`).
  - Captured multi-year seasonality and post-pandemic recovery trends to generate **180-day daily ridership projections** with 95% confidence intervals (`Lower` & `Upper` bounds), exported to `MTA_180Day_Forecast.csv`.
- **Phase 3: Enterprise Data Warehousing & Galaxy Schema ETL (SQL Server)**
  - Designed and deployed a multi-fact **Galaxy (Constellation) Schema** (`MTA_Transit_DW`) separating staging (`stg`) from analytics (`dw`).
  - Executed modular T-SQL DDL & ETL scripts (`01` through `04`) to populate **5 conformed dimensions** and **4 fact tables**, including unpivoting wide 180-day agency forecasts into `1,260` normalized relational records (`180 days × 7 agencies`).
- **Phase 4: Advanced SQL Business Analytics (Completed)**
  - Executed cross-agency T-SQL analytical queries evaluating YoY post-pandemic recovery, net operating balances, on-time performance percentages, incident repair costs, and monthly 180-day forecast summaries.
- **Phase 5: Executive BI Dashboarding (Power BI) (In Progress)**
  - **Page 1:** Historical Executive Summary & System Recovery Ratios (2020–2024).
  - **Page 2:** Operational Financials, On-Time Performance & Incident Impact Analytics.
  - **Page 3:** 180-Day Prophet Predictive Forecast & Confidence Interval Overview.
- **Phase 6: Deliverables & Defense Strategy (Upcoming)**
  - Final Technical Project Documentation PDF and Presentation Defense Slides.

---

## 🗄️ Database Architecture (Galaxy / Constellation Schema)

The data warehouse decouples 5 shared conformed dimensions from 4 core business process fact tables to optimize OLAP query execution and cross-domain analysis:

![MTA Transit Data Warehouse Galaxy Schema](Docs/Galaxy%20Schema_2.png)

### Schema Summary
- **Conformed Dimensions (5 Tables):**
  - `dw.Dim_Date` (`2,557 rows`): Continuous daily calendar (`2020-01-01` to `2026-12-31`) with smart primary key `DateKey` (`YYYYMMDD`), calendar attributes, and `IsWeekend` indicators.
  - `dw.Dim_Agency` (`7 rows`): Lookup mapping unique agency keys to `Subways`, `Buses`, `LIRR`, `Metro-North`, `Access-A-Ride`, `Bridges and Tunnels`, and `Staten Island Railway` with `ModeCategory` and `UnitOfMeasure`.
  - `dw.Dim_Location` (`32 rows`): Enriched station complex metadata including `Borough`, `StationComplex`, geographic coordinates (`Latitude`, `Longitude`), `LineCount`, and `ADAAccessible` flags.
  - `dw.Dim_Service_Details` (`16 rows`): Conformed operational shifts (`TimeShift`) and fare media (`PaymentType`).
  - `dw.Dim_Incident_Category` (`6 rows`): Standardized classification of service disruptions.
- **Fact Tables (4 Tables):**
  - `dw.Fact_Ridership_Actuals` (`450,384 rows`): Daily estimated ridership volumes and pre-pandemic recovery baselines across agencies, stations, shifts, and payment types.
  - `dw.Fact_Operations_Financials` (`47,768 rows`): Scheduled trips, seat capacity, gross fare revenue, operating expenses, delay minutes, and on-time performance percentages.
  - `dw.Fact_Incidents` (`18,500 rows`): Service disruption logs linking incident categories, delay impact minutes, and estimated repair costs.
  - `dw.Fact_Ridership_Forecast` (`1,260 rows`): Unpivoted 180-day Prophet ridership forecasts (`PredictedRidership`) with 95% uncertainty bounds (`LowerBound`, `UpperBound`).

---

## 🛠️ Tech Stack & Tools
- **Programming & Libraries:** Python 3.13, Pandas, NumPy, Meta Prophet
- **Database & Data Warehousing:** Microsoft SQL Server, T-SQL, SQL Server Management Studio (SSMS)
- **Modeling & ERD Design:** dbdiagram.io, Matplotlib, Seaborn
- **Business Intelligence & Dashboards:** Power BI
- **Version Control:** Git, GitHub

---

## 📂 Repository Layout

```text
├── data/
│   ├── MTA_Ridership_Cleaned.csv                   # Sanitized daily ridership dataset (450,384 rows)
│   ├── MTA_Financials_Cleaned.csv                  # Daily operational & financial metrics (47,768 rows)
│   ├── MTA_Incidents_Cleaned.csv                   # Service disruption & repair cost logs (18,500 rows)
│   ├── MTA_Stations_Cleaned.csv                    # Enriched station complex metadata (30 stations)
│   └── MTA_180Day_Forecast.csv                     # Prophet 180-day multi-agency forecast outputs
├── Notebooks/
│   └── ...                                         # End-to-end Python cleaning, EDA & Prophet forecasting notebook
├── SQL/
│   ├── 01_create_database_and_schemas.sql          # Creates MTA_Transit_DW, stg, and dw schemas
│   ├── 02_create_star_schema_tables.sql            # DDL for all 5 Dimensions and 4 Fact tables
│   ├── 03_etl_load_dimensions_and_facts.sql        # T-SQL ETL pipeline (surrogate lookups & unpivoting)
│   └── 04_verification_and_analytical_queries.sql  # Row-count audits & BI analytical queries
├── Docs/
│   └── Galaxy Schema_2.png                         # High-resolution Galaxy Schema ERD (dbdiagram.io)
└── README.md                                       # Project documentation
```

---

## 👥 Team Members (Group 5)
- **Amr Mohamed** — Data Engineering, Prophet Forecasting Pipeline & SQL Architecture


---

## 🚀 Reproduction & Environment Setup

1. **Clone the Repository:**
   ```bash
   git clone [https://github.com/amr305/DEPI-Graduation-Project-R5-G5.git](https://github.com/amr305/DEPI-Graduation-Project-R5-G5.git)
   cd DEPI-Graduation-Project-R5-G5
   ```
2. **Execute Python Forecasting Pipeline:**
   - Open the Jupyter Notebook inside `Notebooks/` in Google Colab or Jupyter Lab.
   - Run all cells to execute data sanitization, feature engineering, and 180-day Prophet model training.
3. **Deploy SQL Server Data Warehouse:**
   - Execute `SQL/01_create_database_and_schemas.sql` in SSMS to create `MTA_Transit_DW`.
   - Import the 5 CSV files from `data/` into the `stg` schema (`stg.MTA_Ridership_Cleaned`, `stg.MTA_Financials_Cleaned`, `stg.MTA_Incidents_Cleaned`, `stg.MTA_Stations_Cleaned`, and `stg.MTA_180Day_Forecast`).
   - Execute `SQL/02_create_star_schema_tables.sql` to build the Galaxy Schema tables.
   - Execute `SQL/03_etl_load_dimensions_and_facts.sql` to populate all dimensions and fact tables.
   - Execute `SQL/04_verification_and_analytical_queries.sql` to verify row reconciliation and run analytical queries.
