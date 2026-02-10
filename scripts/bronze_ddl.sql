/*
===============================================================================
 Script Name : bronze_ddl.sql
 Purpose     : Initialize Bronze layer tables for the Data Warehouse
 Author      : <your_name>
===============================================================================

Description:
------------
This script initializes the **Bronze layer** of the Data Warehouse by creating
raw ingestion tables for CRM and ERP source systems.

The Bronze layer is designed to store **raw, untransformed data** as received
from source systems, serving as the first landing zone in the data pipeline.

Execution Context:
------------------
- Database : data_warehouse
- Schema  : bronze
- Layer   : Bronze (Raw data)

⚠️ WARNING – DATA LOSS RISK
--------------------------
This script uses `DROP TABLE IF EXISTS` before creating tables.
If executed on an environment where Bronze tables already contain data,
ALL EXISTING DATA WILL BE PERMANENTLY DELETED.

Before running this script:
- Ensure you are in the correct environment (dev / stg / prd)
- Backup existing data if required
- Confirm that table recreation is intentional

Technical Notes:
----------------
PostgreSQL does not support `CREATE OR REPLACE` for tables.
Therefore, tables are explicitly dropped and recreated to ensure
a clean and deterministic initialization of the Bronze layer.
===============================================================================
*/

--====== CRM ======--

DROP TABLE IF EXISTS bronze.crm_cust_info;
CREATE TABLE bronze.crm_cust_info (
    cst_id                  INT
    , cst_key               VARCHAR(50)
    , cst_firstname         VARCHAR(50)
    , cst_lastname          VARCHAR(50)
    , cst_marital_status    VARCHAR(50)
    , cst_gndr              VARCHAR(50)
    , cst_create_date       DATE
);

DROP TABLE IF EXISTS bronze.crm_prd_info; 
CREATE TABLE bronze.crm_prd_info (
    prd_id          INT
    , prd_key       VARCHAR(50)
    , prd_nm        VARCHAR(50)
    , prd_cost      INT
    , prd_line      VARCHAR(50)
    , prd_start_dt  DATE
    , prd_end_dt    DATE
);

DROP TABLE IF EXISTS bronze.crm_sales_details; 
CREATE TABLE bronze.crm_sales_details (
    sls_ord_num     VARCHAR(50)
    , sls_prd_key   VARCHAR(50)
    , sls_cust_id   INT
    , sls_order_dt  DATE
    , sls_ship_dt   DATE
    , sls_due_dt    DATE
    , sls_sales     INT
    , sls_quantity  INT
    , sls_price     INT
);

--====== ERP ======--

DROP TABLE IF EXISTS bronze.erp_cust_az12; 
CREATE TABLE bronze.erp_cust_az12 (
    cid     VARCHAR(50)
    , bdate DATE
    , gen   VARCHAR(50)
);

DROP TABLE IF EXISTS bronze.erp_loc_a101; 
CREATE TABLE bronze.erp_loc_a101 (
    cid     VARCHAR(50)
    , cntry VARCHAR(50)
);

DROP TABLE IF EXISTS bronze.erp_px_cat_g1v2; 
CREATE TABLE bronze.erp_px_cat_g1v2 (
    id              VARCHAR(50)
    , cat           VARCHAR(50)
    , subcat        VARCHAR(50)
    , maintenance   BOOLEAN
);