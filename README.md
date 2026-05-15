# Analyse des Offres d'Emploi LinkedIn avec Snowflake

## Introduction

Ce projet a été réalisé dans le cadre de l'évaluation d'Architecture Big Data à l'ESME Paris (2026). Il consiste à ingérer, stocker et analyser un jeu de données d'offres d'emploi LinkedIn en utilisant **Snowflake** comme entrepôt de données cloud et **Streamlit** pour la visualisation interactive.

Les données comprennent des fichiers au format **CSV** et **JSON**, chargées depuis un stage S3. L'objectif est de produire des analyses pertinentes sur le marché de l'emploi : titres les plus demandés, salaires par industrie, répartition par taille d'entreprise et type de contrat.

---

## Répartition des tâches

| Tâche | Axel Remillat | Mathis Levrot |
|---|---|---|
| Setup Snowflake (BDD, schéma, stage, formats) | ✅ | |
| Création des tables CSV | | ✅ |
| Création des tables JSON | ✅ | |
| Chargement des données CSV | | ✅ |
| Chargement des données JSON | ✅ | |
| Analyse 1 – Top 10 titres par industrie | ✅ | |
| Analyse 2 – Top 10 salaires par industrie | ✅ | |
| Analyse 3 – Répartition par taille d'entreprise | | ✅ |
| Analyse 4 – Répartition par secteur | | ✅ |
| Analyse 5 – Répartition par type d'emploi | | ✅ |
| Application Streamlit | ✅ | ✅ |

---

## Étape 1 - Setup Snowflake

```sql
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH
  WAREHOUSE_SIZE = 'X-SMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;

USE WAREHOUSE COMPUTE_WH;
CREATE DATABASE IF NOT EXISTS linkedin;
USE DATABASE linkedin;
CREATE SCHEMA IF NOT EXISTS raw;
USE SCHEMA raw;

CREATE OR REPLACE STAGE linkedin_stage
  URL = 's3://snowflake-lab-bucket/';

CREATE OR REPLACE FILE FORMAT fmt_csv
  TYPE = 'CSV'
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  SKIP_HEADER = 1
  NULL_IF = ('NULL', 'null', '')
  EMPTY_FIELD_AS_NULL = TRUE;

CREATE OR REPLACE FILE FORMAT fmt_json
  TYPE = 'JSON'
  STRIP_OUTER_ARRAY = TRUE;
```

![Setup](screenshots/01_list_stage.png)

> Le stage externe `linkedin_stage` pointe vers le bucket S3 public `s3://snowflake-lab-bucket/`. La commande LIST permet de vérifier que les 8 fichiers sources sont bien accessibles. Les formats `fmt_csv` et `fmt_json` ont été créés pour définir les règles de parsing. Cette étape est le fondement de toute la pipeline de données.

---

## Étape 2 - Création des tables CSV - Mathis

```sql
USE DATABASE linkedin;
USE SCHEMA raw;
USE WAREHOUSE COMPUTE_WH;

CREATE OR REPLACE TABLE job_postings (
  job_id                     NUMBER,
  company_name               VARCHAR,
  title                      VARCHAR,
  description                TEXT,
  max_salary                 FLOAT,
  med_salary                 FLOAT,
  min_salary                 FLOAT,
  pay_period                 VARCHAR,
  formatted_work_type        VARCHAR,
  location                   VARCHAR,
  applies                    NUMBER,
  original_listed_time       NUMBER,
  remote_allowed             VARCHAR,
  views                      NUMBER,
  job_posting_url            VARCHAR,
  application_url            VARCHAR,
  application_type           VARCHAR,
  expiry                     NUMBER,
  closed_time                NUMBER,
  formatted_experience_level VARCHAR,
  skills_desc                TEXT,
  listed_time                NUMBER,
  posting_domain             VARCHAR,
  sponsored                  VARCHAR,
  work_type                  VARCHAR,
  currency                   VARCHAR,
  compensation_type          VARCHAR
);

CREATE OR REPLACE TABLE benefits (
  job_id   NUMBER,
  inferred VARCHAR,
  type     VARCHAR
);

CREATE OR REPLACE TABLE employee_counts (
  company_id     NUMBER,
  employee_count NUMBER,
  follower_count NUMBER,
  time_recorded  NUMBER
);

CREATE OR REPLACE TABLE job_skills (
  job_id    NUMBER,
  skill_abr VARCHAR
);
```

![Tables CSV](screenshots/02_tables_csv.png)

> Les 4 tables CSV ont été créées avec succès : `job_postings`, `benefits`, `employee_counts` et `job_skills`. Chaque colonne a été typée précisément selon la nature des données (NUMBER pour les IDs, FLOAT pour les salaires, VARCHAR pour les textes). Le message "Statement executed successfully" confirme que la structure est prête à recevoir les données. Aucune donnée n'est encore chargée à cette étape.

---

## Étape 3 - Création des tables JSON - Axel

```sql
USE DATABASE linkedin;
USE SCHEMA raw;
USE WAREHOUSE COMPUTE_WH;

CREATE OR REPLACE TABLE companies (
  company_id   VARCHAR,
  name         VARCHAR,
  description  TEXT,
  company_size INT,
  state        VARCHAR,
  country      VARCHAR,
  city         VARCHAR,
  zip_code     VARCHAR,
  address      VARCHAR,
  url          VARCHAR
);

CREATE OR REPLACE TABLE job_industries (
  job_id      VARCHAR,
  industry_id VARCHAR
);

CREATE OR REPLACE TABLE company_industries (
  company_id VARCHAR,
  industry   VARCHAR
);

CREATE OR REPLACE TABLE company_specialities (
  company_id VARCHAR,
  speciality VARCHAR
);
```

![Tables JSON](screenshots/03_tables_json.png)

> Les 4 tables JSON ont été créées : `companies`, `job_industries`, `company_industries` et `company_specialities`. Ces tables reçoivent des données semi-structurées extraites depuis des fichiers JSON via une table VARIANT intermédiaire. Les colonnes sont typées en VARCHAR pour garantir la compatibilité avec les identifiants hétérogènes du jeu de données. Cette approche évite les erreurs de cast lors du parsing JSON.

---

## Étape 4 - Chargement CSV - Mathis

```sql
USE DATABASE linkedin;
USE SCHEMA raw;
USE WAREHOUSE COMPUTE_WH;

COPY INTO job_postings
  FROM @linkedin_stage/job_postings.csv
  FILE_FORMAT = (FORMAT_NAME = 'fmt_csv')
  ON_ERROR = 'CONTINUE';

COPY INTO benefits
  FROM @linkedin_stage/benefits.csv
  FILE_FORMAT = (FORMAT_NAME = 'fmt_csv')
  ON_ERROR = 'CONTINUE';

COPY INTO employee_counts
  FROM @linkedin_stage/employee_counts.csv
  FILE_FORMAT = (FORMAT_NAME = 'fmt_csv')
  ON_ERROR = 'CONTINUE';

COPY INTO job_skills
  FROM @linkedin_stage/job_skills.csv
  FILE_FORMAT = (FORMAT_NAME = 'fmt_csv')
  ON_ERROR = 'CONTINUE';

SELECT 'job_postings' AS table_name, COUNT(*) AS nb_lignes FROM job_postings UNION ALL
SELECT 'benefits',                   COUNT(*) FROM benefits                  UNION ALL
SELECT 'employee_counts',            COUNT(*) FROM employee_counts           UNION ALL
SELECT 'job_skills',                 COUNT(*) FROM job_skills;
```

![Load CSV](screenshots/04_load_csv.png)

> Le chargement des 4 fichiers CSV s'est effectué via la commande COPY INTO avec le format `fmt_csv`. La vérification finale par SELECT COUNT confirme que les tables contiennent bien des données. L'option ON_ERROR CONTINUE permet d'ignorer les lignes malformées sans bloquer l'import. Les tables `job_postings` et `job_skills` contiennent le plus grand volume de données.

---

## Étape 5 - Chargement JSON - Axel

```sql
USE DATABASE linkedin;
USE SCHEMA raw;
USE WAREHOUSE COMPUTE_WH;

CREATE OR REPLACE TEMP TABLE tmp_json (v VARIANT);

COPY INTO tmp_json
  FROM @linkedin_stage/companies.json
  FILE_FORMAT = (FORMAT_NAME = 'fmt_json');

INSERT INTO companies
SELECT
  v:company_id::VARCHAR, v:name::VARCHAR, v:description::VARCHAR,
  v:company_size::INT, v:state::VARCHAR, v:country::VARCHAR,
  v:city::VARCHAR, v:zip_code::VARCHAR, v:address::VARCHAR, v:url::VARCHAR
FROM tmp_json;

TRUNCATE TABLE tmp_json;
COPY INTO tmp_json FROM @linkedin_stage/company_industries.json FILE_FORMAT = (FORMAT_NAME = 'fmt_json');
INSERT INTO company_industries SELECT v:company_id::VARCHAR, v:industry::VARCHAR FROM tmp_json;

TRUNCATE TABLE tmp_json;
COPY INTO tmp_json FROM @linkedin_stage/company_specialities.json FILE_FORMAT = (FORMAT_NAME = 'fmt_json');
INSERT INTO company_specialities SELECT v:company_id::VARCHAR, v:speciality::VARCHAR FROM tmp_json;

TRUNCATE TABLE tmp_json;
COPY INTO tmp_json FROM @linkedin_stage/job_industries.json FILE_FORMAT = (FORMAT_NAME = 'fmt_json');
INSERT INTO job_industries SELECT v:job_id::VARCHAR, v:industry_id::VARCHAR FROM tmp_json;

SELECT 'companies' AS table_name, COUNT(*) AS nb_lignes FROM companies UNION ALL
SELECT 'company_industries', COUNT(*) FROM company_industries           UNION ALL
SELECT 'company_specialities', COUNT(*) FROM company_specialities       UNION ALL
SELECT 'job_industries', COUNT(*) FROM job_industries;
```

![Load JSON](screenshots/05_load_json.png)

> Le chargement des fichiers JSON a nécessité une approche en deux temps : d'abord COPY INTO dans une table VARIANT temporaire, puis INSERT avec extraction des champs via la notation `v:champ::TYPE`. Cette méthode garantit un typage précis de chaque colonne. La vérification SELECT COUNT confirme que les 4 tables JSON sont bien alimentées.

---

## Analyse 1 - Top 10 titres par industrie - Axel

```sql
USE DATABASE linkedin;
USE SCHEMA raw;
USE WAREHOUSE COMPUTE_WH;

WITH ranked_titles AS (
  SELECT
    ji.industry_id                                    AS industrie,
    jp.title                                          AS titre,
    COUNT(*)                                          AS nb_offres,
    RANK() OVER (
      PARTITION BY ji.industry_id
      ORDER BY COUNT(*) DESC
    )                                                 AS rang
  FROM job_postings jp
  INNER JOIN job_industries ji ON jp.job_id = ji.job_id
  WHERE jp.title IS NOT NULL
  GROUP BY ji.industry_id, jp.title
)
SELECT industrie, titre, nb_offres
FROM ranked_titles
WHERE rang <= 10
ORDER BY industrie, rang;
```

![Analyse 1](screenshots/06_analyse1.png)

> Cette analyse identifie les 10 titres de postes les plus publiés pour chaque secteur d'activité. Les résultats montrent que des titres génériques comme "Software Engineer" ou "Data Analyst" dominent dans la plupart des industries technologiques. La fonction RANK() avec PARTITION BY permet un classement indépendant par industrie. Cette analyse révèle les métiers les plus recherchés selon les secteurs.

---

## Analyse 2 - Top 10 salaires par industrie - Axel

```sql
USE DATABASE linkedin;
USE SCHEMA raw;
USE WAREHOUSE COMPUTE_WH;

WITH ranked_salaries AS (
  SELECT
    ji.industry_id                             AS industrie,
    jp.title                                   AS titre,
    ROUND(AVG(jp.med_salary), 0)              AS salaire_moyen,
    COUNT(*)                                   AS nb_offres,
    RANK() OVER (
      PARTITION BY ji.industry_id
      ORDER BY AVG(jp.med_salary) DESC NULLS LAST
    )                                          AS rang
  FROM job_postings jp
  INNER JOIN job_industries ji ON jp.job_id = ji.job_id
  WHERE jp.med_salary IS NOT NULL
    AND jp.pay_period = 'YEARLY'
    AND jp.title IS NOT NULL
  GROUP BY ji.industry_id, jp.title
  HAVING COUNT(*) >= 2
)
SELECT industrie, titre, salaire_moyen, nb_offres
FROM ranked_salaries
WHERE rang <= 10
ORDER BY industrie, rang;
```

![Analyse 2](screenshots/07_analyse2.png)

> Le calcul des salaires médians annuels par industrie met en évidence des écarts significatifs entre les secteurs. Les industries technologiques et financières proposent les rémunérations les plus élevées, tandis que les secteurs du commerce et des services restent en bas du classement. Le filtre sur `pay_period = YEARLY` garantit la comparabilité des données salariales. La clause HAVING COUNT >= 2 assure la représentativité statistique des résultats.

---

## Analyse 3 - Répartition par taille d'entreprise - Mathis

```sql
USE DATABASE linkedin;
USE SCHEMA raw;
USE WAREHOUSE COMPUTE_WH;

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
LEFT JOIN companies c
  ON LOWER(TRIM(jp.company_name)) = LOWER(TRIM(c.name))
GROUP BY c.company_size
ORDER BY c.company_size NULLS LAST;
```

![Analyse 3](screenshots/08_analyse3.png)

> La répartition des offres par taille d'entreprise révèle que les grandes structures (1001-5000 et 5000+ employés) publient le plus grand nombre d'offres sur LinkedIn. Les PME de 51 à 200 employés représentent également une part significative du marché. Les micro-entreprises et auto-entrepreneurs sont peu représentés, LinkedIn étant davantage utilisé par les structures disposant d'un service RH. Un nombre important d'offres provient d'entreprises dont la taille n'est pas renseignée.

---

## Analyse 4 - Répartition par secteur - Mathis

```sql
USE DATABASE linkedin;
USE SCHEMA raw;
USE WAREHOUSE COMPUTE_WH;

SELECT
  ji.industry_id   AS secteur,
  COUNT(jp.job_id) AS nb_offres
FROM job_postings jp
JOIN job_industries ji ON jp.job_id = ji.job_id
WHERE ji.industry_id IS NOT NULL
GROUP BY ji.industry_id
ORDER BY nb_offres DESC
LIMIT 20;
```

![Analyse 4](screenshots/09_analyse4.png)

> Le top 20 des secteurs d'activité montre une forte concentration des offres dans les domaines de la technologie, de la finance et des services professionnels. Ces secteurs tirent parti de LinkedIn comme canal principal de recrutement pour des profils qualifiés. Les secteurs industriels traditionnels apparaissent peu dans ce classement, confirmant le profil des utilisateurs de la plateforme. Cette analyse oriente les candidats vers les secteurs les plus actifs en recrutement.

---

## Analyse 5 - Répartition par type d'emploi - Mathis

```sql
USE DATABASE linkedin;
USE SCHEMA raw;
USE WAREHOUSE COMPUTE_WH;

SELECT
  COALESCE(formatted_work_type, 'Non renseigné')        AS type_emploi,
  COUNT(*)                                               AS nb_offres,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)   AS pourcentage
FROM job_postings
WHERE formatted_work_type IS NOT NULL
GROUP BY formatted_work_type
ORDER BY nb_offres DESC;
```

![Analyse 5](screenshots/10_analyse5.png)

> Les contrats à temps plein (Full-time) représentent la grande majorité des offres publiées, confirmant que LinkedIn cible principalement des profils cherchant des postes permanents. Les contrats à temps partiel et les stages sont très minoritaires sur la plateforme. Le calcul du pourcentage via une window function SUM OVER() permet une lecture rapide de la distribution. Cette tendance suggère que les employeurs utilisent d'autres canaux pour les recrutements temporaires.

---

## Applications Streamlit

### App Axel - Analyses 1 & 2

```python
import streamlit as st
import pandas as pd
from snowflake.snowpark.context import get_active_session

session = get_active_session()
session.sql("USE DATABASE linkedin").collect()
session.sql("USE SCHEMA raw").collect()

st.title("📊 Analyse LinkedIn - Axel")

tab1, tab2 = st.tabs(["Analyse 1 - Top titres", "Analyse 2 - Top salaires"])

with tab1:
    st.header("Top 10 des titres par industrie")
    industries = session.sql("""
        SELECT DISTINCT industry_id FROM job_industries
        WHERE industry_id IS NOT NULL ORDER BY 1
    """).to_pandas()["INDUSTRY_ID"].tolist()
    industrie_sel = st.selectbox("Choisir une industrie", industries)
    df1 = session.sql(f"""
        WITH ranked AS (
            SELECT jp.title, COUNT(*) AS nb_offres,
                   RANK() OVER (ORDER BY COUNT(*) DESC) AS rang
            FROM job_postings jp
            JOIN job_industries ji ON jp.job_id = ji.job_id
            WHERE ji.industry_id = '{industrie_sel}' AND jp.title IS NOT NULL
            GROUP BY jp.title
        )
        SELECT title AS TITRE, nb_offres AS NB_OFFRES FROM ranked WHERE rang <= 10
        ORDER BY nb_offres DESC
    """).to_pandas()
    st.bar_chart(df1.set_index("TITRE")["NB_OFFRES"])
    st.dataframe(df1)

with tab2:
    st.header("Top 10 salaires par industrie")
    industrie_sel2 = st.selectbox("Choisir une industrie", industries, key="sal")
    df2 = session.sql(f"""
        WITH ranked AS (
            SELECT jp.title, ROUND(AVG(jp.med_salary),0) AS salaire_median,
                   COUNT(*) AS nb_offres,
                   RANK() OVER (ORDER BY AVG(jp.med_salary) DESC NULLS LAST) AS rang
            FROM job_postings jp
            JOIN job_industries ji ON jp.job_id = ji.job_id
            WHERE ji.industry_id = '{industrie_sel2}'
              AND jp.med_salary IS NOT NULL AND jp.pay_period = 'YEARLY'
            GROUP BY jp.title HAVING COUNT(*) >= 2
        )
        SELECT title AS TITRE, salaire_median AS SALAIRE_MEDIAN FROM ranked
        WHERE rang <= 10 ORDER BY salaire_median DESC
    """).to_pandas()
    st.bar_chart(df2.set_index("TITRE")["SALAIRE_MEDIAN"])
    st.dataframe(df2)
```

![Streamlit Axel - Analyse 1](screenshots/11_streamlit_axel_analyse1.png)

> L'application Streamlit d'Axel permet de sélectionner dynamiquement une industrie et d'afficher le top 10 des titres les plus publiés sous forme de bar chart interactif. Les données sont requêtées en temps réel depuis Snowflake via `session.sql().to_pandas()`. Le cache Streamlit optimise les performances en évitant les requêtes répétées.

![Streamlit Axel - Analyse 2](screenshots/12_streamlit_axel_analyse2.png)

> La visualisation des salaires par industrie utilise un bar chart pour une meilleure lisibilité des titres de postes. Les données sont filtrées sur les salaires annuels uniquement pour garantir la comparabilité. Un menu déroulant permet de naviguer entre les industries disponibles.

---

### App Mathis - Analyses 3, 4 & 5

```python
import streamlit as st
import pandas as pd
from snowflake.snowpark.context import get_active_session

session = get_active_session()
session.sql("USE DATABASE linkedin").collect()
session.sql("USE SCHEMA raw").collect()

st.title(" Analyse LinkedIn - Mathis")

tab1, tab2, tab3 = st.tabs([
    "Analyse 3 - Taille entreprise",
    "Analyse 4 - Secteur",
    "Analyse 5 - Type emploi"
])

with tab1:
    st.header("Répartition des offres par taille d'entreprise")
    df3 = session.sql("""
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
        LEFT JOIN companies c
            ON LOWER(TRIM(jp.company_name)) = LOWER(TRIM(c.name))
        GROUP BY c.company_size
        ORDER BY c.company_size NULLS LAST
    """).to_pandas()
    st.bar_chart(df3.set_index("TAILLE_ENTREPRISE")["NB_OFFRES"])
    st.dataframe(df3)

with tab2:
    st.header("Top 20 secteurs d'activité")
    df4 = session.sql("""
        SELECT ji.industry_id AS secteur, COUNT(jp.job_id) AS nb_offres
        FROM job_postings jp
        JOIN job_industries ji ON jp.job_id = ji.job_id
        WHERE ji.industry_id IS NOT NULL
        GROUP BY ji.industry_id
        ORDER BY nb_offres DESC
        LIMIT 20
    """).to_pandas()
    st.bar_chart(df4.set_index("SECTEUR")["NB_OFFRES"])
    st.dataframe(df4)

with tab3:
    st.header("Répartition par type d'emploi")
    df5 = session.sql("""
        SELECT
            COALESCE(formatted_work_type, 'Non renseigné') AS type_emploi,
            COUNT(*) AS nb_offres,
            ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pourcentage
        FROM job_postings
        WHERE formatted_work_type IS NOT NULL
        GROUP BY formatted_work_type
        ORDER BY nb_offres DESC
    """).to_pandas()
    st.bar_chart(df5.set_index("TYPE_EMPLOI")["NB_OFFRES"])
    st.dataframe(df5)
```

![Streamlit Mathis - Analyse 3](screenshots/13_streamlit_mathis_analyse3.png)

> L'onglet Analyse 3 affiche la répartition des offres par taille d'entreprise sous forme de bar chart avec des labels lisibles. La jointure sur le nom d'entreprise avec LOWER et TRIM garantit la qualité de la correspondance entre les tables. Le tableau de données brutes est affiché en dessous pour permettre une lecture précise des chiffres.

![Streamlit Mathis - Analyse 4](screenshots/14_streamlit_mathis_analyse4.png)

> L'onglet Analyse 4 présente les 20 secteurs d'activité les plus représentés sous forme de bar chart trié par volume décroissant. La jointure avec `job_industries` permet d'associer chaque offre à son secteur. Les résultats sont limités au top 20 pour une meilleure lisibilité.

![Streamlit Mathis - Analyse 5](screenshots/15_streamlit_mathis_analyse5.png)

> L'onglet Analyse 5 visualise la répartition des types d'emploi sous forme de bar chart et de tableau. Le pourcentage calculé via window function est affiché pour chaque type de contrat. Cette visualisation permet d'identifier en un coup d'œil la dominance du temps plein sur la plateforme LinkedIn.

---

## Problèmes rencontrés et solutions

- **Problème** : Snowflake exécutait les scripts ligne par ligne au lieu de tout exécuter → **Solution** : Utiliser "Run All" via la flèche ▼ à côté du bouton Run, ou Ctrl+A pour tout sélectionner avant d'exécuter
- **Problème** : Erreur `Cannot perform STAGE LS - no current database` lors du LIST @stage → **Solution** : Toujours déclarer USE DATABASE et USE SCHEMA en début de chaque script
- **Problème** : La colonne `company_name` dans `job_postings` contient des noms texte et non des IDs → **Solution** : Utiliser LOWER(TRIM()) des deux côtés de la jointure pour éviter les problèmes de casse et d'espaces
- **Problème** : L'app Streamlit ne trouvait pas les tables (`Object JOB_POSTINGS does not exist`) → **Solution** : Ajouter `session.sql("USE DATABASE linkedin").collect()` et `session.sql("USE SCHEMA raw").collect()` en début d'app
- **Problème** : Les scripts SQL collés dans Snowflake se retrouvaient sur une seule ligne → **Solution** : Coller le code depuis un éditeur texte ou utiliser Run All
- **Problème** : Erreur `File format FMT_JSON does not exist` → **Solution** : Recréer le format avec `CREATE OR REPLACE FILE FORMAT fmt_json TYPE = 'JSON' STRIP_OUTER_ARRAY = TRUE`

---

## Auteurs

- **Axel Remillat** — Big Data & IA, ESME Paris, 2026
- **Mathis Levrot** — Big Data & IA, ESME Paris, 2026
