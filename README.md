## Setup

1. Download Docker Desktop (if you don’t have installed) using the official website, install and launch.
2. Fork this Github project to you Github account. Clone the forked repo to your device.
3. Open your Command Prompt or Terminal, navigate to that folder, and run the command `docker compose up`.
4. Now you have launched a local Postgres database with the following credentials:
 ```
    Host: localhost
    User: admin
    Password: admin
    Port: 5432
```
5. Connect to the db via a preferred tool (e.g. DataGrip, Dbeaver etc)
6. Install dbt-core and dbt-postgres using pip (if you don’t have) on your preferred environment.
7. Now you can run `dbt run` with the test model and check public_pipedrive_analytics schema to see the dbt result (with one test model)

## Project
1. Remove the test model once you make sure it works
2. Dive deep into the Pipedrive CRM source data to gain a thorough understanding of all its details. (You may also research the Pipedrive CRM tool terms).
3. Define DBT sources and build the necessary layers organizing the data flow for optimal relevance and maintainability.
4. Build a reporting model (rep_sales_funnel_monthly) with monthly intervals, incorporating the following funnel steps (KPIs):
  &nbsp;&nbsp;&nbsp;Step 1: Lead Generation
  &nbsp;&nbsp;&nbsp;Step 2: Qualified Lead
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Step 2.1: Sales Call 1
  &nbsp;&nbsp;&nbsp;Step 3: Needs Assessment
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Step 3.1: Sales Call 2
  &nbsp;&nbsp;&nbsp;Step 4: Proposal/Quote Preparation
  &nbsp;&nbsp;&nbsp;Step 5: Negotiation
  &nbsp;&nbsp;&nbsp;Step 6: Closing
  &nbsp;&nbsp;&nbsp;Step 7: Implementation/Onboarding
  &nbsp;&nbsp;&nbsp;Step 8: Follow-up/Customer Success
  &nbsp;&nbsp;&nbsp;Step 9: Renewal/Expansion
5. Column names of the reporting model: `month`, `kpi_name`, `funnel_step`, `deals_count`
6. “Git commit” all the changes and create a PR to your forked repo (not the original one). Send your repo link to us.


----------------------------------------------------------------

# My Implementation


## Table of Contents
- [Project Overview](#project-overview)
- [Data Exploration](#data-exploration)
- [Data Architecture](#data-architecture)
- [Key Design Decisions](#key-design-decisions)
- [How to Run](#how-to-run)
- [Scaling Considerations](#scaling-considerations)
- [Development Note](#development-note)


## Project Overview:

This project builds a dbt analytics layer on top of the Pipedrive CRM data exported to a Postgres database. The goal is to build data structures and layers into a maintainable and scalable dbt project that can be easily extended in the future.

The project follows Medallion architecture principles, organising data into four layers: staging (clean and rename), intermediate (transform with business logic), and marts (dimensional and fact tables for reporting), and reporting (aggregated for final reports).

All models include documentation and testing to ensure data quality and maintainability.

To answer the business question: "How many deals are in each stage of the sales funnel on a monthly basis?", a reporting model (rep_sales_funnel_monthly) is created. It combines data from the activity and deal stage history tables, and aggregates the number of deals at each funnel step for each month.

[back to Table of Contents](#table-of-contents)


## Data Exploration
Before modelling, I explored the source data to understand the data structure and quality, which is crucial for designing the data architecture and transformation logic.

I started by checking the number of records, column names, and data types for each table to get an overview of the data.
I focused on the key tables with historical data for our analysis, which are the activity table and deal_changes table.
I checked the distribution of activity types and change fields, looked for duplicated records and missing values,
and analyzed the stage changes for each deal. I also checked the overlap of deals between the two tables to understand if they are capturing different sets of deals or if there is a data quality issue.

Full exploration queries can be found in the `analysis/source_exploration.sql` file.

Key findings:
1. Activity - 11 duplicated `activity_id` records, which is a data quality issue. Handled in `staging/stg_activity.sql`.
2. Deal Changes
  - all deals have all 4 change fields, that means every deal has a lost_reason. It doesn't make sense in real-world scenarios.
  - There are 17 cases of backwards stage changes or re-entering the same stage, it is possible in real-world scenarios, I will keep all the records as it is.
3. Deal-Activity overlap - the majority of deals in the `activity` table have no matching record in `deal_changes`. It could be a data quality issue or it could be that the two tables are capturing different sets of deals. I will keep all the records as it is.

[back to Table of Contents](#table-of-contents)


## Data Architecture

This project follows Medallion architecture, a layered approach that organizes data into different layers from raw data to final reports. This approach was chosen to build a scalable and maintainable data pipeline for the Pipedrive CRM data. For a single data source and relatively straightforward transformations, the Medallion architecture is a good fit. A more complex architecture like Data Vault could be considered for future projects with multiple data sources.

```
raw source (Postgres)
       ↓
[Staging]       → clean, rename, cast — 1:1 with source tables
       ↓
[Intermediate]  → business transformations (stage history, activity place-holder for future enrichment)
       ↓
[Marts]         → dimensions (stages, users, activity types)
                  facts (deal stage history, activities)
       ↓
[Reporting]     → aggregated business deliverables (rep_sales_funnel_monthly)
```

| Layer | Materialisation | Purpose |
|---|---|---|
| Staging | View | No storage cost, always fresh |
| Intermediate | Table | Complex logic, reused by multiple marts |
| Marts | Table | Optimised for BI queries |
| Reporting | Table | Ready for direct consumption |

[back to Table of Contents](#table-of-contents)


## Key Design Decisions

1. Backwards stage changes and re-entering stages:
 - In the deal_changes table, there are 17 cases where the stage changed backwards or re-entered. This behaviour would ideally be clarified with business stakeholders, but based on common sales process patterns, it is expected for deals to move backwards between stages. Therefore, I decided to keep all the stage changes in the analysis to reflect the real-world scenarios. Alternatively, we could consider only the first time when the stage changes for each deal, but this would oversimplify the sales process and may not provide an accurate representation of the deal's journey through the sales funnel.
2. Duplicated records in activity table:
 - There are 11 duplicated records for the same `activity_id` in the activity table, which is a data quality issue. To address this, we could implement deduplication strategies in the staging layer or intermediate layer to keep only one record per `activity_id`. I decided to implement deduplication in the staging layer to ensure that we have a clean and accurate representation of the source data before any transformations which in intermediate layer are applied.
3. due_to (due_at) as a proxy for activity created month:
 - The activity table does not have a `created_at` timestamp. The only available date field is the due_to date which indicates when the activity is due. For the purpose of our analysis, I decided to use the due_to date as a proxy for the activity created month, with the acknowledged limitation that due date may not reflect actual creation or completion date. Furthurmore, the `is_done` flag is used to filter only completed activities in the
reporting layer to ensure we count meaningful funnel progress.
4. Filtering in the reporting layer:
 - All filtering of activity types (Sales Call 1, Sales Call 2) and completion status (`is_done = true`) is applied in `rep_sales_funnel_monthly`, not in the intermediate or fact layers. This ensures that `fct_activities` remains a generic, reusable table that can serve future KPIs requiring different activity types or statuses.

[back to Table of Contents](#table-of-contents)


## How to Run

### Prerequisites:
Please refer to the setup instructions provided at the top [SetUp](#setup) of this README for installing Docker, dbt, and connecting to the database.

### dbt Profile Setup:
Create a profiles.yml file at `~/.dbt/profiles.yml` with the following configuration:
```yaml
enpal_assessment_project:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      user: admin
      password: admin
      port: 5432
      dbname: postgres
      schema: public_pipedrive_analytics
      threads: 4
```
### Running the dbt Models:
Run all models and tests in one command:
```
dbt build
```

To run a specific layer only:
```
dbt build --select tag:staging
dbt build --select tag:intermediate
dbt build --select tag:fact
dbt build --select tag:report
```

To query the final report:
```sql
SELECT * FROM public_pipedrive_analytics.rep_sales_funnel_monthly;
```

### Exploring Documentation
```
dbt docs generate
dbt docs serve
```

[back to Table of Contents](#table-of-contents)


## Scaling Considerations

- **Incremental Loading:** As the volume of data increases, the models like fct_activities and int_deal_stage_history may take longer to run. The implementation of incremental loading strategies based on timestamps (`due_at` and `stage_started_at`) will be crucial to optimize the data pipeline and reduce processing times.
- **Data Quality Monitoring and Alerts:** dbt tests currently cover model-level quality checks. In production this could be extended with source freshness checks and custom data tests for anomaly detection and pipeline alerting.
- **Query Performance:** For larger datasets, adding indexes on frequently filtered columns like `deal_id`, `stage_started_at`, and `due_at` would significantly improve query performance.
- **Multiple Data Sources:** If additional CRM or ERP systems are integrated in the future, a Data Vault architecture would be worth reconsidering. The Hub/Link/Satellite pattern handles multi-source integration and full historisation more robustly than Medallion.

[back to Table of Contents](#table-of-contents)


## Development Note

This project was developed following modern analytics engineering practices, using available tools and resources to ensure the best possible outcome, including dbt documentation, Pipedrive CRM reference, and AI tools.

[back to Table of Contents](#table-of-contents)
