-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT npi, total_claim_count
FROM prescription
ORDER BY total_claim_count DESC
LIMIT 1;

-- NPI: 1912011792, Total claims: 4538

--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT t1.nppes_provider_first_name, t1.nppes_provider_last_org_name, t1.specialty_description, t2.total_claim_count
FROM prescriber AS t1
LEFT JOIN prescription AS t2
USING (npi)
WHERE total_claim_count IS NOT NULL   --could have used a Inner Join instead of the WHERE clause?
ORDER BY total_claim_count DESC
LIMIT 1;

--DAVID	COFFEY, Family Practice, 4538

-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT DISTINCT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription  		--chose left join to include all specialties, had to filter out nulls 										from total_claims and ended up
USING (npi)             		  -- with basiclly an inner join
WHERE total_claim_count IS NOT NULL
GROUP BY specialty_description
ORDER BY total_claims DESC;

--   "Family Practice",	9752347

--     b. Which specialty had the most total number of claims for opioids?
SELECT DISTINCT specialty_description, Sum(total_claim_count) AS total_claims
FROM prescriber AS t1
INNER JOIN prescription AS t2
USING (npi)
INNER JOIN drug AS t3
USING (drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY total_claims DESC;

-- "Nurse Practitioner"	900845

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT DISTINCT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
USING (npi)
GROUP BY specialty_description
ORDER BY total_claims DESC;

-- Yes, there are 15, unsure of how to filter for only the NULL



--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?
SELECT DISTINCT generic_name, total_drug_cost
FROM drug
INNER JOIN prescription
USING (drug_name)
ORDER BY total_drug_cost DESC
LIMIT 1;

--"PIRFENIDONE", 2829174.3

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT DISTINCT generic_name, ROUND((total_drug_cost / total_day_supply),2) AS cost_per_day
FROM drug
INNER JOIN prescription
USING (drug_name)
ORDER BY cost_per_day DESC
LIMIT 1;

--"IMMUN GLOB G(IGG)/GLY/IGA OV50",	7141.11

-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
SELECT drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
FROM drug;


--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT SUM(total_drug_cost) AS MONEY,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
FROM drug
INNER JOIN prescription
USING(drug_name)
GROUP BY drug_type;

--More on opioids. 105080626.37 on opioids vs 38435121.26 on antibiotics

-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
Select *
FROM cbsa
WHERE cbsaname LIKE '%TN'

-- 33

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

(SELECT DISTINCT(cbsaname), SUM(population) as total_pop
FROM cbsa
INNER JOIN fips_county
USING (fipscounty)
INNER JOIN population
USING (fipscounty)
GROUP BY cbsaname
ORDER BY total_pop DESC
LIMIT 1)
UNION ALL
(SELECT DISTINCT(cbsaname), SUM(population) as total_pop
FROM cbsa
INNER JOIN fips_county
USING (fipscounty)
INNER JOIN population
USING (fipscounty)
GROUP BY cbsaname
ORDER BY total_pop ASC
LIMIT 1)

--"Nashville-Davidson--Murfreesboro--Franklin, TN",	1830410
--"Morristown, TN",	116352

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.


SELECT population,county
FROM population
Left JOIN fips_county
USING (fipscounty)
LEFT JOIN cbsa
USING (fipscounty)
WHERE cbsaname IS NULL
ORDER BY population DESC
LIMIT 1;

-- "SEVIER", pop 95523


-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
Select drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000

--"OXYCODONE HCL"			4538
-- "GABAPENTIN"					3531
-- "MIRTAZAPINE"				3085
-- "LISINOPRIL"					3655
-- "FUROSEMIDE"					3083
-- "HYDROCODONE-ACETAMINOPHEN"	3376
-- "LEVOTHYROXINE SODIUM"		3101
-- "LEVOTHYROXINE SODIUM"		3138
-- "LEVOTHYROXINE SODIUM"		3023

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
    
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
