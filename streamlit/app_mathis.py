# Application Streamlit de Mathis : dashboard interactif de visualisation et d'exploration des données BigData
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
        SELECT
            ji.industry_id AS secteur,
            COUNT(jp.job_id) AS nb_offres
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
