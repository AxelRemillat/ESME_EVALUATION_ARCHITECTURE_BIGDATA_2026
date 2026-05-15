-- ============================================
-- 02_create_tables_axel.sql
-- Axel : Création user Mathis + Tables JSON
-- ============================================
USE ROLE ACCOUNTADMIN;

-- Création du user Mathis
CREATE USER IF NOT EXISTS mathis
  PASSWORD = 'Esme2026!'
  DEFAULT_ROLE = ACCOUNTADMIN
  DEFAULT_WAREHOUSE = COMPUTE_WH
  DEFAULT_NAMESPACE = 'linkedin.raw'
  MUST_CHANGE_PASSWORD = FALSE;

GRANT ROLE ACCOUNTADMIN TO USER mathis;

USE DATABASE linkedin;
USE SCHEMA raw;
USE WAREHOUSE COMPUTE_WH;

-- Table companies
CREATE OR REPLACE TABLE companies (
  company_id NUMBER,
  name VARCHAR,
  description TEXT,
  company_size NUMBER,
  state VARCHAR,
  country VARCHAR,
  city VARCHAR,
  zip_code VARCHAR,
  address VARCHAR,
  url VARCHAR
);

-- Table company_industries
CREATE OR REPLACE TABLE company_industries (
  company_id NUMBER,
  industry VARCHAR
);

-- Table company_specialities
CREATE OR REPLACE TABLE company_specialities (
  company_id NUMBER,
  speciality VARCHAR
);

-- Table job_industries
CREATE OR REPLACE TABLE job_industries (
  job_id NUMBER,
  industry_id NUMBER
);
