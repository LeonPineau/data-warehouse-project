/*
===============================================================================
 Script Name : proc_load_bronze.sql
 Purpose     : Load Bronze Layer (Source -> Bronze)
===============================================================================

Description:
------------
    This stored procedure loads data into the 'bronze' schema from external CSV files.
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `COPY FROM` command to load data from csv files to bronze tables.

Parameters:
-----------
    None.

Usage Exemple:
--------------
    CALL bronze.load_bronze();

===============================================================================
*/

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time timestamptz;
    end_time timestamptz;
    duration_time numeric;
    batch_start_time timestamptz;
    batch_end_time timestamptz;
BEGIN
    batch_start_time := clock_timestamp();
    RAISE NOTICE '====================================================';
    RAISE NOTICE '                 Loading Bronze Layer';
    RAISE NOTICE '====================================================';

    RAISE NOTICE '----------------------------------------------------';
    RAISE NOTICE '                 Loading CRM tables';
    RAISE NOTICE '----------------------------------------------------';

    -- Load bronze.crm_cust_info
    start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: bronze.crm_cust_info';
    TRUNCATE TABLE bronze.crm_cust_info;

    RAISE NOTICE '>> Inserting Data Into: bronze.crm_cust_info';
    COPY bronze.crm_cust_info
    FROM '/datasets/source_crm/cust_info.csv'
    WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER ','
    );
    end_time := clock_timestamp();
    duration_time := EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '>> Load Duration: % ms', duration_time * 1000;
    RAISE NOTICE '----------------------------------------------------';

    -- Load bronze.crm_cust_info
    RAISE NOTICE '>> Truncating Table: bronze.crm_prd_info';
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.crm_prd_info;

    RAISE NOTICE '>> Inserting Data Into: bronze.crm_prd_info';
    COPY bronze.crm_prd_info
    FROM '/datasets/source_crm/prd_info.csv'
    WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER ','
    );
    end_time := clock_timestamp();
    duration_time := EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '>> Load Duration: % ms', duration_time * 1000;
    RAISE NOTICE '----------------------------------------------------';

    -- Load bronze.crm_sales_details
    RAISE NOTICE '>> Truncating Table: bronze.crm_sales_details';
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.crm_sales_details;

    RAISE NOTICE '>> Inserting Data Into: bronze.crm_sales_details';
    COPY bronze.crm_sales_details
    FROM '/datasets/source_crm/sales_details.csv'
    WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER ','
    );
    end_time := clock_timestamp(); 
    duration_time := EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '>> Load Duration: % ms', duration_time * 1000;

    RAISE NOTICE '----------------------------------------------------';
    RAISE NOTICE '                 Loading ERP tables';
    RAISE NOTICE '----------------------------------------------------';

    -- Load bronze.erp_cust_az12
    RAISE NOTICE '>> Truncating Table: bronze.erp_cust_az12';
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.erp_cust_az12;

    RAISE NOTICE '>> Inserting Data Into: bronze.erp_cust_az12';
    COPY bronze.erp_cust_az12
    FROM '/datasets/source_erp/CUST_AZ12.csv'
    WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER ','
    );
    end_time := clock_timestamp();
    duration_time := EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '>> Load Duration: % ms', duration_time * 1000;
    RAISE NOTICE '----------------------------------------------------';

    -- Load bronze.erp_loc_A101
    RAISE NOTICE '>> Truncating Table: bronze.erp_loc_a101';
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.erp_loc_a101;

    RAISE NOTICE '>> Inserting Data Into: bronze.erp_loc_a101';
    COPY bronze.erp_loc_a101
    FROM '/datasets/source_erp/LOC_A101.csv'
    WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER ','
    );
    end_time := clock_timestamp();
    duration_time := EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '>> Load Duration: % ms', duration_time * 1000;
    RAISE NOTICE '----------------------------------------------------';

    -- Load bronze.erp_px_cat_g1v2
    RAISE NOTICE '>> Truncating Table: bronze.erp_px_cat_g1v2';
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;

    RAISE NOTICE '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
    COPY bronze.erp_px_cat_g1v2
    FROM '/datasets/source_erp/PX_CAT_G1V2.csv'
    WITH (
        FORMAT csv,
        HEADER true,
        DELIMITER ','
    );
    end_time := clock_timestamp();
    duration_time := EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '>> Load Duration: % ms', duration_time * 1000;
    RAISE NOTICE '----------------------------------------------------';

    batch_end_time := clock_timestamp();
    duration_time := EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));
    RAISE NOTICE '>> Total batch duration: % ms', duration_time * 1000;

EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Erreur detectee : %', SQLERRM;

END;
$$;