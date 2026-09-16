CREATE TABLE hr_employee_data (
    employee_id INTEGER PRIMARY KEY,
    start_date DATE,
    title VARCHAR(100),
    business_unit VARCHAR(20),
    employee_status VARCHAR(30),
    employee_type VARCHAR(30),
    pay_zone VARCHAR(20),
    employee_classification_type VARCHAR(30),
    department_type VARCHAR(50),
    division VARCHAR(100),
    dob DATE,
    state VARCHAR(2),
    gender_code VARCHAR(10),
    race_desc VARCHAR(30),
    marital_desc VARCHAR(30),
    performance_score VARCHAR(30),
    current_employee_rating INTEGER,
    survey_date DATE,
    engagement_score INTEGER,
    satisfaction_score INTEGER,
    work_life_balance_score INTEGER,
    training_date DATE,
    training_program_name VARCHAR(100),
    training_type VARCHAR(30),
    training_outcome VARCHAR(30),
    training_duration_days INTEGER,
    training_cost NUMERIC(10,2),
    age INTEGER
);

select * from hr_employee_data;

--1. What is the total number of employees in the organization?

select
	count(*) as total_employees
from hr_employee_data;

--2. How many employees are working in each department?

select
	department_type,
	count(*) as total_employees_per_department	
from hr_employee_data
group by department_type
order by 2 desc;

--3. What is the overall average employee satisfaction score?

select
	round(avg(satisfaction_score),2) as avg_satisfaction_score
from hr_employee_data;

--4. How many employees fall into each performance score category?

select 
	performance_score,
	count(*) as total_employees_in_each_score_category
from hr_employee_data
group by 1
order by 2 desc;

--5. What is the average training cost for each training program?

select
	training_program_name,
	round(avg(training_cost),2) as avg_training_cost_for_each_program_type
from hr_employee_data
group by 1
order by 2 desc;

--6.What are the average employee engagement and satisfaction scores for each department?

select
	department_type,
	round(avg(satisfaction_score),2) as avg_satisfaction,
	round(avg(engagement_score),2) as avg_engagement
from hr_employee_data
group by department_type;

--7. How does the average employee rating differ across different employee types 
--such as Full-Time, Part-Time, and Contract?

select
	employee_type,
	round(avg(current_employee_rating),2) as avg_employee_rating
from hr_employee_data
group by 1
order by 2 desc;
	

--8. What percentage of employees fall into each training outcome category
--(Passed, Failed, Completed, and Incomplete)?

select
	training_outcome,
	count(*) as total_employee_in_each_training_outcome,
	round(count(*) * 100 / sum(count(*)) over(), 2) as percentage
from hr_employee_data
group by 1
order by 2 desc;

--9. How is the company's workforce distributed across different age groups?

select 
	count(*) as total_employees,
	case 
		WHEN age < 25 THEN 'Under 25'
		when age between 25 and 34 then '25-34'
		when age between 35 and 44 then '35-44'
		when age between 45 and 55 then '45-54'
		else '55+'
	end as age_groups
from hr_employee_data
group by 
	case 
		when age < 25 then 'Under 25'
		when age between 25 and 34 then '25-34'
		when age between 35 and 44 then '35-44'
		when age between 45 and 55 then '45-54'
		else '55+'
	end
order by 1 desc;
--10. Which departments have the lowest work-life balance scores, and how
--do their satisfaction and engagement scores compare?

select
	department_type,
	round(avg(work_life_balance_score),2) as avg_work_life_balance_score,
	round(avg(satisfaction_score),2) as avg_satisfaction,
	round(avg(engagement_score),2) as avg_engagement
from hr_employee_data
group by department_type;

--11. How do departments rank based on their average employee satisfaction scores?

select
	department_type,
	round(avg(satisfaction_score),2) as avg_satisfaction,
	row_number() over(order by avg(satisfaction_score) desc) as rank
from hr_employee_data
group by 1;
--12. Which departments have an average employee rating below the overall 
--company average?


select 
	department_type,
	round(avg(current_employee_rating),2) as avg_department_rating,
	round(
	(
		select
			avg(current_employee_rating)
		from hr_employee_data), 2
	) as avg_company_rating
from hr_employee_data
group by 1
having avg(current_employee_rating) <=
	(
		select
			avg(current_employee_rating)
		from hr_employee_data
	);

--13. Which training programs have the highest success rate when successful
--training is defined as Passed or Completed?

select 
	training_program_name,
	count(*) as total_trainings,
	sum
	(
		case 
			when training_outcome in ('Passed', 'Completed')then 1
			else 0
			end
	) as successful_training,
	round(sum
	(
		case 
			when training_outcome in ('Passed', 'Completed')then 1
			else 0
			end
	) * 100.0 / count(*),2) as success_rate 
from hr_employee_data
group by 1
order by 3 desc
limit 1;

--14. Which training programs are the most cost-efficient based on the training
--cost per successful outcome?

SELECT
    training_program_name,
    ROUND(AVG(training_cost), 2) AS avg_training_cost,
    SUM(
        CASE
            WHEN training_outcome IN ('Passed', 'Completed') THEN 1
            ELSE 0
        END
    ) AS successful_trainings,
    ROUND(
        SUM(training_cost) /
        NULLIF(
            SUM(
                CASE
                    WHEN training_outcome IN ('Passed', 'Completed') THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS cost_per_successful_outcome
FROM hr_employee_data
GROUP BY training_program_name
ORDER BY cost_per_successful_outcome ASC;


--15. Which employees show multiple warning indicators based on low engagement,
--low satisfaction, poor work-life balance, and low employee ratings, and therefore
--require higher HR attention?

SELECT
    employee_id,
    title,
    department_type,
    engagement_score,
    satisfaction_score,
    work_life_balance_score,
    current_employee_rating,
    (
        CASE
            WHEN engagement_score <= 2 THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN satisfaction_score <= 2 THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN work_life_balance_score <= 2 THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN current_employee_rating <= 2 THEN 1
            ELSE 0
        END
    ) AS warning_indicator_count
FROM hr_employee_data
WHERE
    (
        CASE
            WHEN engagement_score <= 2 THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN satisfaction_score <= 2 THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN work_life_balance_score <= 2 THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN current_employee_rating <= 2 THEN 1
            ELSE 0
        END
    ) >= 3
ORDER BY warning_indicator_count DESC;