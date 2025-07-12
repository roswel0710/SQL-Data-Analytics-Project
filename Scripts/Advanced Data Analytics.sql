--=================================================
--TRENDS (Change over time Analysis)
--=================================================
--Year wise
SELECT EXTRACT (YEAR FROM order_date) as order_year,
SUM(sales_amount) as Total_Sales,
COUNT(DISTINCT customer_key) as total_customers
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY order_year
ORDER BY order_year

--Month Year Wise
SELECT 
TO_CHAR(order_date, 'Mon YYYY') as order_year,
SUM(sales_amount) as Total_Sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY order_year
ORDER BY MIN(order_date)

--=================================================
--Cumulative Analysis
--=================================================

--Calculate total sales for each month and running sales over TIME
SELECT
order_date,
total_sales,
--window function
SUM(total_sales) OVER(PARTITION BY EXTRACT(YEAR FROM order_date) ORDER BY order_date) AS running_total_sales
FROM
(
	SELECT DATE_TRUNC('month', order_date) as order_date,
	SUM(sales_amount) as total_sales
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATE_TRUNC('month', order_date)
	ORDER BY DATE_TRUNC('month', order_date)
)

--=================================================
--Performance Analysis
--=================================================
-- Analyze the yearly performance of products by comparing 
-- each product's sales to both its average sales performance
-- and the previous years sales

WITH yearly_product_sales AS 
(
	SELECT
	  EXTRACT(YEAR FROM f.order_date) AS order_year,
	  p.product_name,
	  SUM(f.sales_amount) AS current_sales
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	  ON p.product_key = f.product_key
	WHERE EXTRACT(YEAR FROM f.order_date) IS NOT NULL
	GROUP BY order_year, p.product_name
)

SELECT 
order_year,
product_name,
current_sales,
AVG(current_sales)OVER(PARTITION BY product_name) Avg_sales,
current_sales - AVG(current_sales) OVER(PARTITION BY product_name) Diff_avg,
CASE WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'Above Average'
	WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'Below Average'
	ELSE 'Average'
	END avg_change,
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year ASC) as previous_year_sales,
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year ASC) AS diff_last_year_sales,
CASE WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year ASC) > 0 THEN 'Increase'
	WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year ASC) < 0 THEN 'Decrease'
	ELSE 'No Change'
	END last_year_change
FROM yearly_product_sales
ORDER BY 2,1;

--=================================================
--Part to Whole Analysis
--=================================================
--Which categories contribute the most to overall sales?
SELECT
category,
category_sales,
SUM(Category_sales) OVER() AS total_sales,
CONCAT(ROUND((category_sales/SUM(Category_sales) OVER())*100,2),'%') AS percent_sales
FROM
(
	SELECT p.category,
	SUM(s.sales_amount) AS category_sales
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_products p
	ON s.product_key = p.product_key
	GROUP BY p.category
)

--=================================================
--Data Segmentation
--================================================= 
--Segment products into cost ranges and
--count how many products fall into each segment
WITH product_segment AS 
(
	SELECT product_key,
	product_name,
	cost,
	CASE WHEN cost < 100 THEN 'Below 100'
		WHEN cost BETWEEN 100 and 500 THEN '100-500'
		WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
		ELSE 'Above 1000'
	END cost_range
	FROM gold.dim_products
)

SELECT 
cost_range,
COUNT(product_key) AS total_products
FROM product_segment
GROUP BY cost_range
ORDER BY 2 DESC

--Group customers into 3 segments based on their spending behaviour
-- VIP: Atleast 12months of history and spending more than 5000
-- Regular: Atleast 12 months of history and spending 5000 or less
-- New: lifespan less than 12 months
--Find total numnber of customers by each group
WITH customer_spending AS 
( SELECT c.customer_key,
SUM(f.sales_amount) As total_spending,
MIN(order_date) as First_order,
MAX(order_date) as Last_order,
EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date))) * 12 +
  EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date))) AS lifespan_months
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key)

SELECT customer_segment,
COUNT(customer_key) as total_customers
FROM (
SELECT customer_key,
CASE WHEN lifespan_months >=12 AND total_spending > 5000 THEN 'VIP'
	WHEN lifespan_months >= 12 AND total_spending <=5000 THEN 'Regular'
	ELSE 'New'
END customer_segment
FROm customer_spending) t
GROUP BY customer_segment
ORDER BY total_customers DESC

/* 
--=================================================
--Building Report
--================================================= 
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend 
===============================================================================
*/
CREATE VIEW gold.report_customers AS 
WITH base_query AS (
--Base Query to retrieve core columns from tables
SELECT 
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT (c.first_name, ' ', c.last_name) AS customer_name,
EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.birthdate)) Age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
WHERE order_date IS NOT NULL)

, customer_aggregation AS
--Customer aggregations: Summarizes key metrics at the customer level
(SELECT customer_key,
customer_number,
customer_name,
Age,
COUNT(DISTINCT order_number) as Total_orders,
SUM(Sales_amount) AS Total_sales,
SUM(quantity) As Total_quantity,
COUNT(DISTINCT product_key) AS total_products,
MIN(order_date) AS first_order,
MAX(order_Date) AS Last_order,
(EXTRACT(YEAR FROM MAX(order_date)) - EXTRACT(YEAR FROM MIN(order_date))) * 12 +
(EXTRACT(MONTH FROM MAX(order_date)) - EXTRACT(MONTH FROM MIN(order_date))) AS lifespan_months
FROM base_query
GROUP BY 1,2,3,4)

SELECT 
customer_key,
customer_number,
customer_name,
Age,
CASE WHEN Age < 20 THEN 'Under 20'
	WHEN Age BETWEEN 20 and 29 THEN '20-29'
	WHEN Age BETWEEN 30 and 39 THEN '30-39'
	WHEN Age BETWEEN 40 and 49 THEN '40-49'
	ELSE '50 and Above'
END AS age_group,
CASE WHEN lifespan_months >=12 AND total_sales > 5000 THEN 'VIP'
	WHEN lifespan_months >= 12 AND total_sales <=5000 THEN 'Regular'
	ELSE 'New'
END AS customer_segment,
first_order,
last_order,
(EXTRACT(YEAR FROM AGE(CURRENT_DATE, last_order)) * 12 +
EXTRACT (MONTH FROM AGE(CURRENT_DATE, last_order))) AS Recency, 
total_orders,
total_sales,
total_products,
lifespan_months,
-- Compute Average order value
total_sales/total_orders as Avg_order_value,
-- Compute Average Monthly Spend
CASE WHEN lifespan_months=0 THEN total_sales
	ELSE total_sales/Lifespan_months 
END AS Avg_monthly_value
FROM customer_aggregation


SELECT *
FROM gold.report_customers

/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/
--=============================================================================
--Create Report: gold.report_products
--=============================================================================
CREATE VIEW gold.report_products AS

WITH base_query AS
(
--Retrieving Base Columns
SELECT p.product_key,
p.product_name,
p.category,
p.subcategory,
p.cost,
f.customer_key,
f.quantity,
f.sales_amount,
f.order_number,
f.order_date
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
WHERE order_date IS NOT NULL)
,
--Product aggregations
products_aggregation AS (
SELECT product_key,
product_name,
category,
subcategory,
cost,
COUNT(order_number) AS total_orders,
SUM(sales_amount) AS total_sales,
SUM(quantity) AS total_quantity,
COUNT(DISTINCT customer_key) AS total_unique_customers,
MIN(order_date) AS first_order,
MAX(order_date) AS last_order,
(EXTRACT(YEAR FROM MAX(order_date)) - EXTRACT(YEAR FROM MIN(order_date))) * 12 +
(EXTRACT(MONTH FROM MAX(order_date)) - EXTRACT(MONTH FROM MIN(order_date))) AS lifespan_months
FROM base_query
GROUP BY 1,2,3,4,5
)
--Final report
SELECT product_key,
product_name,
category,
subcategory,
cost,
total_orders,
total_sales,
CASE WHEN total_sales > 50000 THEN 'High-Perfomer'
	WHEN total_sales >= 10000 THEN 'Mid-Performer'
	ELSE 'Low-Performer'
END AS product_segment,
total_quantity,
total_unique_customers,
first_order,
last_order,
(EXTRACT (YEAR FROM (CURRENT_DATE)) - (EXTRACT (YEAR FROM last_order)))*12 + 
(EXTRACT (MONTH FROM (CURRENT_DATE)) - (EXTRACT (MONTH FROM last_order))) AS Recency_months,
--Average Order Revenue
CASE WHEN total_orders = 0 THEN 0
	ELSE total_sales/total_orders
END AS Avg_order_revenue,
--Average Monthly Revenuw
CASE WHEN lifespan_months = 0 THEN total_sales
	ELSE total_sales/lifespan_months
END AS Avg_monthly_revenue
FROM products_aggregation