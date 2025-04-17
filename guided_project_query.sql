USE crimes;

-- Write your query here
-- What is the total number of crimes for each crime status?
SELECT case_status_desc, COUNT(*) AS total_crimes
FROM report_t
GROUP BY case_status_desc;

-- Which was the most frequent crime committed each week?
SELECT week_number, crime_type, total_crimes
FROM (
    SELECT week_number, crime_type, COUNT(*) AS total_crimes,
           RANK() OVER(PARTITION BY week_number ORDER BY COUNT(*) DESC) AS rnk
    FROM report_t
    GROUP BY week_number, crime_type
) AS ranked_crimes
WHERE rnk = 1;

-- Does the existence of CCTV cameras deter crimes from happening? 
SELECT cctv_flag, COUNT(*) AS total_crimes
FROM report_t
GROUP BY cctv_flag;

-- How much footage has been recovered from the CCTV at the crime scene?
SELECT 
    SUM(CASE WHEN r.cctv_flag = 'Yes' THEN l.cctv_count ELSE 0 END) AS cctv_footage_recovered,
    SUM(l.cctv_count) AS total_cctv_installed
FROM report_t r
JOIN location_t l ON r.area_code = l.area_code;



-- What is the frequency of various complaint types?
SELECT complaint_type, COUNT(*) AS complaint_count
FROM report_t
GROUP BY complaint_type
ORDER BY complaint_count DESC;


-- Is crime more likely to be committed by the relation of victims or strangers?
SELECT offender_relation, COUNT(*) AS total_crimes
FROM report_t
GROUP BY offender_relation
ORDER BY total_crimes DESC;


-- Is crime more prevalent in areas with a higher population density, fewer police personnel, and a larger precinct area?
SELECT 
precinct_code, 
SUM(population_density) AS pop_density, 
COUNT(r.area_code) AS total_areas, 
COUNT(r.officer_code) AS total_officers, 
COUNT(report_no) AS cases_reported 
FROM report_t as r 
JOIN location_t as l 
ON l.area_code = r.area_code 
JOIN officer_t as o 
ON r.officer_code = o.officer_code 
GROUP BY precinct_code 
ORDER BY precinct_code;

-- At what parts of the day is the crime rate at its peak? Group this by the type of crime. Use the following mapping to divide the day into five parts.
-- 00:00 to 05:00 = Midnight, 
-- 05:01 to 12:00 = Morning, 
-- 12:01 to 18:00 = Afternoon,
-- 18:01 to 21:00 = Evening, 
-- 21:00 to 24:00 = Night

SELECT dayparts, crime_type, total_crimes
FROM (
    SELECT 
        CASE 
            WHEN HOUR(incident_time) BETWEEN 0 AND 5 THEN 'Midnight'
            WHEN HOUR(incident_time) BETWEEN 6 AND 12 THEN 'Morning'
            WHEN HOUR(incident_time) BETWEEN 12 AND 18 THEN 'Afternoon'
            WHEN HOUR(incident_time) BETWEEN 18 AND 21 THEN 'Evening'
            ELSE 'Night'
        END AS dayparts,
        crime_type,
        COUNT(*) AS total_crimes,
        RANK() OVER(PARTITION BY crime_type ORDER BY COUNT(*) DESC) AS rnk
    FROM report_t
    GROUP BY dayparts, crime_type
) AS ranked_crimes
WHERE rnk = 1;


-- At what point in the day do most crimes occur in different localities? Use the same mapping provided in Question 8 to divide the day into five parts

SELECT area_name, dayparts, total_crimes
FROM (
    SELECT 
        l.area_name,
        CASE 
            WHEN HOUR(r.incident_time) BETWEEN 0 AND 5 THEN 'Midnight'
            WHEN HOUR(r.incident_time) BETWEEN 6 AND 12 THEN 'Morning'
            WHEN HOUR(r.incident_time) BETWEEN 12 AND 18 THEN 'Afternoon'
            WHEN HOUR(r.incident_time) BETWEEN 18 AND 21 THEN 'Evening'
            ELSE 'Night'
        END AS dayparts,
        COUNT(*) AS total_crimes,
        RANK() OVER(PARTITION BY l.area_name ORDER BY COUNT(*) DESC) AS rnk
    FROM report_t r
    JOIN location_t l ON r.area_code = l.area_code
    GROUP BY l.area_name, dayparts
) AS ranked_localities
WHERE rnk = 1;


-- Which age group is more likely to fall victim to crimes at certain points in the day? Use the same mapping provided in Question 8 to divide the day into five parts. Additionally, use the following mapping to divide the age group. 
-- Age 0 to 12: kids 
-- 13 to 23: teenage
-- 24 to 35: middle age
-- 36 to 55: adults
-- 56 to 120: old


SELECT age_group, dayparts, COUNT(*) AS total_crimes
FROM (
    SELECT 
        CASE 
            WHEN v.victim_age BETWEEN 0 AND 12 THEN 'Kids'
            WHEN v.victim_age BETWEEN 13 AND 23 THEN 'Teenage'
            WHEN v.victim_age BETWEEN 24 AND 35 THEN 'Middle Age'
            WHEN v.victim_age BETWEEN 36 AND 55 THEN 'Adults'
            WHEN v.victim_age BETWEEN 56 AND 120 THEN 'Old'
            ELSE 'Unknown'
        END AS age_group,
        CASE 
            WHEN HOUR(r.incident_time) BETWEEN 0 AND 5 THEN 'Midnight'
            WHEN HOUR(r.incident_time) BETWEEN 6 AND 12 THEN 'Morning'
            WHEN HOUR(r.incident_time) BETWEEN 12 AND 18 THEN 'Afternoon'
            WHEN HOUR(r.incident_time) BETWEEN 18 AND 21 THEN 'Evening'
            ELSE 'Night'
        END AS dayparts
    FROM report_t r
    JOIN victim_t v ON r.victim_code = v.victim_code
) AS categorized_crimes
GROUP BY age_group, dayparts
ORDER BY total_crimes DESC;

-- Crime Metrics Overview

SELECT COUNT(DISTINCT precinct_code) AS total_precincts FROM officer_t;

SELECT COUNT(*) AS total_crimes_reported FROM report_t;

SELECT COUNT(DISTINCT area_code) AS total_areas FROM location_t;

SELECT COUNT(DISTINCT victim_code) AS total_offenders FROM victim_t;

SELECT COUNT(DISTINCT officer_code) AS total_officers FROM officer_t;

SELECT SUM(population_density) AS total_population FROM location_t;

SELECT SUM(cctv_count) AS total_cctvs FROM location_t;

SELECT COUNT(*) AS case_status_code FROM report_t WHERE case_status = 'IC';

SHOW COLUMNS FROM report_t;








