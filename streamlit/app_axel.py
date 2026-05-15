# Application Streamlit d'Axel : dashboard interactif de visualisation et d'exploration des données BigData
import streamlit as st
from snowflake.snowpark.context import get_active_session

session = get_active_session()
session.sql("USE DATABASE linkedin").collect()
session.sql("USE SCHEMA raw").collect()

st.title("📊 Analyse LinkedIn - Axel Remillat")

# ============================================
# Analyse 1 : Top 10 titres par industrie
# ============================================
st.header("Analyse 1 - Top 10 titres de postes par industrie")

industry_ids = session.sql("""
    SELECT DISTINCT ji.industry_id
    FROM job_postings jp
    JOIN job_industries ji ON jp.job_id = ji.job_id
    ORDER BY ji.industry_id
""").to_pandas()

selected_industry = st.selectbox(
    "Sélectionne une industrie :",
    industry_ids["INDUSTRY_ID"].tolist(),
    key="ind1"
)

df1 = session.sql(f"""
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
    SELECT title, nb_offres
    FROM ranked
    WHERE rang <= 10 AND industry_id = {selected_industry}
    ORDER BY nb_offres DESC
""").to_pandas()

st.bar_chart(df1.set_index("TITLE")["NB_OFFRES"])
st.dataframe(df1)

# ============================================
# Analyse 2 : Top 10 salaires par industrie
# ============================================
st.header("Analyse 2 - Top 10 postes les mieux rémunérés par industrie")

selected_industry2 = st.selectbox(
    "Sélectionne une industrie :",
    industry_ids["INDUSTRY_ID"].tolist(),
    key="ind2"
)

df2 = session.sql(f"""
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
    SELECT title, salaire_moyen
    FROM ranked_salary
    WHERE rang <= 10 AND industry_id = {selected_industry2}
    ORDER BY salaire_moyen DESC
""").to_pandas()

if df2.empty:
    st.warning("Pas de données de salaire pour cette industrie.")
else:
    st.bar_chart(df2.set_index("TITLE")["SALAIRE_MOYEN"])
    st.dataframe(df2)
