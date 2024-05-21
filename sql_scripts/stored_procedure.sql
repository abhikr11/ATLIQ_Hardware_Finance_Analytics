# Stored Procedures
-- Used to store SQL Quarries so that we don't have to write code again & again
-- we can just use this stored fn to recall
-- Monthly sales for Amazon, Ebay, AtliQ stores, Flipkart so writing same code again & again could be hectic
-- use Stored Procedures

#Amazon monthly sales
select * from dim_customer
where customer like "%amazon%" and
	market like "%india%";

-- Amazon customer codes are 90002008 and 90002016

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

# Stored Procedure when there is more than one value say a list of values
-- use FIND_IN_SET

# Stored Procedure for Market Badge
-- Create a stored proc that can determine the market badge based on the following logic
-- If total sold quantity > 5 million that market is considered Gold else Silver
-- Input : market, fiscal year
-- Output : market badge

SELECT
    market,
    SUM(sold_quantity) AS total_sold_qty
FROM fact_sales_monthly AS s
JOIN dim_customer AS c
	ON s.customer_code = c.customer_code
WHERE c.market = "India"
	AND get_fiscal_year(s.date) =2020
GROUP BY market ;

# USE CASE TO GET MARKET_BADGE
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

# call stored procedure 
call gdb0041.market_badge('india', 2020);

call gdb0041.market_badge('india', 2021);

call gdb0041.market_badge('indonesia', 2021);

call gdb0041.market_badge('', 2021);

# CALL get_market_badge
set @out_market_badge = '0';
set @out_total_sold_qty = 0;
call gdb0041.get_market_badge('india', 2020, @out_market_badge, @out_total_sold_qty);
select @out_market_badge, @out_total_sold_qty;

-- Indonesia / 2020
set @out_market_badge = '0';
set @out_total_sold_qty = 0;
call gdb0041.get_market_badge('indonesia', 2020, @out_market_badge, @out_total_sold_qty);
select @out_market_badge, @out_total_sold_qty;

