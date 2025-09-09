--Pregled tabele (po stolpcih)
PRAGMA table_info("World_Happiness_Report");

--Preveri koliko manjkajočih vrednosti ima posamezen stolpec
SELECT
    SUM(CASE WHEN "Country name" IS NULL OR TRIM("Country name") = '' THEN 1 ELSE 0 END) AS missing_country,
    SUM(CASE WHEN "Regional indicator" IS NULL OR TRIM("Regional indicator") = '' THEN 1 ELSE 0 END) AS missing_region,
    SUM(CASE WHEN "year" IS NULL THEN 1 ELSE 0 END) AS missing_year,
    SUM(CASE WHEN "Life Ladder" IS NULL THEN 1 ELSE 0 END) AS missing_life_ladder,
    SUM(CASE WHEN "Log GDP per capita" IS NULL THEN 1 ELSE 0 END) AS missing_gdp
FROM "World_Happiness_Report";

--Preveriti kje manjkajo podatki (vrstice)
SELECT *
FROM "World_Happiness_Report"
WHERE "Life Ladder" IS NULL
   OR "Log GDP per capita" IS NULL
   OR "Regional indicator" IS NULL
   OR TRIM("Country name") = '';

--Ustvarjanje čistega pogleda (filtriranje)
DROP VIEW IF EXISTS wh_clean;

CREATE VIEW wh_clean AS
SELECT
    "Country name"      AS country,
    "Regional indicator" AS region,
    "year"              AS year,
    "Life Ladder"       AS life_ladder,
    "Log GDP per capita" AS log_gdp_per_capita
FROM "World_Happiness_Report"
WHERE
    COALESCE("Life Ladder", 0) > 0
    AND COALESCE("Log GDP per capita", 0) > 0
    AND TRIM(COALESCE("Regional indicator", '')) <> ''
    AND TRIM(COALESCE("Country name", '')) <> '';

--Preveri ali se je čisti pogled ustvaril
SELECT name, type
FROM sqlite_master
WHERE type IN ('table','view');

--RQ1: regionalne razlike (povprečja Life Ladder po regijah)
SELECT
    region,
    ROUND(AVG(life_ladder), 2) AS avg_life_ladder,
    COUNT(*) AS n_obs
FROM wh_clean
GROUP BY region
ORDER BY avg_life_ladder DESC;

--RQ2: povezanost med BDP (Log GDP per capita) in Life Ladder.
--ukaz za izračun korelacije (Pearson)
WITH stats AS (
    SELECT
        AVG(log_gdp_per_capita) AS x_bar,
        AVG(life_ladder)        AS y_bar,
        AVG(log_gdp_per_capita * life_ladder) AS xy_bar,
        AVG(log_gdp_per_capita * log_gdp_per_capita) AS x2_bar,
        AVG(life_ladder * life_ladder) AS y2_bar
    FROM wh_clean
)
SELECT
    ROUND(
        (xy_bar - x_bar * y_bar)
        / (SQRT(x2_bar - x_bar * x_bar) * SQRT(y2_bar - y_bar * y_bar))
    , 4) AS pearson_r
FROM stats;

--Koda za izračun regresijske premice (y = a + b*x)
WITH stats AS (
    SELECT
        AVG(log_gdp_per_capita) AS x_bar,
        AVG(life_ladder)        AS y_bar,
        AVG(log_gdp_per_capita * life_ladder) AS xy_bar,
        AVG(log_gdp_per_capita * log_gdp_per_capita) AS x2_bar
    FROM wh_clean
)
SELECT
    ROUND( (xy_bar - x_bar * y_bar) / (x2_bar - x_bar * x_bar), 4) AS slope_b,
    ROUND( y_bar - ((xy_bar - x_bar * y_bar) / (x2_bar - x_bar * x_bar)) * x_bar, 4) AS intercept_a
FROM stats;

--RQ3: Časovni trendi za tri države (Afghanistan, Finland, Slovenia)
--vse tri države (pogojna agregacija)
SELECT
    year,
    ROUND(AVG(CASE WHEN country = 'Afghanistan' THEN life_ladder END), 2) AS Afghanistan,
    ROUND(AVG(CASE WHEN country = 'Finland'     THEN life_ladder END), 2) AS Finland,
    ROUND(AVG(CASE WHEN country = 'Slovenia'    THEN life_ladder END), 2) AS Slovenia
FROM wh_clean
WHERE country IN ('Afghanistan', 'Finland', 'Slovenia')
GROUP BY year
ORDER BY year;

--povprečni trendi po celotnem obdobju
SELECT
    country,
    ROUND(AVG(life_ladder), 2) AS overall_avg
FROM wh_clean
WHERE country IN ('Afghanistan', 'Finland', 'Slovenia')
GROUP BY country
ORDER BY overall_avg DESC;


--Deskriptivna statistika
SELECT
    ROUND(AVG(life_ladder), 2) AS mean_life,
    ROUND(MIN(life_ladder), 2) AS min_life,
    ROUND(MAX(life_ladder), 2) AS max_life,
    ROUND(AVG(log_gdp_per_capita), 2) AS mean_log_gdp,
    ROUND(MIN(log_gdp_per_capita), 2) AS min_log_gdp,
    ROUND(MAX(log_gdp_per_capita), 2) AS max_log_gdp,
    COUNT(*) AS n_obs
FROM wh_clean;


-- (1) varno izbriši staro tabelo, če obstaja
DROP TABLE IF EXISTS rq3_long;

-- (2) ustvari long format: year | country | life_ladder
CREATE TABLE rq3_long AS
SELECT
    year,
    country,
    ROUND(AVG(life_ladder), 3) AS life_ladder
FROM wh_clean
WHERE country IN ('Afghanistan','Finland','Slovenia')
GROUP BY year, country
ORDER BY year, country;

SELECT * FROM rq3_long ORDER BY year, country;














