-- ============================================
-- 06_load_data_mathis.sql
-- Mathis : COPY INTO tables CSV
-- ============================================
USE DATABASE linkedin;
USE SCHEMA raw;
USE WAREHOUSE COMPUTE_WH;

COPY INTO job_postings
FROM @linkedin_stage/job_postings.csv
FILE_FORMAT = (FORMAT_NAME = 'csv_format');

COPY INTO benefits
FROM @linkedin_stage/benefits.csv
FILE_FORMAT = (FORMAT_NAME = 'csv_format');

COPY INTO employee_counts
FROM @linkedin_stage/employee_counts.csv
FILE_FORMAT = (FORMAT_NAME = 'csv_format');

COPY INTO job_skills
FROM @linkedin_stage/job_skills.csv
FILE_FORMAT = (FORMAT_NAME = 'csv_format');

-- Vérification
SELECT 'job_postings' as table_name, COUNT(*) as nb_lignes FROM job_postings
UNION ALL
SELECT 'benefits', COUNT(*) FROM benefits
UNION ALL
SELECT 'employee_counts', COUNT(*) FROM employee_counts
UNION ALL
SELECT 'job_skills', COUNT(*) FROM job_skills;
