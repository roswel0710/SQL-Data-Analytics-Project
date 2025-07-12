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