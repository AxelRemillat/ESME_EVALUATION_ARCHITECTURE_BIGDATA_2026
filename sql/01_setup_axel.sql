-- Configuration initiale de l'environnement BigData pour Axel : création du schéma, des rôles et des paramètres de session
CREATE DATABASE IF NOT EXISTS linkedin;
USE DATABASE linkedin;
CREATE SCHEMA IF NOT EXISTS raw;
USE SCHEMA raw;
USE WAREHOUSE COMPUTE_WH;
CREATE OR REPLACE STAGE linkedin_stage URL = 's3://snowflake-lab-bucket/';
CREATE OR REPLACE FILE FORMAT csv_format TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1 NULL_IF = ('', 'NULL') EMPTY_FIELD_AS_NULL = TRUE;
CREATE OR REPLACE FILE FORMAT json_format TYPE = JSON STRIP_OUTER_ARRAY = TRUE;
LIST @linkedin.raw.linkedin_stage;
