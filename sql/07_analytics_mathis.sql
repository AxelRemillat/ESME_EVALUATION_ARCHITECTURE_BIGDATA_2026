-- ============================================
-- 07_analytics_mathis.sql
-- Mathis : Analyses 3, 4 & 5
-- ============================================
USE DATABASE linkedin;
USE SCHEMA raw;
USE WAREHOUSE COMPUTE_WH;

-- Analyse 3 : Répartition des offres par taille d'entreprise
SELECT
  CASE c.company_size
    WHEN 0 THEN '0 - Auto-entrepreneur'
    WHEN 1 THEN '1 - 1-10 emp.'
    WHEN 2 THEN '2 - 11-50 emp.'
    WHEN 3 THEN '3 - 51-200 emp.'
    WHEN 4 THEN '4 - 201-500 emp.'
    WHEN 5 THEN '5 - 501-1000 emp.'
    WHEN 6 THEN '6 - 1001-5000 emp.'
    WHEN 7 THEN '7 - 5000+ emp.'
    ELSE 'Inconnue'
  END AS taille_entreprise,
  COUNT(*) AS nb_offres
FROM job_postings jp
JOIN companies c ON jp.company_name::NUMBER = c.company_id
GROUP BY c.company_size
ORDER BY c.company_size;

-- Analyse 4 : Répartition des offres par secteur d'activité
SELECT ci.industry, COUNT(jp.job_id) AS nb_offres
FROM job_postings jp
JOIN companies c ON jp.company_name::NUMBER = c.company_id
JOIN company_industries ci ON c.company_id = ci.company_id
GROUP BY ci.industry
ORDER BY nb_offres DESC
LIMIT 20;

-- Analyse 5 : Répartition des offres par type d'emploi
SELECT
  COALESCE(formatted_work_type, 'Non renseigné') AS type_emploi,
  COUNT(*) AS nb_offres,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pourcentage
FROM job_postings
WHERE formatted_work_type IS NOT NULL
GROUP BY formatted_work_type
ORDER BY nb_offres DESC;
