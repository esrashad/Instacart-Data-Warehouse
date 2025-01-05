# Instacart-Data-Warehouse
This project implements an ETL pipeline for building and maintaining a data warehouse to analyze Instacart grocery order data. Using Apache Airflow for orchestration and Docker for containerization, the pipeline ingests, transforms, and loads data into SQL Server, creating dimension and fact tables for analytics.

### Solution Architecture Overview
![image](https://github.com/user-attachments/assets/1104ed11-a773-47f1-b38f-81c031043cf1)

## Project Overview
The goal of this project is to transform raw CSV files into a well-structured data warehouse that supports analysis and reporting. The pipeline extracts data from raw files, transforms it to ensure consistency and quality, and loads it into dimension and fact tables in SQL Server.

#### Features
- SCD Type 2: Maintains historical data in dimension tables by tracking changes to attributes over time.
- Batch Processing: Data is processed in batches for efficient loading into SQL Server.
- Data Integrity: Ensures no duplicate records and consistent foreign key mapping.
- Dynamic Foreign Key Mapping: Resolves relationships between dimensions and facts.

#### Pipeline Workflow
1) Dimensional Tables: Process and load data into dimension tables (dim_date, dim_department, dim_aisle, dim_products, dim_user, dim_orders, dim_order_products).
2) Fact Table: Aggregate data into the fact_instacart table for analysis.
3) Dependencies: Tasks are orchestrated to respect dependencies between tables.
![Screenshot 2025-01-02 150832](https://github.com/user-attachments/assets/0c8213c2-9a07-4c34-82bb-0c28bfb14831)

#### Input Data
**`Instacart ETL/instacart-market-basket-analysis`**
- Departments: departments.csv
- Aisles: aisles.csv
- Products: products.csv
- Orders: orders.csv
- Order Products: order_products.csv

#### Output Data
- Dimensional Tables:
  - dim_date
  - dim_department
  - dim_aisle
  - dim_products
  - dim_user
  - dim_orders
  - dim_order_products
- Fact Table: fact_instacart

### Analysis and Visualization
Power BI dashboards were created to analyze the processed data.
![1](https://github.com/user-attachments/assets/480f1293-43da-44c3-8c96-c4819c54b0f7)
![2](https://github.com/user-attachments/assets/9611a89b-3325-43e2-aac2-7da8b9dd9efe)

### Technologies Used
- Apache Airflow: Orchestrates the ETL process.
- SQL Server: Stores the processed data.
- Pandas: Handles data transformations.
- Power BI: Visualizes insights from the data warehouse.
- Docker: Manages the Airflow environment.

### SCD Type 2 Implementation
- This project uses SCD Type 2 to track changes in dimension tables. For example:
If a product's name changes, the previous record is marked as inactive (is_current = 0), and a new record is added with updated details.
- Each record maintains valid_from and valid_to timestamps to indicate its validity period.

#### How to Run
- Set up the environment using Docker.
- Trigger the DAG named instacart_etl in the Airflow UI.
- View the processed data in SQL Server and analyze it using Power BI dashboards.





