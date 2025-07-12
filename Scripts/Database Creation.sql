--=================================================
--Databese Creation and Table loading
--=================================================

CREATE SCHEMA IF NOT EXISTS gold;

CREATE TABLE gold.dim_customers (
	customer_key INT,
	customer_id INT,
	customer_number VARCHAR(50),
	first_name VARCHAR(50),
	last_name VARCHAR(50),
	country VARCHAR(50),
	marital_status VARCHAR(50),
	gender VARCHAR(50),
	birthdate DATE,
	create_date DATE
);

CREATE TABLE gold.dim_products (
	product_key INT,
	product_id INT,
	product_number VARCHAR(50),
	product_name VARCHAR(50),
	category_id VARCHAR(50),
	category VARCHAR(50),
	subcategory VARCHAR(50),
	maintenance VARCHAR(50),
	cost INT,
	product_line VARCHAR(50),
	start_date DATE
);

CREATE TABLE gold.fact_sales (
	order_number VARCHAR(50),
	product_key INT,
	customer_key INT,
	order_date DATE,
	shipping_date DATE,
	due_date DATE,
	sales_amount INT,
	quantity SMALLINT,
	price INT
);

-- Load customers
COPY gold.dim_customers FROM '/Users/rosewalalmeida/Desktop/Capstone Project/SQL Projects/sql-data-analytics-project/datasets/csv-files/gold.dim_customers.csv'
DELIMITER ',' CSV HEADER;

-- Load products
COPY gold.dim_products FROM '/Users/rosewalalmeida/Desktop/Capstone Project/SQL Projects/sql-data-analytics-project/datasets/csv-files/gold.dim_products.csv'
DELIMITER ',' CSV HEADER;

-- Load sales
COPY gold.fact_sales FROM '/Users/rosewalalmeida/Desktop/Capstone Project/SQL Projects/sql-data-analytics-project/datasets/csv-files/gold.fact_sales.csv'
DELIMITER ',' CSV HEADER;

