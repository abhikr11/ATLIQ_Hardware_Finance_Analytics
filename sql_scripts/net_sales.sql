# Calculate Net Sales Amount
-- Net Sales Amount = (Total_Gross_Sales - Pre_Invoice_Deduction - Post_Invoice_Deduction)

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

-- Took 30sec

# This took so long to run, there is need to Performance Improvment
-- It took time becz we are calling get_fisical_year fn again and again instead we can make
-- table which can store date and fiscal year

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

# Again Performance can be reduced by adding extra column in fact_sales_monthly for fiscal year
SELECT
	s.date,
    s.product_code,
    s.fiscal_year,
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
    g.fiscal_year = s.fiscal_year
JOIN fact_pre_invoice_deductions AS pre
	ON s.customer_code = pre.customer_code
    AND s.fiscal_year = pre.fiscal_year
WHERE
	s.fiscal_year = 2021
ORDER BY s.date;

-- Took 4sec

# Get the net_invoice_sales amount using the CTE's
WITH cte AS (
	SELECT
		s.date,
		s.fiscal_year,
        s.customer_code,
		s.product_code,
		c.market,
		p.product,
		p.variant,
		s.sold_quantity,
		g.gross_price,
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
	ORDER BY s.date
    )
SELECT
	*,
    (1- pre_invoice_discount_pct) * total_gross_price AS net_invoice_sale
FROM cte;

-- Instead of using cte we can use VIEW to avoid any mistake, VIEW makes querry simpler, 
-- easy in giving access to others if we donot want to share whole database

#Store sales_pre_invoice_discount result as a VIEW
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

#fetch from view
SELECT * FROM sales_pre_invoice_discounts;

#net_invoice_sales
SELECT 
	*,
    (1- pre_invoice_discount_pct) * total_gross_price AS net_invoice_sale
FROM sales_pre_invoice_discounts;


#JOIN post_invoice_discount table with it and create view for 'sales_post_invoice_discounts'

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
    
# get net_sale
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


# Check run time matrix	
EXPLAIN ANALYZE
SELECT 
	*,
    (1- post_invoice_discount_pct) * net_invoice_sale AS net_sale
FROM sales_post_invoice_discounts;


#Top customer by net sales
SELECT
	c.customer,
	ROUND(SUM(net_sale) / 1000000, 2) AS net_sale_million
FROM net_sales AS s
JOIN dim_customer AS c
	ON s.customer_code =c.customer_code
WHERE fiscal_year = 2021
GROUP BY c.customer
ORDER BY net_sale_million DESC;

#Top customer by percentage
# net_sales % share by Customer
WITH cte AS (
	SELECT
		c.customer,
		ROUND(SUM(net_sale) / 1000000, 2) AS net_sale_million
	FROM net_sales AS s
	JOIN dim_customer AS c
		ON s.customer_code =c.customer_code
	WHERE fiscal_year = 2021
	GROUP BY c.customer
    )
    
SELECT
	*,
    net_sale_million*100/SUM(net_sale_million) OVER() AS percentage_sale 
FROM cte
ORDER BY percentage_sale DESC;

# net_sales % share by Region
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

# Get Top n product in each divison by their sold quantity in given FY
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

-- By using 2 cte 
WITH cte1 AS (
			SELECT
				p.division,
				p.product,
				SUM(s.sold_quantity) AS total_quantity
			FROM fact_sales_monthly AS s
			JOIN dim_product AS p
				ON s.product_code = p.product_code
			WHERE s.fiscal_year = 2021
			GROUP BY p.division, p.product
			),
	cte2 AS (
			SELECT 
				*,
				DENSE_RANK() OVER(PARTITION BY division ORDER BY total_quantity DESC) AS dense_rnk
			FROM cte1
            )

SELECT * FROM cte2
WHERE dense_rnk <=3;

#Create Stored Procedure for Top n product in each divison by their sold quantity
-- CALL
call gdb0041.get_top_n_product_per_divison_by_sold_quantity(2021, 3);
