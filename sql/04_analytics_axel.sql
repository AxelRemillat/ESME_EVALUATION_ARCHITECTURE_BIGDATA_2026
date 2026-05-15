-- ============================================
-- 04_analytics_axel.sql
-- Axel : Analyses 1 & 2
-- ============================================
USE DATABASE linkedin;
USE SCHEMA raw;
USE WAREHOUSE COMPUTE_WH;

-- Analyse 1 : Top 10 titres de postes les plus publiés par industrie
WITH ranked AS (
  SELECT
    ji.industry_id,
    jp.title,
    COUNT(*) AS nb_offres,
    ROW_NUMBER() OVER (PARTITION BY ji.industry_id ORDER BY COUNT(*) DESC) AS rang
  FROM job_postings jp
  JOIN job_industries ji ON jp.job_id = ji.job_id
  GROUP BY ji.industry_id, jp.title
)
SELECT industry_id, title, nb_offres, rang
FROM ranked
WHERE rang <= 10
ORDER BY industry_id, rang;

-- Analyse 2 : Top 10 postes les mieux rémunérés par industrie
WITH ranked_salary AS (
  SELECT
    ji.industry_id,
    jp.title,
    ROUND(AVG(jp.med_salary), 2) AS salaire_moyen,
    ROW_NUMBER() OVER (PARTITION BY ji.industry_id ORDER BY AVG(jp.med_salary) DESC) AS rang
  FROM job_postings jp
  JOIN job_industries ji ON jp.job_id = ji.job_id
  WHERE jp.med_salary IS NOT NULL
  GROUP BY ji.industry_id, jp.title
)
SELECT industry_id, title, salaire_moyen, rang
FROM ranked_salary
WHERE rang <= 10
ORDER BY industry_id, rang;
