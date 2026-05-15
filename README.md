# Analyse des Offres d'Emploi LinkedIn avec Snowflake

## Introduction

Ce projet a été réalisé dans le cadre de l'évaluation d'Architecture Big Data à l'ESME Paris (2026). Il consiste à ingérer, stocker et analyser un jeu de données d'offres d'emploi LinkedIn en utilisant **Snowflake** comme entrepôt de données cloud et **Streamlit** pour la visualisation interactive.

Les données comprennent des fichiers au format **CSV** (offres d'emploi, entreprises, compétences) et **JSON** (données enrichies), chargées depuis un stage S3. L'objectif est de produire des analyses pertinentes sur le marché de l'emploi : titres les plus demandés, salaires par industrie, répartition par taille d'entreprise et type de contrat.

---

## Répartition des tâches

| Tâche | Axel Remillat | Mathis |
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

Cette première étape consiste à initialiser l'environnement complet Snowflake nécessaire au projet. Nous créons la base de données `linkedin`, le schéma `raw`, ainsi qu'un warehouse de calcul `COMPUTE_WH` en taille X-Small avec auto-suspension après 60 secondes d'inactivité. Un stage externe est configuré pour pointer vers le bucket S3 public `s3://snowflake-lab-bucket/`, et deux formats de fichiers sont définis : un format CSV avec gestion des guillemets et des valeurs nulles, et un format JSON avec dépliage du tableau racine. La commande `LIST @stage` confirme la présence des 8 fichiers de données.

```sql
-- À compléter : voir sql/01_setup_axel.sql
```

![Setup](screenshots/01_list_stage.png)

---

## Étape 2 - Création des tables CSV - Mathis

Mathis prend en charge la création des 4 tables destinées à accueillir les données au format CSV. La table `job_postings` est la plus volumineuse avec 27 colonnes couvrant toutes les informations d'une offre d'emploi : identifiant, titre, description, salaires min/med/max, type de contrat, localisation, nombre de candidatures et de vues. Les tables `benefits`, `employee_counts` et `job_skills` complètent ce schéma avec respectivement les avantages sociaux, les effectifs par entreprise et les compétences requises par offre. Tous les types de données sont soigneusement choisis (NUMBER, FLOAT, VARCHAR, TEXT) pour correspondre au contenu réel des fichiers.

```sql
-- À compléter : voir sql/05_create_tables_mathis.sql
```

![Tables CSV](screenshots/02_tables_csv.png)

---

## Étape 3 - Création des tables JSON - Axel

Axel crée les 4 tables correspondant aux fichiers JSON, qui décrivent les entreprises et leurs caractéristiques. La table `companies` stocke les informations détaillées de chaque entreprise : identifiant LinkedIn, nom, description, taille (codée de 0 à 7), localisation géographique et URL. Les tables `company_industries` et `company_specialities` permettent une relation many-to-many entre entreprises et secteurs ou spécialités. Enfin, `job_industries` établit le lien entre chaque offre d'emploi et son secteur d'activité, clé pour les analyses par industrie.

```sql
-- À compléter : voir sql/02_create_tables_axel.sql
```

![Tables JSON](screenshots/03_tables_json.png)

---

## Étape 4 - Chargement CSV - Mathis

Mathis utilise la commande `COPY INTO` pour charger les 4 fichiers CSV depuis le stage S3 vers les tables Snowflake correspondantes. Le format `csv_format` défini à l'étape 1 est appliqué pour gérer correctement les champs entre guillemets, les headers et les valeurs nulles. Au total, plus de 57 000 lignes sont chargées : 15 886 offres d'emploi, 13 761 avantages sociaux, 15 907 données d'effectifs et 27 099 compétences associées aux offres. Une requête de vérification avec `COUNT(*)` confirme l'intégrité du chargement pour chaque table.

```sql
-- À compléter : voir sql/05_load_data_mathis.sql
```

![Load CSV](screenshots/04_load_csv.png)

---

## Étape 5 - Chargement JSON - Axel

Axel charge les 4 fichiers JSON en utilisant une syntaxe `COPY INTO` avec sous-requête `SELECT` pour extraire les champs depuis la structure semi-structurée Snowflake. Chaque champ est casté explicitement vers le bon type SQL (NUMBER, VARCHAR) via la notation `$1:field_name::TYPE`. Le chargement totalise plus de 171 000 lignes réparties sur les 4 tables : 6 063 entreprises, 15 880 associations industrie-entreprise, 128 355 spécialités et 21 993 liens offre-industrie. La vérification finale confirme la cohérence des données chargées.

```sql
-- À compléter : voir sql/03_load_data_axel.sql
```

![Load JSON](screenshots/05_load_json.png)

---

## Analyse 1 - Top 10 titres par industrie - Axel

Cette analyse identifie les 10 titres de postes les plus fréquemment publiés pour chaque secteur d'activité. Elle repose sur une jointure entre `job_postings` et `job_industries`, regroupée par `industry_id` et `title`, avec un comptage des occurrences. La fonction analytique `ROW_NUMBER() OVER (PARTITION BY industry_id ORDER BY COUNT(*) DESC)` permet de classer les titres au sein de chaque industrie et de ne conserver que le top 10. La visualisation Streamlit propose un menu déroulant pour filtrer par industrie et affiche un bar chart interactif avec le tableau de données associé.

```sql
-- À compléter : voir sql/04_analytics_axel.sql
```

![Analyse 1](screenshots/06_analyse1.png)

---

## Analyse 2 - Top 10 salaires par industrie - Axel

Cette analyse détermine les 10 postes les mieux rémunérés par secteur d'activité en se basant sur le salaire médian (`med_salary`). Une CTE avec `ROW_NUMBER()` partitionné par industrie classe les postes par salaire moyen décroissant, en excluant les offres sans information salariale. Les résultats mettent en évidence des écarts importants entre industries, avec certains secteurs affichant des médianes supérieures à 130 000$/an. La visualisation Streamlit permet de comparer dynamiquement les rémunérations entre industries via un sélecteur interactif.

```sql
-- À compléter : voir sql/04_analytics_axel.sql
```

![Analyse 2](screenshots/07_analyse2.png)

---

## Analyse 3 - Répartition par taille d'entreprise - Mathis

Cette analyse répartit les offres d'emploi selon la taille des entreprises recruteurs, codée de 0 (auto-entrepreneur) à 7 (5000+ employés) dans la table `companies`. La jointure entre `job_postings` et `companies` utilise un cast de `company_name::NUMBER` sur `company_id`, car le champ `company_name` contient en réalité des identifiants numériques. Les résultats révèlent que les grandes entreprises (taille 6 et 7) dominent largement le marché des offres LinkedIn, ce qui reflète leur capacité à recruter massivement. Cette découverte constitue l'un des problèmes techniques les plus intéressants du projet, résolu grâce à une inspection minutieuse des données.

```sql
-- À compléter : voir sql/07_analytics_mathis.sql
```

![Analyse 3](screenshots/08_analyse3.png)

---

## Analyse 4 - Répartition par secteur - Mathis

Cette analyse identifie les 20 secteurs d'activité les plus actifs en termes de recrutement sur LinkedIn. Elle combine trois tables via des jointures successives : `job_postings` → `companies` (via company_id) → `company_industries` (via company_id). Le résultat est trié par nombre d'offres décroissant et limité aux 20 premiers secteurs pour lisibilité. La visualisation met en évidence la domination de certains secteurs comme la technologie, la finance et la santé, offrant une vue claire des dynamiques du marché de l'emploi.

```sql
-- À compléter : voir sql/07_analytics_mathis.sql
```

![Analyse 4](screenshots/09_analyse4.png)

---

## Analyse 5 - Répartition par type d'emploi - Mathis

Cette analyse étudie la distribution des offres selon leur type de contrat : temps plein, contrat, temps partiel, temporaire, stage, bénévolat. Elle s'appuie directement sur la colonne `formatted_work_type` de `job_postings` avec un `COALESCE` pour gérer les valeurs nulles. Un calcul de pourcentage via `SUM() OVER ()` complète le comptage brut pour une lecture proportionnelle. Les résultats montrent une forte domination du temps plein (80.85%) suivi des contrats (10.95%), ce qui traduit la nature professionnelle des offres indexées sur LinkedIn.

```sql
-- À compléter : voir sql/07_analytics_mathis.sql
```

![Analyse 5](screenshots/10_analyse5.png)

---

## Applications Streamlit

### App Axel - Analyses 1 & 2
L'application Streamlit d'Axel intègre les analyses 1 et 2 dans une interface interactive déployée directement dans Snowflake. Un menu déroulant permet de filtrer les résultats par industrie pour chacune des deux analyses, rendant l'exploration des données intuitive. Les graphiques en barres sont générés dynamiquement depuis les requêtes SQL exécutées en temps réel via `session.sql()`, sans aucune donnée pré-calculée. Un tableau de données détaillé accompagne chaque visualisation pour permettre une lecture précise des valeurs.

![Streamlit Axel - Analyse 1](screenshots/11_streamlit_axel_analyse1.png)
![Streamlit Axel - Analyse 2](screenshots/12_streamlit_axel_analyse2.png)

### App Mathis - Analyses 3, 4 & 5
L'application Streamlit de Mathis regroupe les analyses 3, 4 et 5 dans une interface à onglets pour une navigation claire. Chaque onglet correspond à une analyse distincte avec son propre graphique en barres et son tableau de données. Les requêtes SQL s'appuient sur les jointures complexes identifiées lors de la phase d'analyse, notamment le cast `company_name::NUMBER` pour relier les offres aux entreprises. L'ensemble tourne nativement dans Snowflake sans infrastructure externe, garantissant des performances optimales sur les données chargées.

![Streamlit Mathis - Analyse 3](screenshots/13_streamlit_mathis_analyse3.png)
![Streamlit Mathis - Analyse 4](screenshots/14_streamlit_mathis_analyse4.png)
![Streamlit Mathis - Analyse 5](screenshots/15_streamlit_mathis_analyse5.png)

---

## Problèmes rencontrés et solutions

- **Problème** : Snowflake exécutait les scripts ligne par ligne au lieu de tout exécuter → **Solution** : Utiliser "Run All" via la flèche ▼ à côté du bouton Run, ou Ctrl+A pour tout sélectionner avant d'exécuter
- **Problème** : Erreur `Cannot perform STAGE LS - no current database` lors du LIST @stage → **Solution** : Toujours déclarer USE DATABASE et USE SCHEMA en début de chaque script
- **Problème** : La colonne `company_name` dans `job_postings` contient des IDs numériques et non des noms d'entreprises → **Solution** : Cast en NUMBER (`company_name::NUMBER`) pour joindre directement sur `company_id` dans la table `companies`
- **Problème** : L'app Streamlit ne trouvait pas les tables (`Object JOB_POSTINGS does not exist`) → **Solution** : Ajouter `session.sql("USE DATABASE linkedin").collect()` et `session.sql("USE SCHEMA raw").collect()` en début d'app
- **Problème** : Les scripts SQL collés dans Snowflake se retrouvaient sur une seule ligne → **Solution** : Coller le code depuis un éditeur texte ou utiliser Run All
- **Problème**: La coordination entre les deux comptes Snowflake séparés a été une difficulté majeure — nous ne savions pas si nous étions sur la même session, si les objets créés par l'un étaient visibles par l'autre, et Snowflake ne propose pas de mécanisme simple de partage de workspace entre comptes différents → Solution : Chaque membre a recréé l'environnement complet sur son propre compte (DB, stage, formats, tables), et la coordination s'est faite uniquement via le repo GitHub commun pour synchroniser les fichiers SQL et le code Streamlit
---

## Auteurs

- **Axel Remillat** — Big Data & IA, ESME Paris, 2026
- **Mathis Levrot** — Big Data & IA, ESME Paris, 2026
