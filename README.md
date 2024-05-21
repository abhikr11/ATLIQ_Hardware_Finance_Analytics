# AtliQ Hardware Finance Analytics using MySQL

## Introduction

This repository contains SQL scripts and data analysis for AtliQ Hardware, a prominent supplier of computer hardware and peripherals in India. The aim is to provide the sales director with a robust platform for seamlessly tracking sales performance across all operations, enabling informed decision-making and strategic planning.

## Objective

The primary objective of this project is to address the challenges faced by AtliQ Hardware in accessing timely and comprehensive updates on sales metrics from regional sales managers. By implementing a centralized and user-friendly system, the project seeks to present sales data in a cohesive and visually appealing format, facilitating swift comprehension and informed decision-making.

## Tools Used

- MySQL: For data analysis, querying, and generating reports.

## Analyses and Stored Procedures

The repository includes the following analyses and stored procedures:

### Analyses

1. **Analysis 1**: Generate a report of individual product sales for the Croma India customer for FY=2021.
2. **Analysis 2**: Create a stored procedure to generate a monthly sales report for a given customer code.
3. **Analysis 3**: Create a stored procedure to generate a monthly sales report for a given customer with multiple customer codes.
4. **Analysis 4**: Generate a yearly report for "Atliq e Store" for all markets.
5. **Analysis 5**: Create a stored procedure to determine the market badge based on the total sold quantity.
6. **Analysis 6**: Create a view for gross sales with relevant columns.
7. **Analysis 7**: Implement performance improvements for SQL queries.
8. **Analysis 8**: Calculate the net sales amount.
9. **Analysis 9**: Identify the top markets and customers by net sales.
10. **Analysis 10**: Calculate the percentage share of net sales for each customer within their respective region for 2021.
11. **Analysis 11**: Get the top n products in each division by their sold quantity in a given fiscal year.

### Stored Procedures

1. `get_monthly_sales_report`: Generate a monthly sales report for a given customer code.
2. `get_monthly_sales_report_multiple_customers`: Generate a monthly sales report for a given customer with multiple customer codes.
3. `get_market_badge`: Determine the market badge based on the total sold quantity.
4. `get_top_market_by_netsales`: Get the top markets for a given fiscal year by net sales.
5. `get_top_customer_by_netsales_and_market`: Get the top customers for a given fiscal year by net sales and market.
6. `get_top_n_product_per_division_by_sold_quantity`: Get the top n products in each division by their sold quantity in a given fiscal year.

## Learnings and Outcomes

Through this project, the following key learnings were achieved:

- Effective data analysis and querying techniques using SQL.
- Creating stored procedures for generating reports and performing complex calculations.
- Implementing performance optimization techniques, such as creating lookup tables and adding generated columns.
- Calculating key metrics like net sales amount, top markets, and top customers based on net sales.
- Generating reports for individual product sales, monthly sales, and yearly sales.
- Determining market badges based on sold quantity thresholds.
- Creating views for efficient data retrieval and analysis.

The project successfully implemented a centralized system for AtliQ Hardware, enabling the sales director to monitor sales performance effectively. By leveraging data analytics and visualization techniques, the project delivered outcomes such as automated report generation, calculation of net sales amount, identification of top markets and customers, analysis of percentage share of net sales, and retrieval of top-selling products in each division.

## Contributing

Contributions to this repository are welcome. If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.
