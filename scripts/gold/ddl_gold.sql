/*
===============================================================================
 Script Name : ddl_gold.sql
 Purpose     : Create Gold Views for the Data Warehouse
===============================================================================

Description:
------------
    This script creates views in the 'gold' schema in the data warehouse.
    The Gold layer represents the final dimension and fact tables (Star Schema).

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

    Run this script to re-define the DDL structure of 'gold' Views.

Usage:
    - These views can be quieried directly foro analytics and reporting.

===============================================================================
*/

DROP VIEW IF EXISTS gold.fact_sales;
DROP VIEW IF EXISTS gold.dim_customers;
DROP VIEW IF EXISTS gold.dim_products;

-- ============================================================================
-- Create Dimension: gold.dim_customers
-- ============================================================================

CREATE VIEW gold.dim_customers AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY cust_info.cst_id) AS customer_key -- surrogate key
        , cust_info.cst_id              AS customer_id
        , cust_info.cst_key             AS customer_number
        , cust_info.cst_firstname       AS first_name
        , cust_info.cst_lastname        AS last_name
        , cust_loc.cntry                AS country
        , CASE 
            WHEN cust_info.cst_gndr != 'n/a' 
                THEN cust_info.cst_gndr
            ELSE COALESCE(cust_bg.gen, 'n/a')
        END AS gender -- CRM table is our Master table
        , cust_info.cst_marital_status  AS marital_status
        , cust_bg.bdate                 AS birthdate
        , cust_info.cst_create_date     AS create_date
    FROM silver.crm_cust_info cust_info
    LEFT JOIN silver.erp_cust_az12 cust_bg
        ON cust_info.cst_key = cust_bg.cid
    LEFT JOIN silver.erp_loc_a101 cust_loc
        ON cust_info.cst_key = cust_loc.cid
);

-- ============================================================================
-- Create Dimension: gold.dim_products
-- ============================================================================

-- Only current data
CREATE VIEW gold.dim_products AS (
    WITH current_prd_info AS (
        SELECT
            prd_id
            , cat_id
            , prd_key
            , prd_nm
            , prd_cost
            , prd_line
            , prd_start_dt
            -- , prd_end_dt -- we don't need it (always null with our historical filter)
        FROM silver.crm_prd_info
        WHERE prd_end_dt IS NULL -- Filter out all historical data
    )
    SELECT
        ROW_NUMBER() OVER (ORDER BY current_prd_info.prd_start_dt, current_prd_info.prd_key) AS product_key
        , current_prd_info.prd_id       AS product_id
        , current_prd_info.prd_key      AS product_number
        , current_prd_info.prd_nm       AS product_name
        , current_prd_info.cat_id       AS category_id
        , prd_cat.cat                   AS category
        , prd_cat.subcat                AS subcategory
        , prd_cat.maintenance           AS maintenance
        , current_prd_info.prd_cost     AS cost
        , current_prd_info.prd_line     AS product_line
        , current_prd_info.prd_start_dt AS start_date
    FROM current_prd_info
    LEFT JOIN silver.erp_px_cat_g1v2 prd_cat
        ON current_prd_info.cat_id = prd_cat.id
);
-- ============================================================================
-- Create Fact Table: gold.fact_sales
-- ============================================================================

CREATE VIEW gold.fact_sales AS (
    SELECT
        sales.sls_ord_num AS order_number
        , prod.product_key
        , cust.customer_key
        -- , sales.sls_prd_key -- not useful, we use the surrogate key
        -- , sales.sls_cust_id -- not useful, we use the surrogate key
        , sales.sls_order_dt AS order_date
        , sales.sls_ship_dt AS shipping_date
        , sales.sls_due_dt AS due_date
        , sales.sls_sales AS sales_amount
        , sales.sls_quantity AS quantity
        , sales.sls_price AS price
    FROM silver.crm_sales_details AS sales
    LEFT JOIN gold.dim_customers cust
        ON sales.sls_cust_id = cust.customer_id
    LEFT JOIN gold.dim_products prod
        ON sales.sls_prd_key = prod.product_number
);