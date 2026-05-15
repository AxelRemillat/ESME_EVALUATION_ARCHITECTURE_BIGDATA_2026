-- ============================================
-- 03_load_data_axel.sql
-- Axel : COPY INTO tables JSON
-- ============================================
USE DATABASE linkedin;
USE SCHEMA raw;
USE WAREHOUSE COMPUTE_WH;

-- Chargement companies
COPY INTO companies
FROM (
  SELECT
    $1:company_id::NUMBER,
    $1:name::VARCHAR,
    $1:description::VARCHAR,
    $1:company_size::NUMBER,
    $1:state::VARCHAR,
    $1:country::VARCHAR,
    $1:city::VARCHAR,
    $1:zip_code::VARCHAR,
    $1:address::VARCHAR,
    $1:url::VARCHAR
  FROM @linkedin_stage/companies.json
)
FILE_FORMAT = (FORMAT_NAME = 'json_format');

-- Chargement company_industries
COPY INTO company_industries
FROM (
  SELECT
    $1:company_id::NUMBER,
    $1:industry::VARCHAR
  FROM @linkedin_stage/company_industries.json
)
FILE_FORMAT = (FORMAT_NAME = 'json_format');

-- Chargement company_specialities
COPY INTO company_specialities
FROM (
  SELECT
    $1:company_id::NUMBER,
    $1:speciality::VARCHAR
  FROM @linkedin_stage/company_specialities.json
)
FILE_FORMAT = (FORMAT_NAME = 'json_format');

-- Chargement job_industries
COPY INTO job_industries
FROM (
  SELECT
    $1:job_id::NUMBER,
    $1:industry_id::NUMBER
  FROM @linkedin_stage/job_industries.json
)
FILE_FORMAT = (FORMAT_NAME = 'json_format');

-- Vérification
SELECT 'companies' as table_name, COUNT(*) as nb_lignes FROM companies
UNION ALL
SELECT 'company_industries', COUNT(*) FROM company_industries
UNION ALL
SELECT 'company_specialities', COUNT(*) FROM company_specialities
UNION ALL
SELECT 'job_industries', COUNT(*) FROM job_industries;
