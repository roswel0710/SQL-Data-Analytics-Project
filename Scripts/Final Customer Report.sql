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
