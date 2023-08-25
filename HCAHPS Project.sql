-- About HCAHPS survey: https://data.cms.gov/provider-data/topics/hospitals/hcahps

-- Preview table
SELECT TOP 10 * FROM [HCAHPS-Hospital]

-- Number of participating hospitals
SELECT COUNT(DISTINCT facility_name)
FROM [HCAHPS-Hospital]


-- States AND 6 included territories 
/*
	(AS:American_Samoa,
	DC:District_of_Colombia, GU:Guam,
	MP:Northern_Mariana_Islands, 
	PR:Puerto_Rico, VI:Virgin_Islands)
*/
SELECT DISTINCT state
FROM [HCAHPS-Hospital]
ORDER BY state ASC


-- 93 measures in the survey and average responses
SELECT HCAHPS_question, HCAHPS_measure_ID, 
	AVG(CAST(HCAHPS_answer_percent AS Float)) AS answer_percent,
	AVG(CAST(patient_survey_star_rating AS Float)) AS star_rating,
	AVG(CAST(HCAHPS_linear_mean_value AS Float)) AS mean_value
FROM [HCAHPS-Hospital] 
GROUP BY HCAHPS_question, HCAHPS_measure_ID


-- 22 Individual questions
SELECT SUBSTRING(HCAHPS_measure_ID, 1, 8)
FROM [HCAHPS-Hospital]
GROUP BY SUBSTRING(HCAHPS_measure_ID, 1, 8)
ORDER BY SUBSTRING(HCAHPS_measure_ID, 1, 8) ASC


-- Create a temp table to break down measure_ID into categories
DROP TABLE IF EXISTS #Question_Details
CREATE TABLE #Question_Details (
	HCAHPS_measure_ID NVARCHAR(50),
	question_category NVARCHAR(50),
	measure_category NVARCHAR(50)
);

INSERT INTO #Question_Details
SELECT HCAHPS_measure_ID, 
		-- Question type (nurse, hospital environment, etc.)
		CASE	
			WHEN HCAHPS_measure_ID LIKE '%COMP_1%' OR HCAHPS_measure_ID LIKE '%NURSE%'
				THEN 'nurse_communication'
			WHEN HCAHPS_measure_ID LIKE '%COMP_2%' OR HCAHPS_measure_ID LIKE '%DOCTOR%'
				THEN 'doctor_communication'
			WHEN HCAHPS_measure_ID LIKE '%COMP_3%' OR HCAHPS_measure_ID LIKE '%CALL%'
				OR HCAHPS_measure_ID LIKE '%BATH%'
				THEN 'responsiveness'
			WHEN HCAHPS_measure_ID LIKE '%COMP_5%' OR HCAHPS_measure_ID LIKE '%MED%'
				OR HCAHPS_measure_ID LIKE '%SIDE%'
				THEN 'med_communication'
			WHEN HCAHPS_measure_ID LIKE '%COMP_6%' OR HCAHPS_measure_ID LIKE '%DISCH%'
				THEN 'discharge_info'
			WHEN HCAHPS_measure_ID LIKE '%COMP_7%' OR HCAHPS_measure_ID LIKE '%CT%'
				 OR HCAHPS_measure_ID LIKE '%SYMPTOMS%'
				THEN 'care_transition'
			WHEN HCAHPS_measure_ID LIKE '%CLEAN%' OR HCAHPS_measure_ID LIKE '%QUIET%'
				THEN 'environment'
			WHEN HCAHPS_measure_ID LIKE '%HSP%' OR HCAHPS_measure_ID LIKE '%RECMND%'
				OR HCAHPS_measure_ID LIKE '%H_STAR%'
				THEN 'overall'
		END AS question_category,
		-- Measure type (positive, negative, etc.)
		CASE
			WHEN HCAHPS_measure_ID LIKE '%LINEAR%'
				THEN 'linear_score'
			WHEN HCAHPS_measure_ID LIKE '%STAR%'
				THEN 'star_rating'
			WHEN HCAHPS_measure_ID LIKE '%A_P' OR HCAHPS_measure_ID LIKE '%_SA'
				OR HCAHPS_measure_ID LIKE '%_DY' OR HCAHPS_measure_ID LIKE '%9_10'
				THEN 'positive'
			WHEN HCAHPS_measure_ID LIKE '%U_P' OR HCAHPS_measure_ID LIKE '%_A'
				OR HCAHPS_measure_ID LIKE '%_PY' OR HCAHPS_measure_ID LIKE '%7_8'
				THEN 'neutral'
			WHEN HCAHPS_measure_ID LIKE '%SN_%' OR HCAHPS_measure_ID LIKE '%D_SD'
				OR HCAHPS_measure_ID LIKE '%_DN' OR HCAHPS_measure_ID LIKE '%0_6'
				THEN 'negative'
			WHEN HCAHPS_measure_ID LIKE '%Y_P'
				THEN 'yes'
			WHEN HCAHPS_measure_ID LIKE '%N_P'
				THEN 'no'
		END AS measure_category
FROM [HCAHPS-Hospital] 
GROUP BY HCAHPS_measure_ID

SELECT * FROM #Question_Details


-- Analysis

-- Average positive rating for overall category by state
SELECT state, question_category, 
	AVG(CAST(HCAHPS_Answer_Percent AS Float)) AS avg_positive
FROM [HCAHPS-Hospital] h
LEFT JOIN #Question_Details q ON h.HCAHPS_Measure_ID = q.HCAHPS_measure_ID
WHERE question_category = 'overall' AND measure_category = 'positive'
GROUP BY state, question_category
ORDER BY avg_positive


-- Average negative rating for environment category by state
SELECT state, question_category, 
	AVG(CAST(HCAHPS_Answer_Percent AS Float)) AS avg_negative
FROM [HCAHPS-Hospital] h
LEFT JOIN #Question_Details q ON h.HCAHPS_Measure_ID = q.HCAHPS_measure_ID
WHERE question_category = 'environment' AND measure_category = 'negative'
GROUP BY state, question_category
ORDER BY avg_negative


-- Positive, negative, neutral breakdown per question category per state
SELECT state, question_category, measure_category,
	AVG(CAST(HCAHPS_Answer_Percent AS Float)) AS average
FROM [HCAHPS-Hospital] h
LEFT JOIN #Question_Details q ON h.HCAHPS_Measure_ID = q.HCAHPS_measure_ID
WHERE measure_category <> 'linear_score' AND measure_category <> 'star_rating'
	AND measure_category <> 'yes' AND measure_category <> 'no'
GROUP BY state, question_category, measure_category
ORDER BY state


-- Total surveys collected by state
SELECT state, SUM(Number_of_Completed_Surveys) AS total_surveys
FROM [HCAHPS-Hospital]
GROUP BY state
ORDER BY total_surveys DESC


-- Number of participating hospitals per state
SELECT state, COUNT(DISTINCT facility_name) AS num_hospitals
FROM [HCAHPS-Hospital]
GROUP BY state
ORDER BY num_hospitals


-- Average star rating by state
SELECT state, 
	AVG(CAST(Patient_Survey_Star_Rating AS Float)) AS avg_star_rating
FROM [HCAHPS-Hospital] h
LEFT JOIN #Question_Details q ON h.HCAHPS_Measure_ID = q.HCAHPS_measure_ID
WHERE measure_category = 'star_rating'
GROUP BY state
ORDER BY avg_star_rating


-- Top 10 individual hospitals by overall positive rating
SELECT facility_name, state,
	AVG(CAST(HCAHPS_Answer_Percent AS Float)) AS avg_positive
FROM [HCAHPS-Hospital] h
LEFT JOIN #Question_Details q ON h.HCAHPS_Measure_ID = q.HCAHPS_measure_ID
WHERE question_category = 'overall' AND measure_category = 'positive'
GROUP BY Facility_Name, state
ORDER BY avg_positive DESC


-- Top 10 individual hospitals by overall positive rating 
-- AND over 300 completed surveys
SELECT facility_name, state, number_of_completed_surveys,
	AVG(CAST(HCAHPS_Answer_Percent AS Float)) AS avg_positive
FROM [HCAHPS-Hospital] h
LEFT JOIN #Question_Details q ON h.HCAHPS_Measure_ID = q.HCAHPS_measure_ID
WHERE question_category = 'overall' AND measure_category = 'positive'
	AND Number_of_Completed_Surveys > 2000
GROUP BY Facility_Name, state, number_of_completed_surveys
ORDER BY avg_positive DESC





