# 🗽 MTA Daily Ridership Analysis & Predictive Forecasting
> **DEPI Graduation Project | Data Analyst Track — Round 5 (Group 5)**

An end-to-end data engineering, predictive machine learning, and data warehousing pipeline analyzing New York City Metropolitan Transportation Authority (MTA) daily ridership data (2020–2024). The project encompasses data hygiene, temporal feature engineering, an enterprise Star Schema architecture built in Microsoft SQL Server, 30-day multi-agency Random Forest forecasting models, and executive business dashboards.

---

## 📌 Project Architecture & Workflow

```
Raw CSV Data (2020–2024) 
   │
   ├──▶ [Python / Google Colab] ──▶ Data Cleaning & Temporal Feature Engineering
   │                                   └──▶ Scikit-Learn Random Forest (30-Day Forecast)
   │
   ├──▶ [SQL Server (SSMS)] ──────▶ Staging Ingestion ──▶ Star Schema ETL
   │                                                       ├── Dim_Date (1,706 rows)
   │                                                       ├── Dim_Agency (7 rows)
   │                                                       └── Fact_DailyRidership (11,942 rows)
   │
   └──▶ [Business Intelligence] ──▶ SQL Analytics Queries & Power BI / Tableau Dashboards
```

---

## ✅ Project Milestones & Roadmap

- [x] **Phase 1: Data Preprocessing & Sanitization (Python)**
  - Cleaned and standardized 1,706 raw records across 15 original features into uniform `snake_case`.
  - Resolved missing values, handled nulls, parsed ISO date formats, and exported `MTA_Daily_Ridership_Cleaned.csv`.
- [x] **Phase 2: Temporal Feature Engineering & Predictive ML (Scikit-Learn)**
  - Engineered temporal dimensions: `Year`, `Month`, `MonthName`, `Day`, `DayOfWeek`, and binary `IsWeekend`.
  - Trained 7 independent `RandomForestRegressor` models (`n_estimators=100`, `random_state=42`) tailored to each transit agency.
  - Generated 30-day predictive ridership forecasts exported to `MTA_30Day_Forecast.csv`.
- [x] **Phase 3: Data Warehousing Architecture & ETL Pipeline (SQL Server)**
  - Designed an enterprise-grade Star Schema dimensional model (`MTA_DB`).
  - Executed T-SQL DDL scripts to construct `Dim_Date`, `Dim_Agency`, and `Fact_DailyRidership`.
  - Built T-SQL ETL transformations unpivoting 7 wide agency metrics into 11,942 normalized relational fact records.
- [ ] **Phase 4: Advanced SQL Business Analytics** *(In Progress)*
  - Querying system-wide recovery trends, weekend vs. weekday ridership distribution, and peak demand periods.
- [ ] **Phase 5: Executive BI Dashboarding (Power BI / Tableau)** *(Upcoming)*
  - Page 1: Historical Executive Summary & System Recovery Ratios (2020–2024).
  - Page 2: Agency & Sector Performance Analytics.
  - Page 3: 30-Day Machine Learning Predictive Forecast Overview.
- [ ] **Phase 6: Deliverables & Defense Strategy** *(Upcoming)*
  - Final Technical Project Documentation PDF and Presentation Defense Slides.

---

## 🗄️ Database Architecture (Star Schema)

The data warehouse decouples temporal dimensions from operational transit metrics to optimize OLAP query execution and facilitate scalable analytical aggregation:

![MTA Star Schema ERD](Docs/ERD%20Star%20Schema.png)

### Schema Summary
* **`Dim_Date`** (1,706 rows): Stores primary temporal key `DateKey` (YYYYMMDD), calendar components, day names, and weekend indicators.
* **`Dim_Agency`** (7 rows): Dimension lookup mapping unique agency identifiers to Subways, Buses, LIRR, Metro-North, Access-A-Ride, Bridges & Tunnels, and Staten Island Railway.
* **`Fact_DailyRidership`** (11,942 rows): Fact table containing foreign keys linking date and agency dimensions to daily volume counts and pre-pandemic percentage baselines.

---

## 🛠️ Tech Stack & Tools

* **Programming & Libraries:** Python 3.13, Pandas, NumPy, Scikit-Learn (`RandomForestRegressor`)
* **Database & Data Warehousing:** Microsoft SQL Server, T-SQL, SQL Server Management Studio (SSMS)
* **Modeling & ERD Design:** dbdiagram.io, Matplotlib, Seaborn
* **Business Intelligence & Dashboards:** Power BI / Tableau
* **Version Control:** Git, GitHub

---

## 📂 Repository Layout

```text
├── data/
│   ├── MTA_Daily_Ridership_Cleaned.csv     # Preprocessed, sanitized historical dataset
│   └── MTA_30Day_Forecast.csv              # Machine learning 30-day predicted outputs
├── notebooks/
│   └── Data_cleaning_and_forcasting.ipynb  # End-to-end Python cleaning and ML pipeline notebook
├── sql/
│   └── MTA_Star_Schema_ETL.sql             # Full DDL, staging, and ETL T-SQL script
├── docs/
│   └── MTA_Star_Schema_ERD.png             # Modern high-resolution Star Schema ERD diagram
├── dashboard/                              # Power BI / Tableau workbook files & visual assets
├── reports/                                # Technical documentation PDF and presentation slides
└── README.md                               # Project documentation
```

---

## 👥 Team Members (Group 5)

* **Amr Mohamed** — Data Engineering, ML Pipeline & SQL Architecture
* **Hamed Hobballah** — Business Intelligence Queries
* **Ahmed Tamer** _
* **Hadeer Mohamed** — 
* **Kiriakos Ayman** — Technical Documentation Lead & Presentation Design

---

## 🚀 Reproduction & Environment Setup

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/amr305/DEPI-Graduation-Project-R5-G5.git
   cd DEPI-Graduation-Project-R5-G5
   ```

2. **Execute Python Machine Learning Pipeline:**
   * Open `notebooks/Data_cleaning_and_forcasting.ipynb` in Google Colab or Jupyter Lab.
   * Run all cells to execute data cleaning, feature extraction, and model training.

3. **Deploy SQL Server Data Warehouse:**
   * Import `data/MTA_Daily_Ridership_Cleaned.csv` into SSMS as staging table `Staging_MTA`.
   * Open and execute `sql/MTA_Star_Schema_ETL.sql` to construct tables and populate the Star Schema.
