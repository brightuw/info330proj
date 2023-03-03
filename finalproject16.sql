-- INFO 330 BB Project Assignment 4: Database Implementation
-- Group 16 - Bright, Megan, Ryu, Ryan

-- Q0. brighth.db
--     the tables in our project will be notated with an "a_" before each table name.

-- Q1. [create table statements here]

CREATE TABLE a_brand (
	brand_name varchar(100) PRIMARY KEY, 
	country varchar(100)
);

CREATE TABLE a_department (
	department varchar(200) PRIMARY KEY
)

drop table a_product;
CREATE TABLE a_product (
	product_name varchar(100),
	brand varchar(100) REFERENCES a_brand(brand_name) ON DELETE SET NULL,
	department varchar(100) REFERENCES a_department(department) ON DELETE RESTRICT,
	category varchar(100),
	subcategory varchar(200),
	product_id serial PRIMARY KEY
);

CREATE TABLE a_product_tags (
	product_id int REFERENCES a_product(product_id) ON DELETE CASCADE ON UPDATE CASCADE,
	tag varchar(100),
	PRIMARY KEY (product_id, tag)
);

CREATE TABLE a_customer (
	phone_number varchar(100),
	first_name varchar(100),
	last_name varchar(100),
	email varchar(50),
	street_address varchar(200),
	city varchar(200),
	state_province varchar(200),
	country varchar(200),
	postal_code int,
	customer_id serial PRIMARY KEY
);

CREATE TABLE a_location (
	type varchar(200),
	street_address varchar(200),
	city varchar(100),
	state_province varchar(100),
	country varchar(100),
	still_open boolean,
	location_id serial PRIMARY KEY
);

CREATE TABLE a_transaction (
	transaction_id serial PRIMARY KEY,
	customer int REFERENCES a_customer(customer_id) ON DELETE SET DEFAULT,
	location int REFERENCES a_location(location_id) ON DELETE RESTRICT,
	date_time timestamp
);

ALTER TABLE a_transaction ALTER COLUMN customer SET DEFAULT 0;

CREATE TABLE a_purchase (
	transaction_id int REFERENCES a_transaction (transaction_id) ON DELETE CASCADE,
	product_id INT REFERENCES a_product(product_id) ON DELETE RESTRICT,
	price decimal,
	size varchar(100),
	quantity smallint,
	PRIMARY KEY (transaction_id, product_id)
);

CREATE TABLE a_employee (
	first_name varchar(100),
	last_name varchar(100),
	salary int,
	date_joined date,
	employee_id serial PRIMARY KEY
);

CREATE TABLE a_works_at (
	employee_id int REFERENCES a_employee(employee_id) ON DELETE CASCADE ON UPDATE CASCADE,
	position varchar(200),
	location int REFERENCES a_location(location_id) ON DELETE CASCADE ON UPDATE CASCADE,
	PRIMARY KEY (employee_id, position, location)
);








-- Q2. 10 SQL Statements
-- 1. In 2022, what were the top 10 products that were purchased the most often?
SELECT p.product_id, r.product_name, COUNT(p.product_id)
FROM a_purchase p
JOIN a_product r on p.product_id = r.product_id
JOIN a_transaction t on p.transaction_id = t.transaction_id
WHERE EXTRACT('year' FROM t.date_time) = 2022
GROUP BY p.product_id, r.product_name 
ORDER BY COUNT(p.product_id) DESC
LIMIT 10;

-- 2. Which location has the highest average number of transactions per month? 
WITH all_transactions_per_month AS (
	SELECT t.location, EXTRACT('month' FROM t.date_time), EXTRACT('year' FROM t.date_time), COUNT(*) 
	FROM a_transaction t
	GROUP BY t.location, EXTRACT('month' FROM t.date_time), EXTRACT('year' FROM t.date_time)
),
average_transactions_per_month AS (
	SELECT a.location, AVG(a.count)
	FROM all_transactions_per_month a
	GROUP BY a.location
),
location_max_avg AS (
	SELECT *
	FROM average_transactions_per_month a
	WHERE avg = (SELECT MAX(avg) FROM average_transactions_per_month)
)
SELECT l.location_id, l.street_address, l.city, l.state_province, l.country, m.avg AS avg_transactions_per_month
FROM location_max_avg m
JOIN a_location l on m.location = l.location_id
GROUP BY l.location_id, l.street_address, l.city, l.state_province, l.country, m.avg;

-- 3.What are the top 10 store locations that made the greatest year-on-year improvement in revenue from 2021 to 2022? 
WITH transaction_totals AS (
	SELECT x.transaction_id, x.location, x.date_time, SUM(p.price * p.quantity) AS total_cost
	FROM a_purchase p
	JOIN a_transaction x on p.transaction_id = x.transaction_id
	GROUP BY x.transaction_id, x.location, x.date_time
),
location_rev_2021 AS (
	SELECT t.location, SUM(t.total_cost) AS yearly_rev
	FROM transaction_totals t
	WHERE EXTRACT('year' FROM t.date_time) = 2021
	GROUP BY t.location
),
location_rev_2022 AS (
	SELECT t.location, SUM(t.total_cost) AS yearly_rev
	FROM transaction_totals t
	WHERE EXTRACT('year' FROM t.date_time) = 2022
	GROUP BY t.location
)
SELECT l.location_id, l.street_address, l.city, l.state_province, l.country, r1.yearly_rev AS rev_2021, r2.yearly_rev AS rev_2022, r2.yearly_rev - r1.yearly_rev AS change_in_rev
FROM location_rev_2021 r1
JOIN location_rev_2022 r2 on r1.location = r2.location 
JOIN a_location l on r1.location = l.location_id 
ORDER BY r2.yearly_rev - r1.yearly_rev DESC
LIMIT 10;

