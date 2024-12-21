-- 1. Select all records from the "hrs" table
SELECT * FROM public."hrs";

-- 2. Alter column "id" to change its data type to varchar(20)
ALTER TABLE public."hrs"
ALTER COLUMN id SET DATA TYPE varchar(20);

-- 3. Drop the NOT NULL constraint from the "id" column
ALTER TABLE public."hrs"
ALTER COLUMN id DROP NOT NULL;

-- 4. Set date style to ISO with YMD format
SET datestyle = 'ISO, YMD';

-- 5. Update the "birthdate" column to standardize the format
UPDATE public."hrs"
SET birthdate = CASE
    WHEN birthdate LIKE '%/%' THEN to_char(TO_DATE(birthdate, 'MM/DD/YYYY'), 'YYYY/MM/DD')
    WHEN birthdate LIKE '%-%' THEN to_char(TO_DATE(birthdate, 'MM-DD-YYYY'), 'YYYY/MM/DD')
    ELSE NULL
END
WHERE birthdate IS NOT NULL AND birthdate != '';

-- 6. Update the "birthdate" column to standardize and fix year format
UPDATE public."hrs"
SET birthdate = 
    CASE
        WHEN birthdate LIKE '____/__/__' THEN
            CASE
                WHEN SUBSTRING(birthdate FROM 3 FOR 2) > '30' THEN
                    '19' || SUBSTRING(birthdate FROM 3 FOR 2) || '/' || SUBSTRING(birthdate FROM 6 FOR 5)
                WHEN SUBSTRING(birthdate FROM 3 FOR 2) < '30' THEN
                    '20' || SUBSTRING(birthdate FROM 3 FOR 2) || '/' || SUBSTRING(birthdate FROM 6 FOR 5)
                ELSE birthdate
            END
        ELSE birthdate  
    END;

-- 7. Alter column "birthdate" to set its data type to date
ALTER TABLE public."hrs"
ALTER COLUMN birthdate SET DATA TYPE date
USING birthdate :: date;

-- 8. Update the "hire_date" column to standardize the format
UPDATE public."hrs"
SET hire_date = CASE
    WHEN hire_date LIKE '%/%' THEN to_char(TO_DATE(hire_date, 'MM/DD/YYYY'), 'YYYY/MM/DD')
    WHEN hire_date LIKE '%-%' THEN to_char(TO_DATE(hire_date, 'MM-DD-YYYY'), 'YYYY/MM/DD')
    ELSE NULL
END
WHERE hire_date IS NOT NULL AND hire_date != '';

-- 9. Update the "hire_date" column to standardize and fix year format
UPDATE public."hrs"
SET hire_date = 
    CASE
        WHEN hire_date LIKE '____/__/__' THEN
            CASE
                WHEN SUBSTRING(hire_date FROM 3 FOR 2) > '30' THEN
                    '19' || SUBSTRING(hire_date FROM 3 FOR 2) || '/' || SUBSTRING(hire_date FROM 6 FOR 5)
                WHEN SUBSTRING(hire_date FROM 3 FOR 2) < '30' THEN
                    '20' || SUBSTRING(hire_date FROM 3 FOR 2) || '/' || SUBSTRING(hire_date FROM 6 FOR 5)
                ELSE hire_date
            END
        ELSE hire_date  
    END;

-- 10. Alter column "hire_date" to set its data type to date
ALTER TABLE public."hrs"
ALTER COLUMN hire_date SET DATA TYPE date
USING hire_date :: date;

-- 11. Update the "termndate" column to the correct date format
UPDATE public."hrs"
SET termndate = to_date(to_timestamp(termndate, 'YYYY-MM-DD HH24:MI:SS UTC') :: TEXT, 'MM/DD/YYYY')
WHERE termndate IS NOT NULL AND termndate = ' ';

-- 12. Alter column "termndate" to set its data type to date
ALTER TABLE public."hrs"
ALTER COLUMN termndate SET DATA TYPE DATE
USING termndate :: DATE;

-- 13. Add a new "age" column
ALTER TABLE public."hrs"
ADD COLUMN age integer;

-- 14. Update the "age" column with the difference between current date and birthdate
UPDATE public."hrs"
SET age = EXTRACT(YEAR FROM AGE(current_date, birthdate));

-- 15. Get the minimum and maximum age from the "hrs" table
SELECT min(age), max(age) FROM public."hrs";

-- 16. Get the minimum and maximum termndate from the "hrs" table
SELECT min(termndate), max(termndate) FROM public."hrs";

-- 17. Gender breakdown of company employees
SELECT gender, count(*) FROM public."hrs"
WHERE termndate > current_date
GROUP BY gender;

-- 18. Race/ethnicity breakdown of employees
SELECT race, COUNT(*) FROM public."hrs"
WHERE termndate > CURRENT_DATE
GROUP BY race;

-- 19. Age distribution of employees in the company
SELECT age, COUNT(*) FROM public."hrs"
WHERE termndate > CURRENT_DATE
GROUP BY age
ORDER BY age DESC;

-- 20. Employees working at headquarters vs remote locations
SELECT LOCATION, COUNT(*) FROM public."hrs"
WHERE termndate > CURRENT_DATE
GROUP BY LOCATION
ORDER BY DESC(*) DESC;

-- 21. Average length of employment for employees who have been terminated
SELECT round(AVG(EXTRACT(YEAR FROM AGE(termndate, hire_date))), 1) AS average_employee_year 
FROM public."hrs"
WHERE termndate < CURRENT_DATE;

-- 22. Gender distribution across departments
SELECT department, gender, COUNT (*) AS employee_count 
FROM public."hrs"
WHERE termndate > CURRENT_DATE
GROUP BY department, gender
ORDER BY department ASC,
    CASE 
        WHEN gender = 'female' THEN 1
        WHEN gender = 'male' THEN 2
        WHEN gender = 'non-conforming' THEN 3 
    END;

-- 23. Gender distribution across job titles
SELECT jobtitle, gender, COUNT (*) AS employee_count 
FROM public."hrs"
WHERE termndate > CURRENT_DATE
GROUP BY jobtitle, gender
ORDER BY jobtitle ASC,
    CASE 
        WHEN gender = 'female' THEN 1
        WHEN gender = 'male' THEN 2
        WHEN gender = 'non-conforming' THEN 3 
    END;

-- 24. Distribution of job titles across the company
SELECT jobtitle, COUNT(*) as number_of_employees 
FROM public."hrs"
WHERE termndate > CURRENT_DATE
GROUP BY jobtitle
ORDER BY COUNT(*) DESC;

-- 25. Department with the highest turnover rate
SELECT department, count(*) as total_count, 
    SUM(CASE WHEN termndate > CURRENT_DATE THEN 1 ELSE 0 END ) as terminated_count,
    SUM(CASE WHEN termndate < CURRENT_DATE THEN 1 ELSE 0 END) as active_count,
    ROUND(SUM(CASE WHEN termndate < CURRENT_DATE THEN 1 ELSE 0 END) / count(*) :: numeric, 2) as termination_rate
FROM public."hrs"
GROUP BY department
ORDER BY department ASC;

-- 26. Distribution of employees across locations by state
SELECT location_store, count(*) FROM public."hrs"
WHERE termndate < current_date
GROUP BY location_store
ORDER BY location_store ASC;

-- 27. How employee count has changed based on hire and term dates
SELECT extract(year from hire_date) as hire_year, count(*) as hires,
    sum(case when termndate < current_date then 1 else 0 end) as terminations,
    count(*) - sum(case when termndate < current_date then 1 else 0 end) as net_change,
    CASE 
        WHEN count(*) > 0 THEN round(
            (count(*) - sum(case when termndate < current_date then 1 else 0 end) :: numeric) 
            / count(*) * 100, 2)
        ELSE 0 
    END as percentage_change
FROM public."hrs"
GROUP BY EXTRACT(year from hire_date)
ORDER BY hire_year;

-- 28. Tenure distribution for each department
SELECT department, ROUND(EXTRACT(YEAR FROM AVG(AGE(termndate, hire_date)))) as average_tenure
FROM public."hrs"
WHERE termndate < current_date
GROUP BY department
ORDER BY department ASC;
