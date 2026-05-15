-- ============================================
-- 05_create_tables_mathis.sql
-- Mathis : Tables CSV
-- ============================================
USE DATABASE linkedin;
USE SCHEMA raw;
USE WAREHOUSE COMPUTE_WH;

-- Table job_postings
CREATE OR REPLACE TABLE job_postings (
  job_id NUMBER,
  company_name VARCHAR,
  title VARCHAR,
  description TEXT,
  max_salary FLOAT,
  med_salary FLOAT,
  min_salary FLOAT,
  pay_period VARCHAR,
  formatted_work_type VARCHAR,
  location VARCHAR,
  applies NUMBER,
  original_listed_time NUMBER,
  remote_allowed VARCHAR,
  views NUMBER,
  job_posting_url VARCHAR,
  application_url VARCHAR,
  application_type VARCHAR,
  expiry NUMBER,
  closed_time NUMBER,
  formatted_experience_level VARCHAR,
  skills_desc TEXT,
  listed_time NUMBER,
  posting_domain VARCHAR,
  sponsored VARCHAR,
  work_type VARCHAR,
  currency VARCHAR,
  compensation_type VARCHAR
);

-- Table benefits
CREATE OR REPLACE TABLE benefits (
  job_id NUMBER,
  inferred VARCHAR,
  type VARCHAR
);

-- Table employee_counts
CREATE OR REPLACE TABLE employee_counts (
  company_id NUMBER,
  employee_count NUMBER,
  follower_count NUMBER,
  time_recorded NUMBER
);

-- Table job_skills
CREATE OR REPLACE TABLE job_skills (
  job_id NUMBER,
  skill_abr VARCHAR
);
