# 🧮 Advanced SQL Data Analytics Project

## 📌 Overview

This project showcases a complete end-to-end SQL-based data analytics workflow using PostgreSQL. It involves designing a data warehouse schema, loading real-world retail datasets, and conducting detailed data exploration, business metric calculations, and reporting using SQL views. 

> 💡 **Inspiration:** This project was built by following the YouTube tutorial by **[Data with Baraa](https://www.youtube.com/@DataWithBaraa)**. Full credit for the project idea and flow goes to him.

---

## 📂 Project Structure

- **Schema Design:** `gold` schema with `dim_customers`, `dim_products`, and `fact_sales` tables.
- **Data Loading:** CSV files loaded using `COPY`.
- **Analysis Techniques Used:**
  - Exploratory Data Analysis (EDA)
  - Aggregation & Window Functions
  - Time Series & Trend Analysis
  - Ranking & Segmentation
  - Customer & Product Reporting

---

## 📊 Key Analysis Sections

### 1. Database & Table Setup
- Created a PostgreSQL schema and 3 core tables.
- Loaded datasets with customer, product, and sales information.

### 2. Data Exploration
- Identified unique countries, categories, and subcategories.
- Investigated time range of orders and customer age distribution.

### 3. Business Metrics
- Calculated total sales, quantity sold, average selling price.
- Counted orders, products, and unique customers.

### 4. Magnitude Analysis
- Customer count by country and gender.
- Product distribution and category-wise revenue.
- Customer-wise total sales and order behavior.

### 5. Ranking Analysis
- Top 5 and bottom 5 revenue-generating products.
- Top 10 highest-spending customers.

### 6. Time Trend Analysis
- Sales performance by year and by month.
- Cumulative sales trends using `SUM() OVER()` with partitioning.

### 7. Performance Analysis
- Compared each product's sales to its average and previous year.
- Tagged products as `Above Average`, `Below Average`, or `No Change`.

### 8. Part-to-Whole Analysis
- Category-wise sales contribution to total revenue with percentage breakdown.

### 9. Segmentation
- Grouped products into cost ranges.
- Segmented customers into:
  - `VIP` (12+ months, >5000 sales),
  - `Regular` (12+ months, ≤5000 sales),
  - `New` (<12 months).

---

## 📑 Reports Built

### ✅ `gold.report_customers` View
- Combines customer details with:
  - Age and age group
  - Total orders, sales, and product count
  - Lifespan and recency
  - Average order value and monthly spend
  - Customer segment (VIP, Regular, New)

### ✅ `gold.report_products` View
- Summarizes product-level metrics:
  - Sales, orders, customer reach
  - Cost-based performance tags (High, Mid, Low)
  - Recency of sales
  - Average revenue per order and per month

---

## 🛠 Tools Used

- **Database:** PostgreSQL
- **Data Format:** CSV
- **Language:** SQL
- **Platform:** Local PostgreSQL setup

---

## ✅ How to Run

1. Create the `gold` schema and load the provided CSV files using the `COPY` command.
2. Run the SQL scripts in order: Database setup → EDA → Analysis → Reporting views.
3. Query the views `gold.report_customers` and `gold.report_products` to access business insights.

---

## 📎 Credits

- **Idea & Structure:** Inspired by [Data with Baraa](https://www.youtube.com/@DataWithBaraa)
- **Data Source:** Sample retail datasets in CSV format

---

## 📝 Final Notes

This project is a practical demonstration of how SQL can be used not just for querying but for deep data exploration and reporting. The entire analysis was done using **pure SQL**, without any BI or visualization tools.
