
-- ============================================================
-- HR Employee Analytics & Training Effectiveness
-- Database: PostgreSQL
-- Table: hr_employee_data
-- ============================================================


-- 1. What is the total number of employees in the organization?

SELECT
    COUNT(*) AS total_employees
FROM hr_employee_data;


-- 2. How many employees are working in each department?

SELECT
    department_type,
    COUNT(*) AS total_employees
FROM hr_employee_data
GROUP BY department_type
ORDER BY total_employees DESC;


-- 3. What is the overall average employee satisfaction score?

SELECT
    ROUND(AVG(satisfaction_score), 2) AS avg_satisfaction_score
FROM hr_employee_data;


-- 4. How many employees fall into each performance score category?

SELECT
    performance_score,
    COUNT(*) AS total_employees
FROM hr_employee_data
GROUP BY performance_score
ORDER BY total_employees DESC;


-- 5. What is the average training cost for each training program?

SELECT
    training_program_name,
    ROUND(AVG(training_cost), 2) AS avg_training_cost
FROM hr_employee_data
GROUP BY training_program_name
ORDER BY avg_training_cost DESC;


-- 6. What are the average employee engagement and satisfaction
--    scores for each department?

SELECT
    department_type,
    ROUND(AVG(engagement_score), 2) AS avg_engagement,
    ROUND(AVG(satisfaction_score), 2) AS avg_satisfaction
FROM hr_employee_data
GROUP BY department_type;


-- 7. How does the average employee rating differ across
--    different employee types?

SELECT
    employee_type,
    ROUND(AVG(current_employee_rating), 2) AS avg_employee_rating
FROM hr_employee_data
GROUP BY employee_type
ORDER BY avg_employee_rating DESC;


-- 8. What percentage of employees fall into each training
--    outcome category?

SELECT
    training_outcome,
    COUNT(*) AS total_employees,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM hr_employee_data
GROUP BY training_outcome
ORDER BY total_employees DESC;


-- 9. How is the company's workforce distributed across
--    different age groups?

SELECT
    CASE
        WHEN age < 25 THEN 'Under 25'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 44 THEN '35-44'
        WHEN age BETWEEN 45 AND 54 THEN '45-54'
        ELSE '55+'
    END AS age_group,
    COUNT(*) AS total_employees
FROM hr_employee_data
GROUP BY
    CASE
        WHEN age < 25 THEN 'Under 25'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 44 THEN '35-44'
        WHEN age BETWEEN 45 AND 54 THEN '45-54'
        ELSE '55+'
    END
ORDER BY total_employees DESC;


-- 10. Which departments have the lowest work-life balance scores,
--     and how do their satisfaction and engagement scores compare?

SELECT
    department_type,
    ROUND(AVG(work_life_balance_score), 2) AS avg_work_life_balance,
    ROUND(AVG(satisfaction_score), 2) AS avg_satisfaction,
    ROUND(AVG(engagement_score), 2) AS avg_engagement
FROM hr_employee_data
GROUP BY department_type
ORDER BY avg_work_life_balance ASC;


-- 11. How do departments rank based on their average
--     employee satisfaction scores?

SELECT
    department_type,
    ROUND(AVG(satisfaction_score), 2) AS avg_satisfaction,
    RANK() OVER (
        ORDER BY AVG(satisfaction_score) DESC
    ) AS satisfaction_rank
FROM hr_employee_data
GROUP BY department_type
ORDER BY satisfaction_rank;


-- 12. Which departments have an average employee rating
--     below the overall company average?

SELECT
    department_type,
    ROUND(AVG(current_employee_rating), 2) AS avg_department_rating,
    ROUND(
        (
            SELECT AVG(current_employee_rating)
            FROM hr_employee_data
        ),
        2
    ) AS avg_company_rating
FROM hr_employee_data
GROUP BY department_type
HAVING AVG(current_employee_rating) < (
    SELECT AVG(current_employee_rating)
    FROM hr_employee_data
)
ORDER BY avg_department_rating ASC;


-- 13. Which training programs have the highest success rate
--     when successful training is defined as Passed or Completed?

WITH training_success AS (
    SELECT
        training_program_name,
        COUNT(*) AS total_trainings,
        SUM(
            CASE
                WHEN training_outcome IN ('Passed', 'Completed') THEN 1
                ELSE 0
            END
        ) AS successful_trainings,
        ROUND(
            SUM(
                CASE
                    WHEN training_outcome IN ('Passed', 'Completed') THEN 1
                    ELSE 0
                END
            ) * 100.0 / COUNT(*),
            2
        ) AS success_rate
    FROM hr_employee_data
    GROUP BY training_program_name
)

SELECT
    training_program_name,
    total_trainings,
    successful_trainings,
    success_rate
FROM training_success
WHERE success_rate = (
    SELECT MAX(success_rate)
    FROM training_success
);


-- 14. Which training programs are the most cost-efficient
--     based on the training cost per successful outcome?

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
HAVING SUM(
    CASE
        WHEN training_outcome IN ('Passed', 'Completed') THEN 1
        ELSE 0
    END
) > 0
ORDER BY cost_per_successful_outcome ASC;


-- 15. Which employees show multiple warning indicators based on
--     low engagement, low satisfaction, poor work-life balance,
--     and low employee ratings, and therefore require higher
--     HR attention?

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

