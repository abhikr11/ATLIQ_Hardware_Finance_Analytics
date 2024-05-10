-- ATLIQ Hardware: Finance Analytics

-- Analysis: 1
## Generate report of individual product sales(aggregated on a monthly basis at the product code level) 
## for Croma India customer for FY=2021. Required fields:
-- Month
-- Product Name
-- Varient
-- Sold Quantity
-- Gross Price Per Item
-- Gross Price Total

# Step 1: Get Croma India Customer Code
SELECT * FROM dim_customer
WHERE customer LIKE "%croma%" AND market = "%India%";

-- croma customer code = 90002002

# Step 2: Get sales for Fisical Year 2021
-- As FY 2021 for AtliQ starts in Sep 2020 (2020-09-01) to Aug 2021 (2021-09-01)

 SELECT * FROM fact_sales_monthly
 WHERE 
	YEAR(DATE_ADD(date, INTERVAL 4 MONTH)) = 2021
    AND customer_code = 90002002
ORDER BY date;

-- define a function to automatically get fiscal year
SELECT * FROM fact_sales_monthly
WHERE
	get_fiscal_year(date) = 2021 AND
    customer_code = 90002002
ORDER BY date;

# Step 3: Get Product Name and Varient from Product Table By Using JOIN
SELECT
	s.date,
    s.product_code,
    p.product,
    p.variant,
    s.sold_quantity
FROM fact_sales_monthly AS s
JOIN dim_product AS p
	ON s.product_code = p.product_code
WHERE
	get_fiscal_year(date) = 2021 AND
    customer_code = 90002002
ORDER BY date;

# Step 4: Get Gross price
SELECT
	s.date,
    s.product_code,
    g.fiscal_year,
    p.product,
    p.variant,
    s.sold_quantity,
    g.gross_price
FROM fact_sales_monthly AS s
JOIN dim_product AS p
	ON s.product_code = p.product_code
JOIN fact_gross_price AS g
	ON g.product_code = s.product_code AND
    g.fiscal_year = get_fiscal_year(s.date)
WHERE
	get_fiscal_year(date) = 2021 AND
    customer_code = 90002002
ORDER BY date;

# Step 5: Cal Total Gross Price (Qty * gross_price)
SELECT
	MONTHNAME(s.date) AS month,
    p.product,
    p.variant,
    s.sold_quantity,
    g.gross_price AS gross_price_per_item,
    ROUND(s.sold_quantity * g.gross_price, 2) AS total_gross_price
FROM fact_sales_monthly AS s
JOIN dim_product AS p
	ON s.product_code = p.product_code
JOIN fact_gross_price AS g
	ON g.product_code = s.product_code AND
    g.fiscal_year = get_fiscal_year(s.date)
WHERE
	get_fiscal_year(date) = 2021 AND
    customer_code = 90002002
ORDER BY date;

-- -------------------------------------------------------------------------------------------------------

-- Analysis: 2
## Make report for croma monthly sales
SELECT 
	s.date,
    SUM(s.sold_quantity * gp.gross_price) AS total_gross_price
FROM fact_sales_monthly AS s
JOIN fact_gross_price AS gp
	ON s.product_code = gp.product_code AND
    get_fiscal_year(s.date) = gp.fiscal_year
WHERE customer_code = 90002002
GROUP BY s.date
ORDER BY date;

-- Generate Stored Procedure to create monthly sales report for given customer
-- Input: customer_code

-- Created Stored Procedure (monthly_total_gross_sales)
-- Call monthly_total_gross_sales
# croma monthly sales
call gdb0041.monthly_total_gross_sales(90002002);

# Flipkart monthly sales
-- Get Flipkart customer code for Indian market
select * from dim_customer
where customer like "%Flipkart%" and market ="India";        -- 90002009

call gdb0041.monthly_total_gross_sales(90002009);

-- ----------------------------------------------------------------------------------------------------

-- Analysis: 3
## What if there are more than one customer code for same customer
-- Input: list of customer_code

#Amazon monthly sales
select * from dim_customer
where customer like "%amazon%" and
	market like "%india%";

-- Amazon customer codes for India are 90002008 and 90002016

SELECT 
	s.date,
    SUM(s.sold_quantity * gp.gross_price) AS total_gross_price
FROM fact_sales_monthly AS s
JOIN fact_gross_price AS gp
	ON gp.fiscal_year = get_fiscal_year(s.date) AND
    gp.product_code = s.product_code
WHERE customer_code IN (90002008,90002016)
GROUP BY s.date
ORDER BY date;

-- Created Stored Procedure (monthly_gross_sales) for list of cus_code
-- Call monthly_gross_sales for Amazon monthly sales
call gdb0041.monthly_gross_sales('90002008,90002016');

-- ----------------------------------------------------------------------------------------------------------

-- Analysis: 4
## Generate a yearly report for Croma India where there are two columns
#1. Fiscal Year
#2. Total Gross Sales amount In that year from Croma

SELECT 
	gp.fiscal_year,
    ROUND(SUM(s.sold_quantity * gp.gross_price), 2) AS total_yearly_gross_price
FROM fact_sales_monthly AS s
JOIN fact_gross_price AS gp
	ON s.product_code=gp.product_code AND
    get_fiscal_year(s.date) = gp.fiscal_year
WHERE customer_code = 90002002
GROUP BY gp.fiscal_year;

-- Generate a yearly report for "Atliq e Store" for all market
# Get customer code for "Atliq e Store"
SELECT customer_code, customer, market FROM dim_customer
WHERE customer LIKE "%Atliq e Store%";

# use cte to get customer codes
WITH cte1 AS(
	SELECT customer_code FROM dim_customer
	WHERE customer LIKE "%Atliq e Store%")
-- get yearly sales by using cte table
SELECT 
	gp.fiscal_year,
    ROUND(SUM(s.sold_quantity * gp.gross_price), 2) AS total_yearly_gross_price
FROM fact_sales_monthly AS s
JOIN fact_gross_price AS gp
	ON s.product_code=gp.product_code AND
    get_fiscal_year(s.date) = gp.fiscal_year
WHERE
	s.customer_code IN (SELECT * FROM cte1)
GROUP BY gp.fiscal_year;

-- --------------------------------------------------------------------------------------------------------

-- Analysis: 5
## Stored Procedure for Market Badge
-- Create a stored proc that can determine the market badge based on the following logic
-- If total sold quantity > 5 million that market is considered Gold else Silver
-- Input : market, fiscal year
-- Output : market badge

# Get market badge for Indian market and fiscal year 2020
SELECT
    market,
    CASE
		WHEN SUM(sold_quantity) > 5000000 THEN "Gold"
        ELSE "Silver"
	END AS market_badge
FROM fact_sales_monthly AS s
JOIN dim_customer AS c
	ON s.customer_code = c.customer_code
WHERE c.market = "India"
	AND get_fiscal_year(s.date) =2020
GROUP BY market ;

# Create Stored Procedure to get market badge
-- If market is not provided as input then make "India" as default market

# CALL get_market_badge India/2020
set @out_market_badge = '0';
set @out_total_sold_qty = 0;
call gdb0041.get_market_badge('india', 2020, @out_market_badge, @out_total_sold_qty);
select @out_market_badge, @out_total_sold_qty;

-- -----------------------------------------------------------------------------------------------------

-- Analysis: 6
## Create a view for gross sales.
 
-- It should have the following columns:
-- date, fiscal_year, customer_code, customer, market, product_code, product, variant,
-- sold_quanity, gross_price_per_item, gross_price_total
CREATE VIEW gross_sales AS
		SELECT
			s.date,
			s.fiscal_year,
			s.customer_code,
			c.customer,
			c.market,
			s.product_code,
			p.product,
			p.variant,
			s.sold_quantity,
			gp.gross_price AS gross_price_per_item,
			(s.sold_quantity * gp.gross_price) AS gross_price_total
		FROM fact_sales_monthly AS s
		JOIN fact_gross_price AS gp
			ON s.product_code = gp.product_code
			AND s.fiscal_year = gp.fiscal_year
		JOIN dim_customer AS c
			ON s.customer_code =c.customer_code
		JOIN dim_product AS p
			ON s.product_code = p.product_code;

-- -----------------------------------------------------------------------------------------------------

-- Analysis: 7
## Performance Improvement of SQL Query

EXPLAIN ANALYZE
SELECT
	s.date,
    s.product_code,
    g.fiscal_year,
    p.product,
    p.variant,
    s.sold_quantity,
    g.gross_price,
    ROUND(s.sold_quantity * g.gross_price, 2) AS total_gross_price,
    pre.pre_invoice_discount_pct
FROM fact_sales_monthly AS s
JOIN dim_product AS p
	ON s.product_code = p.product_code
JOIN fact_gross_price AS g
	ON g.product_code = s.product_code AND
    g.fiscal_year = get_fiscal_year(s.date)
JOIN fact_pre_invoice_deductions AS pre
	ON s.customer_code = pre.customer_code
    AND get_fiscal_year(s.date) = pre.fiscal_year
WHERE
	get_fiscal_year(date) = 2021
ORDER BY s.date;

-- Took 27 sec to execute

-- As we are calling get_fiscal_year function again and again on each row, so it took more time to execute
-- Reduce the time taken to execute the querry

-- Performance Improvement: 1
-- Create a lookup table which contains date and fiscal year then join with date and get fiscal year
SELECT
	s.date,
    s.product_code,
    dt.fiscal_year,
    g.fiscal_year,
    p.product,
    p.variant,
    s.sold_quantity,
    g.gross_price,
    ROUND(s.sold_quantity * g.gross_price, 2) AS total_gross_price,
    pre.pre_invoice_discount_pct
FROM fact_sales_monthly AS s
JOIN dim_date_fiscal_year AS dt
	ON s.date = dt.date
JOIN dim_product AS p
	ON s.product_code = p.product_code
JOIN fact_gross_price AS g
	ON g.product_code = s.product_code AND
    g.fiscal_year = dt.fiscal_year
JOIN fact_pre_invoice_deductions AS pre
	ON s.customer_code = pre.customer_code
    AND dt.fiscal_year = pre.fiscal_year
WHERE
	dt.fiscal_year = 2021
ORDER BY s.date;

-- Took 10sec

-- Performance Improvement: 2
-- Again Performance can be reduced by adding extra column in fact_sales_monthly for fiscal year
-- Add generated column in fact_sales_monthly table to get fiscal year from date
SELECT
	s.date,
    s.product_code,
    s.fiscal_year,
    p.product,
    p.variant,
    s.sold_quantity,
    g.gross_price,
    ROUND(s.sold_quantity * g.gross_price, 2) AS total_gross_price,
    pre.pre_invoice_discount_pct
FROM fact_sales_monthly AS s
JOIN dim_product AS p
	ON s.product_code = p.product_code
JOIN fact_gross_price AS g
	ON g.product_code = s.product_code AND
    g.fiscal_year = s.fiscal_year
JOIN fact_pre_invoice_deductions AS pre
	ON s.customer_code = pre.customer_code
    AND s.fiscal_year = pre.fiscal_year
WHERE
	s.fiscal_year = 2021
ORDER BY s.date;

-- Took 4sec

-- -----------------------------------------------------------------------------------------------------

-- Analysis: 8
## Calculate Net Sales Amount
-- Net Sales Amount = (Total_Gross_Sales - Pre_Invoice_Deduction - Post_Invoice_Deduction)

-- Step: 1 Join pre invoice discounts table
-- Store sales_pre_invoice_discount result as a VIEW
CREATE VIEW sales_pre_invoice_discounts AS
	SELECT
		s.date,
		s.fiscal_year,
        s.customer_code,
		s.product_code,
		c.market,
		p.product,
		p.variant,
		s.sold_quantity,
		g.gross_price AS gross_price_per_item,
		ROUND(s.sold_quantity * g.gross_price, 2) AS total_gross_price,
		pre.pre_invoice_discount_pct
	FROM fact_sales_monthly AS s
	JOIN dim_customer AS c
		ON s.customer_code = c.customer_code
	JOIN dim_product AS p
		ON s.product_code = p.product_code
	JOIN fact_gross_price AS g
		ON g.product_code = s.product_code AND
		g.fiscal_year = s.fiscal_year
	JOIN fact_pre_invoice_deductions AS pre
		ON s.customer_code = pre.customer_code
		AND s.fiscal_year = pre.fiscal_year
	ORDER BY s.date;

-- fetch from view
SELECT * FROM sales_pre_invoice_discounts;

-- Step: 2 Get net invoice sales (total gross price -  pre invoice discounts price)
#net_invoice_sales
SELECT 
	*,
    (1- pre_invoice_discount_pct) * total_gross_price AS net_invoice_sale
FROM sales_pre_invoice_discounts;

-- Step: 3 JOIN post_invoice_discount table with it and create view for 'sales_post_invoice_discounts'
CREATE VIEW sales_post_invoice_discounts AS
		SELECT
			pre.date, pre.fiscal_year, pre.customer_code, pre.product_code, pre.product, pre.variant,
			pre.market, pre.sold_quantity, pre.gross_price_per_item, 
			pre.total_gross_price,
			pre.pre_invoice_discount_pct,
			(1- pre_invoice_discount_pct) * total_gross_price AS net_invoice_sale,
			(pos.discounts_pct + pos.other_deductions_pct) AS post_invoice_discount_pct
		FROM sales_pre_invoice_discounts AS pre
		JOIN fact_post_invoice_deductions AS pos
			ON pre.date = pos.date
			AND pre.customer_code = pos.customer_code 
			AND pre.product_code = pos.product_code;
            
-- fetch from view
SELECT * FROM sales_post_invoice_discounts;

-- Step: 3 Get Net Sale
SELECT 
	*,
    (1- post_invoice_discount_pct) * net_invoice_sale AS net_sale
FROM sales_post_invoice_discounts;

#create VIEW for net_sale
CREATE VIEW net_sales AS 
		SELECT 
			*,
			(1- post_invoice_discount_pct) * net_invoice_sale AS net_sale
		FROM sales_post_invoice_discounts;
        
-- -----------------------------------------------------------------------------------------------------

-- Analysis: 9
## Top Market and Customer by Net Sales

## Create Stored Procedure for top Market for given fiscal year by "net_sale"
-- Input Parameter: fiscal year, top n market
-- Get net sales in Million
SELECT
	market,
    ROUND(SUM(net_sale) / 1000000, 2) AS net_sale_million
FROM net_sales
WHERE fiscal_year = 2021
GROUP BY market
ORDER BY net_sale_million DESC
LIMIT 5;

-- CREATED STORED PROCEDURE "get_top_market_by_netsales"
-- Input: Top n, Fiscal Year

-- CALL "get_top_market_by_netsales"
call gdb0041.get_top_market_by_netsales(3, 2021);


## Top Customer for given fiscal year by "net_sale" and "Market"
SELECT
	c.customer,
    ROUND(SUM(net_sale) / 1000000, 2) AS net_sale_million
FROM net_sales AS s
JOIN dim_customer AS c
	ON s.customer_code =c.customer_code
WHERE fiscal_year = 2021
	AND s.market = "india"
GROUP BY c.customer
ORDER BY net_sale_million DESC
LIMIT 5;

-- CREATED STORED PROCEDURE "get_top_customer_by_netsales" 
-- Input: Market, Fiscal Year, Top n

-- Call "get_top_customer_by_netsales"
call gdb0041.get_top_customer_by_netsales('INDIA', 2021, 3);

-- -----------------------------------------------------------------------------------------------------

-- Analysis: 10
## Percentage share of net sales for each customer within their respective region for 2021

WITH cte AS(
	SELECT
		c.region,
		c.customer,
		ROUND(SUM(net_sale) / 1000000, 2) AS net_sale_million
	FROM net_sales AS s
	JOIN dim_customer AS c
		ON s.customer_code =c.customer_code
	WHERE fiscal_year = 2021
	GROUP BY c.region,c.customer
    )
    
SELECT
	*,
    net_sale_million * 100 / SUM(net_sale_million) OVER( PARTITION BY region) AS pct_share_by_region 
FROM cte
ORDER BY region, pct_share_by_region DESC;


-- -----------------------------------------------------------------------------------------------------

-- Analysis: 11
## Get Top n product in each divison by their sold quantity in given FY

WITH cte AS (
	SELECT
		p.division,
		p.product,
		SUM(s.sold_quantity) AS total_quantity
	FROM fact_sales_monthly AS s
	JOIN dim_product AS p
		ON s.product_code = p.product_code
	WHERE s.fiscal_year = 2021
	GROUP BY p.division, p.product
    )
SELECT * FROM 
			(SELECT 
				*,
				DENSE_RANK() OVER(PARTITION BY division ORDER BY total_quantity DESC) AS dense_rnk
			FROM cte) AS d_table
WHERE dense_rnk <=3;

-- CREATED STORED PROCEDURE "get_top_n_product_per_divison_by_sold_quantity" 
-- Input: Fiscal Year, Top n

-- CALL "get_top_n_product_per_divison_by_sold_quantity"
call gdb0041.get_top_n_product_per_divison_by_sold_quantity(2021, 3);


-- -----------------------------------------------------------------------------------------------------

-- Analysis: 12
## Get Forecast Accuracy Report for given Fiscal Year

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


-- ------------------------------------------------------------------------------------------------------------------------------------

-- Analysis: 13
## The supply chain business manager wants to see which customers’ forecast accuracy has dropped from 2020 to 2021. 
## Provide a complete report with these columns: customer_code, customer_name, market, forecast_accuracy_2020, forecast_accuracy_2021

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