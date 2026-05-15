-- ============================================
-- 01_setup_axel.sql
-- Axel : Création DB, Warehouse, Stage, File Formats
-- ============================================
CREATE DATABASE IF NOT EXISTS linkedin;
USE DATABASE linkedin;
CREATE SCHEMA IF NOT EXISTS raw;
USE SCHEMA raw;
USE WAREHOUSE COMPUTE_WH;

-- Stage externe pointant vers le bucket S3 public
CREATE OR REPLACE STAGE linkedin_stage
  URL = 's3://snowflake-lab-bucket/';

-- Format de fichier CSV
CREATE OR REPLACE FILE FORMAT csv_format
  TYPE = CSV
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  SKIP_HEADER = 1
  NULL_IF = ('', 'NULL')
  EMPTY_FIELD_AS_NULL = TRUE;

-- Format de fichier JSON
CREATE OR REPLACE FILE FORMAT json_format
  TYPE = JSON
  STRIP_OUTER_ARRAY = TRUE;

-- Vérification des fichiers S3
LIST @linkedin.raw.linkedin_stage;
