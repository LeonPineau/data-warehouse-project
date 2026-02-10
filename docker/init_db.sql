-- Create Bronze, Silver, Gold schemas
CREATE DATABASE data_warehouse WITH OWNER = postgres ENCODING = 'UTF-8';

\connect data_warehouse

CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

COMMENT ON SCHEMA bronze IS 'Raw data layer - no transformations';
COMMENT ON SCHEMA silver IS 'Silver data layer - cleaned data without changed data models';
COMMENT ON SCHEMA gold   IS 'Gold data layer - Business-ready aggregated data for data products';

-- I can add some ROLES and USERS