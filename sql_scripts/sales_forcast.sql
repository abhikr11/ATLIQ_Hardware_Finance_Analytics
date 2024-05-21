## Supply chain analytics

-- Absolute Error = |Predicted Value − Actual Value|

## Module: Create a Helper Table which contains both sold quantity and forcast quantity
SELECT * FROM gdb0041.fact_sales_monthly;
SELECT * FROM gdb0041.fact_forecast_monthly;

SELECT COUNT(*) FROM gdb0041.fact_sales_monthly;
-- 1425706

SELECT COUNT(*) FROM gdb0041.fact_forecast_monthly;
-- 1885941

SELECT 1885941-1425706;
-- There is difference of 460235 rows between sold quantity and forcast quantity table
-- Full Join both table

-- Create seperate table which contains both sold and forcast quantity 
-- fact actual estimate

CREATE TABLE fact_act_est
(
SELECT
	s.*,
    f.forecast_quantity
FROM fact_sales_monthly AS s
LEFT JOIN fact_forecast_monthly AS f
USING (date, customer_code, product_code)

UNION

SELECT
	f.date,
    f.fiscal_year,
    f.product_code,
    f.customer_code,
    s.sold_quantity,
    f.forecast_quantity
FROM fact_forecast_monthly AS f
LEFT JOIN fact_sales_monthly AS s
USING (date, customer_code, product_code)
);

-- FETCH fact_act_est table
SELECT * FROM gdb0041.fact_act_est;

-- Update table sold_quantity = 0 where it is NULL
UPDATE fact_act_est
SET sold_quantity = 0
WHERE sold_quantity IS NULL;

-- Update table forcast_quantity = 0 where it is NULL
UPDATE fact_act_est
SET forecast_quantity = 0
WHERE forecast_quantity IS NULL;


## Database Triggers
-- As fact_act_est table is derived from fact_sales_monthly and fact_forcast_monthly
-- So we want to automatically add data in fact_act_est when ever we add data in fact_sales_monthly table
-- For this we will use "Trigger" in fact_sales_monthly table
-- We want to add data into fact_act_est table after we finished inserting data into fact_sales_monthly
-- Trigger > After Insert
-- Use NEW.column_name to add values
/*
CREATE DEFINER=`root`@`localhost` TRIGGER `fact_sales_monthly_AFTER_INSERT` AFTER INSERT ON `fact_sales_monthly` FOR EACH ROW BEGIN
	INSERT INTO fact_act_est
		(date, product_code, customer_code, sold_quantity)
	VALUES(
		NEW.date,
        NEW.product_code,
        NEW.customer_code,
        NEW.sold_quantity
	)
    ON DUPLICATE KEY UPDATE 
		sold_quantity = VALUES(sold_quantity);
END
*/

-- Show all Triggers in database
SHOW TRIGGERS;

-- Insert a record into fact_sales_monthly table
INSERT INTO fact_sales_monthly
	(date, product_code, customer_code, sold_quantity)
VALUES
	("2025-01-01", "CHECK", 100, 50);
    
-- Check inserted row
SELECT * FROM fact_sales_monthly
WHERE customer_code = 100;

-- As we have inserted values in fact_sales_monthly table, this must have inserted into fact_act_est
SELECT * FROM fact_act_est
WHERE customer_code = 100;
-- Due to Trigger, fact_act_est table automaticaly updated

-- Write Trigger to automatically insert data into fact_act_est where ever data is inserted into fact_forcast_monthly
/*
CREATE DEFINER=`root`@`localhost` TRIGGER `fact_forecast_monthly_AFTER_INSERT` AFTER INSERT ON `fact_forecast_monthly` FOR EACH ROW BEGIN
	INSERT INTO fact_act_est
		(date, product_code, customer_code, forecast_quantity)
	VALUES(
		NEW.date,
        NEW.product_code,
        NEW.customer_code,
        NEW.forecast_quantity
	)
    ON DUPLICATE KEY UPDATE 
		forecast_quantity = VALUES(forecast_quantity);
END
*/

-- Insert a record into fact_forecast_monthly table
INSERT INTO fact_forecast_monthly
	(date, product_code, customer_code, forecast_quantity)
VALUES
	("2025-01-01", "CHECK", 100, 40);
    
-- Check inserted row
SELECT * FROM fact_forecast_monthly
WHERE customer_code = 100;

-- As we have inserted values in fact_forecast_monthly table, this must have inserted into fact_act_est
SELECT * FROM fact_act_est
WHERE customer_code = 100;

-- -------------------------------------------------------------------------------------------------------------------

## Get Forecast Accuracy Report for given Fiscal Year
-- Forecast accuracy report using cte

WITH forecast_error_table AS(
	SELECT 
		e.customer_code,
		c.customer AS customer_name,
		c.market,
		SUM(e.sold_quantity) AS total_sold_qty,
		SUM(e.forecast_quantity) AS total_forecast_qty,
		SUM(e.forecast_quantity - e.sold_quantity) AS net_error,
		ROUND(SUM(e.forecast_quantity - e.sold_quantity)*100/ SUM(e.forecast_quantity), 2) AS net_error_pct,
		SUM(ABS(e.forecast_quantity - e.sold_quantity)) AS abs_error,
		ROUND(SUM(ABS(e.forecast_quantity - e.sold_quantity))*100/ SUM(e.forecast_quantity), 2) AS abs_error_pct
	FROM fact_act_est AS e
	JOIN dim_customer AS c
	USING(customer_code)
	WHERE e.fiscal_year = 2021
	GROUP BY e.customer_code
)

SELECT
	*,
    IF(abs_error_pct > 100, 0, 100 - abs_error_pct) AS forecast_accuracy
FROM forecast_error_table
ORDER BY forecast_accuracy DESC;

-- CREATE STORED PROCEDURE to get forecast acuuracy
/*
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_forecast_accuracy`(
						IN in_fiscal_year INT
)
BEGIN
	WITH forecast_error_table AS(
		SELECT 
			e.customer_code,
			c.customer AS customer_name,
			c.market,
			SUM(e.sold_quantity) AS total_sold_qty,
			SUM(e.forecast_quantity) AS total_forecast_qty,
			SUM(e.forecast_quantity - e.sold_quantity) AS net_error,
			ROUND(SUM(e.forecast_quantity - e.sold_quantity)*100/ SUM(e.forecast_quantity), 2) AS net_error_pct,
			SUM(ABS(e.forecast_quantity - e.sold_quantity)) AS abs_error,
			ROUND(SUM(ABS(e.forecast_quantity - e.sold_quantity))*100/ SUM(e.forecast_quantity), 2) AS abs_error_pct
		FROM fact_act_est AS e
		JOIN dim_customer AS c
		USING(customer_code)
		WHERE e.fiscal_year = in_fiscal_year
		GROUP BY e.customer_code
	)

	SELECT
		*,
		IF(abs_error_pct > 100, 0, 100 - abs_error_pct) AS forecast_accuracy
	FROM forecast_error_table
	ORDER BY forecast_accuracy DESC;
END
*/

-- CALL get_forecast_accuracy
call gdb0041.get_forecast_accuracy(2021);

-- -------------------------------------------------------------------------------------------------------------------------------
## TEMPORARY TABLE
/*
Temporary Tables: Temporary tables are used to store intermediate results temporarily during a session. 
They are particularly useful when you need to store a large set of data or when you need to perform multiple operations on the data.
Valid for current session

CTEs: Common Table Expressions are used to define a temporary result set within a query. 
They are helpful for improving the readability and maintainability of complex queries by breaking them into smaller, more manageable parts.
Only valid within a query
*/

-- Forecast accuracy report using temporary table (It exists for the entire session)
drop table if exists forecast_error_table;

CREATE TEMPORARY TABLE forecast_error_table
	SELECT 
		e.customer_code,
		c.customer AS customer_name,
		c.market,
		SUM(e.sold_quantity) AS total_sold_qty,
		SUM(e.forecast_quantity) AS total_forecast_qty,
		SUM(e.forecast_quantity - e.sold_quantity) AS net_error,
		ROUND(SUM(e.forecast_quantity - e.sold_quantity)*100/ SUM(e.forecast_quantity), 2) AS net_error_pct,
		SUM(ABS(e.forecast_quantity - e.sold_quantity)) AS abs_error,
		ROUND(SUM(ABS(e.forecast_quantity - e.sold_quantity))*100/ SUM(e.forecast_quantity), 2) AS abs_error_pct
	FROM fact_act_est AS e
	JOIN dim_customer AS c
	USING(customer_code)
	WHERE e.fiscal_year = 2021
	GROUP BY e.customer_code;
    
-- This will create a tem table in the memory and we can use this any time within the current session
SELECT
	*,
    IF(abs_error_pct > 100, 0, 100 - abs_error_pct) AS forecast_accuracy
FROM forecast_error_table
ORDER BY forecast_accuracy DESC;


## The supply chain business manager wants to see which customers’ forecast accuracy has dropped from 2020 to 2021. 
## Provide a complete report with these columns: customer_code, customer_name, market, forecast_accuracy_2020, forecast_accuracy_2021

-- Using CTE
WITH 
	forecast_error_2020 AS(
		SELECT 
			e.customer_code,
			c.customer AS customer_name,
			c.market,
			SUM(e.sold_quantity) AS total_sold_qty,
			SUM(e.forecast_quantity) AS total_forecast_qty,
			SUM(e.forecast_quantity - e.sold_quantity) AS net_error,
			ROUND(SUM(e.forecast_quantity - e.sold_quantity)*100/ SUM(e.forecast_quantity), 2) AS net_error_pct,
			SUM(ABS(e.forecast_quantity - e.sold_quantity)) AS abs_error,
			ROUND(SUM(ABS(e.forecast_quantity - e.sold_quantity))*100/ SUM(e.forecast_quantity), 2) AS abs_error_pct
		FROM fact_act_est AS e
		JOIN dim_customer AS c
		USING(customer_code)
		WHERE e.fiscal_year = 2020
		GROUP BY e.customer_code
	),
	forecast_error_2021 AS(
		SELECT 
			e.customer_code,
			c.customer AS customer_name,
			c.market,
			SUM(e.sold_quantity) AS total_sold_qty,
			SUM(e.forecast_quantity) AS total_forecast_qty,
			SUM(e.forecast_quantity - e.sold_quantity) AS net_error,
			ROUND(SUM(e.forecast_quantity - e.sold_quantity)*100/ SUM(e.forecast_quantity), 2) AS net_error_pct,
			SUM(ABS(e.forecast_quantity - e.sold_quantity)) AS abs_error,
			ROUND(SUM(ABS(e.forecast_quantity - e.sold_quantity))*100/ SUM(e.forecast_quantity), 2) AS abs_error_pct
		FROM fact_act_est AS e
		JOIN dim_customer AS c
		USING(customer_code)
		WHERE e.fiscal_year = 2021
		GROUP BY e.customer_code
	),
	forecast_accuray_20_21 AS(
		SELECT 
			a.customer_code,
			a.customer_name,
			a.market,
			IF(a.abs_error_pct > 100, 0, 100 - a.abs_error_pct) AS forecast_accuracy_2020,
			IF(b.abs_error_pct > 100, 0, 100 - b.abs_error_pct) AS forecast_accuracy_2021
		FROM forecast_error_2020 AS a
		JOIN forecast_error_2021 AS b
		USING(customer_code)
	)
SELECT * FROM forecast_accuray_20_21
WHERE forecast_accuracy_2020 > forecast_accuracy_2021
ORDER BY forecast_accuracy_2020 DESC;


-- Using TEMPORARY TABLE
# step 1: Get forecast accuracy of FY 2020 and store that in a temporary table
DROP TABLE IF EXISTS forecast_accuracy_2020;
CREATE TEMPORARY TABLE forecast_accuracy_2020
	WITH forecast_error_2020 AS(
		SELECT 
			e.customer_code,
			c.customer AS customer_name,
			c.market,
			SUM(e.sold_quantity) AS total_sold_qty,
			SUM(e.forecast_quantity) AS total_forecast_qty,
			SUM(e.forecast_quantity - e.sold_quantity) AS net_error,
			ROUND(SUM(e.forecast_quantity - e.sold_quantity)*100/ SUM(e.forecast_quantity), 2) AS net_error_pct,
			SUM(ABS(e.forecast_quantity - e.sold_quantity)) AS abs_error,
			ROUND(SUM(ABS(e.forecast_quantity - e.sold_quantity))*100/ SUM(e.forecast_quantity), 2) AS abs_error_pct
		FROM fact_act_est AS e
		JOIN dim_customer AS c
		USING(customer_code)
		WHERE e.fiscal_year = 2020
		GROUP BY e.customer_code
        )
	SELECT
		*,
		IF(abs_error_pct > 100, 0, 100 - abs_error_pct) AS forecast_accuracy_2020
	FROM forecast_error_2020
	ORDER BY forecast_accuracy_2020 DESC;

# step 2: Get forecast accuracy of FY 2021 and store that in a temporary table
DROP TABLE IF EXISTS forecast_accuracy_2021;
CREATE TEMPORARY TABLE forecast_accuracy_2021
	WITH forecast_error_2021 AS(
		SELECT 
			e.customer_code,
			c.customer AS customer_name,
			c.market,
			SUM(e.sold_quantity) AS total_sold_qty,
			SUM(e.forecast_quantity) AS total_forecast_qty,
			SUM(e.forecast_quantity - e.sold_quantity) AS net_error,
			ROUND(SUM(e.forecast_quantity - e.sold_quantity)*100/ SUM(e.forecast_quantity), 2) AS net_error_pct,
			SUM(ABS(e.forecast_quantity - e.sold_quantity)) AS abs_error,
			ROUND(SUM(ABS(e.forecast_quantity - e.sold_quantity))*100/ SUM(e.forecast_quantity), 2) AS abs_error_pct
		FROM fact_act_est AS e
		JOIN dim_customer AS c
		USING(customer_code)
		WHERE e.fiscal_year = 2021
		GROUP BY e.customer_code
        )
	SELECT
		*,
		IF(abs_error_pct > 100, 0, 100 - abs_error_pct) AS forecast_accuracy_2021
	FROM forecast_error_2021
	ORDER BY forecast_accuracy_2021 DESC;

# step 3: Join forecast accuracy tables for 2020 and 2021 using a customer_code
SELECT
	f_20.customer_code,
    f_20.customer_name,
    f_20.market,
    f_20.forecast_accuracy_2020,
    f_21.forecast_accuracy_2021
FROM forecast_accuracy_2020 AS f_20
JOIN forecast_accuracy_2021 AS f_21
USING(customer_code)
WHERE f_20.forecast_accuracy_2020 > f_21.forecast_accuracy_2021
ORDER BY f_20.forecast_accuracy_2020 DESC;