/*
===============================================================================
 Script Name : proc_load_silver.sql
 Purpose     : Load Silver Layer (Bronze -> Silver)
===============================================================================

Description:
------------
    This stored procedure performs the ETL (Extract, Transform, Load) process to
    populate the 'silver' schema tables from the 'bronze' schema.
    Actions Performed:
        - Truncates Silver tables.
        - Inserts transformed and cleaned data from Bronze into Silver tables.

Parameters:
-----------
    None.

Usage Exemple:
--------------
    CALL silver.load_silver();

===============================================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time TIMESTAMPTZ;
    end_time TIMESTAMPTZ;
    duration_time NUMERIC;
    batch_start_time TIMESTAMPTZ;
    batch_end_time TIMESTAMPTZ;
BEGIN
    batch_start_time := clock_timestamp();
    RAISE NOTICE '====================================================';
    RAISE NOTICE '                 Loading Silver Layer';
    RAISE NOTICE '====================================================';

    RAISE NOTICE '----------------------------------------------------';
    RAISE NOTICE '                 Loading CRM tables';
    RAISE NOTICE '----------------------------------------------------';

    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: silver.crm_cust_info'; 
    TRUNCATE TABLE silver.crm_cust_info;
    RAISE NOTICE '>> Inserting Data Into: silver.crm_cust_info';
    INSERT INTO silver.crm_cust_info (
        cst_id
        , cst_key
        , cst_firstname
        , cst_lastname
        , cst_marital_status
        , cst_gndr
        , cst_create_date
    )
    SELECT
        cst_id
        , cst_key
        , TRIM(cst_firstname) as cst_firstname
        , TRIM(cst_lastname) as cst_lastname
        , CASE cst_marital_status
            WHEN 'S' THEN 'Single'
            WHEN 'M' THEN 'Married'
            ELSE 'n/a'
          END as cst_marital_status
        , CASE UPPER(TRIM(cst_gndr))
            WHEN 'M' THEN 'Male'
            WHEN 'F' THEN 'Female'
            ELSE 'n/a'
          END as cst_gndr
        , cst_create_date
    FROM (
        SELECT
            *
            , ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as rn
        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL
    ) t
    WHERE rn = 1;
    
    end_time := clock_timestamp();
    duration_time := EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '>> Load Duration: % ms', duration_time * 1000;
    RAISE NOTICE '----------------------------------------------------';

    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: silver.crm_prd_info'; 
    TRUNCATE TABLE silver.crm_prd_info;
    RAISE NOTICE '>> Inserting Data Into: silver.crm_prd_info';
    INSERT INTO silver.crm_prd_info (
        prd_id
        , prd_key
        , cat_id
        , prd_nm
        , prd_cost
        , prd_line
        , prd_start_dt
        , prd_end_dt
    )
    SELECT
        prd_id
        , SUBSTRING(prd_key, 7, LENGTH(prd_key)) AS prd_key
        , CASE
            WHEN REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') = 'CO_PE' THEN 'CO_PD'
            ELSE REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_')
        END AS cat_id
        , prd_nm
        , COALESCE(prd_cost, 0) AS prd_cost
        , CASE TRIM(prd_line) 
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'T' THEN 'Touring'
            WHEN 'S' THEN 'Other Sales'
            ELSE 'n/a'
        END AS prd_line
        , prd_start_dt
        , LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS prd_end_dt
    FROM bronze.crm_prd_info
    WHERE prd_id IS NOT NULL;

    end_time := clock_timestamp();
    duration_time := EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '>> Load Duration: % ms', duration_time * 1000;
    RAISE NOTICE '----------------------------------------------------';

    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: silver.crm_sales_details'; 
    TRUNCATE TABLE silver.crm_sales_details;
    RAISE NOTICE '>> Inserting Data Into: silver.crm_sales_details';
    INSERT INTO silver.crm_sales_details (
        sls_ord_num
        , sls_prd_key
        , sls_cust_id
        , sls_order_dt
        , sls_ship_dt
        , sls_due_dt
        , sls_sales
        , sls_quantity
        , sls_price
    )
    SELECT
        sls_ord_num
        , sls_prd_key
        , sls_cust_id
        , NULLIF(sls_order_dt, DATE('1970-01-01')) AS sls_order_dt
        , sls_ship_dt
        , sls_due_dt
        , CASE
            WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != ABS(sls_price) * sls_quantity
                THEN ABS(sls_price) * sls_quantity
            ELSE sls_sales
        END AS sls_sales
        , sls_quantity
        , CASE
            WHEN sls_price IS NULL OR sls_price = 0
                THEN ABS(sls_sales)/NULLIF(sls_quantity, 0)
            WHEN sls_price < 0
                THEN ABS(sls_price)
            ELSE sls_price
        END AS sls_price
    FROM bronze.crm_sales_details;

    end_time := clock_timestamp();
    duration_time := EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '>> Load Duration: % ms', duration_time * 1000;

    RAISE NOTICE '----------------------------------------------------';
    RAISE NOTICE '                 Loading ERP tables';
    RAISE NOTICE '----------------------------------------------------';

    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: silver.erp_cust_az12'; 
    TRUNCATE TABLE silver.erp_cust_az12;
    RAISE NOTICE '>> Inserting Data Into: silver.erp_cust_az12';
    INSERT INTO silver.erp_cust_az12 (
        cid
        , bdate
        , gen
    )
    SELECT
        CASE 
            WHEN SUBSTRING(cid, 1,3) = 'NAS' THEN SUBSTRING(cid, 4, LENGTH(cid))
            ELSE cid
        END AS cid
        , CASE
            WHEN bdate > NOW() THEN NULL
            ELSE bdate
        END AS bdate
        , CASE 
            WHEN UPPER(TRIM(gen))='M' THEN 'Male'
            WHEN UPPER(TRIM(gen))='F' THEN 'Female'
            WHEN TRIM(gen)=''  THEN 'n/a'
            WHEN gen IS NULL THEN 'n/a'
            ELSE gen
        END AS gen
    FROM bronze.erp_cust_az12;
    end_time := clock_timestamp();
    duration_time := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Load Duration: % ms', duration_time * 1000;
    RAISE NOTICE '----------------------------------------------------';

    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: silver.erp_loc_a101'; 
    TRUNCATE TABLE silver.erp_loc_a101;
    RAISE NOTICE '>> Inserting Data Into: silver.erp_loc_a101';
    INSERT INTO silver.erp_loc_a101 (
        cid
        , cntry
    )
    SELECT
        REPLACE(cid,'-','') AS cid
        , CASE
            WHEN TRIM(cntry) = '' THEN 'n/a'
            WHEN TRIM(cntry) = 'DE' THEN 'Germany'
            WHEN TRIM(cntry) = 'US' THEN 'United State'
            WHEN TRIM(cntry) = 'USA' THEN 'United State'
            WHEN cntry IS NULL THEN 'n/a'
            ELSE cntry
        END as cntry
    FROM bronze.erp_loc_a101;
    end_time := clock_timestamp();
    duration_time := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Load Duration: % ms', duration_time * 1000;
    RAISE NOTICE '----------------------------------------------------';

    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: silver.erp_px_cat_g1v2'; 
    TRUNCATE TABLE silver.erp_px_cat_g1v2;
    RAISE NOTICE '>> Inserting Data Into: silver.erp_px_cat_g1v2';
    INSERT INTO silver.erp_px_cat_g1v2 (
        id
        , cat
        , subcat
        , maintenance
    )
    SELECT
        id
        , cat
        , subcat
        , maintenance
    FROM bronze.erp_px_cat_g1v2;
    end_time := clock_timestamp();
    duration_time := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Load Duration: % ms', duration_time * 1000;

    batch_end_time := clock_timestamp();
    duration_time := EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));
    RAISE NOTICE '====================================================';
    RAISE NOTICE '>> Loading Silver Layer is Completed';
    RAISE NOTICE '>> Total Load Duration: % ms', duration_time * 1000;
    RAISE NOTICE '====================================================';

EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Error detected : %', SQLERRM;

END;
$$;