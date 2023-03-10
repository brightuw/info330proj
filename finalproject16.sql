-- INFO 330 BB Project Assignment 4: Database Implementation
-- Group 16 - Bright, Megan, Ryu, Ryan

-- Q0. brighth_db
--     the tables in our project will be notated with an "a_" before each table name.

-- Q1.
CREATE TABLE a_brand (
	brand_name varchar(100) PRIMARY KEY, 
	country varchar(100)
);

CREATE TABLE a_department (
	department varchar(200) PRIMARY KEY
);

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
select p.product_id, r.product_name, sum(p.quantity) as num_purchases
from a_purchase p
join a_product r on p.product_id = r.product_id
join a_transaction t on p.transaction_id = t.transaction_id
where extract('year' from t.date_time) = 2022
group by p.product_id, r.product_name 
order by sum(p.quantity) desc
limit 10;

-- 2. Which store location has the highest average number of transactions per month? 
WITH all_transactions_per_month as (
	select t.location, extract('month' from t.date_time), extract('year' from t.date_time), count(*) 
	from a_transaction t
	group by t.location, extract('month' from t.date_time), extract('year' from t.date_time)
),
average_transactions_per_month as (
	select a.location, avg(a.count)
	from all_transactions_per_month a
	group by a.location
),
location_max_avg as (
	select *
	from average_transactions_per_month a
	where avg = (select max(avg) from average_transactions_per_month)
)
select l.location_id, l.street_address, l.city, l.state_province, l.country, m.avg as avg_transactions_per_month
from location_max_avg m
join a_location l on m.location = l.location_id
where l.type = 'Store'
group by l.location_id, l.street_address, l.city, l.state_province, l.country, m.avg;

-- 3. What were the top 5 store locations that made the greatest year-on-year improvement in revenue from 2021 to 2022? 
WITH transaction_totals as (
	select x.transaction_id, x.location, x.date_time, sum(p.price * p.quantity) as total_cost
	from a_purchase p
	join a_transaction x on p.transaction_id = x.transaction_id
	group by x.transaction_id, x.location, x.date_time
),
location_rev_2021 as (
	select t.location, sum(t.total_cost) as yearly_rev
	from transaction_totals t
	where extract('year' from t.date_time) = 2021
	group by t.location
),
location_rev_2022 as (
	select t.location, sum(t.total_cost) as yearly_rev
	from transaction_totals t
	where extract('year' from t.date_time) = 2022
	group by t.location
)
select l.location_id, l.street_address, l.city, l.state_province, l.country, r1.yearly_rev as rev_2021, r2.yearly_rev as rev_2022, r2.yearly_rev - r1.yearly_rev as change_in_rev
from location_rev_2021 r1
join location_rev_2022 r2 on r1.location = r2.location 
join a_location l on r1.location = l.location_id 
where l.type = 'Store'
	and (r2.yearly_rev - r1.yearly_rev) > 0
order by r2.yearly_rev - r1.yearly_rev desc
limit 5;

-- 4. Customer searching for women's items under $50 and sorting from least to most expensive.
select p.product_name as "Item name", p.brand as "Brand", r.price as Price, l.street_address as "Store", l.city as "City"
from a_product p
join a_purchase r on p.product_id = r.product_id
join a_transaction t on r.transaction_id = t.transaction_id
join a_location l on t.location = l.location_id
where p.department = 'Womens' and r.price < 50
order by r.price;

-- 5. According to company policy, all "store" employees that have been employed for over a year
-- are obligated a raise. Find these employees names, position, ID #, and current salary.
select e.first_name, e.last_name, e.employee_id, w.position, e.salary
from a_employee e
join a_works_at w on e.employee_id = w.employee_id
join a_location l on w.location = l.location_id
where l.type = 'Store' and e.date_joined < '2022-03-01';

-- 6. Banana Republic plans to increase their production and wants to find out which department is 
-- making the most amount in sales. Rank all departments by the total revenue.
select p.department, sum(r.price * r.quantity) as "Revenue"
from a_product p 
join a_purchase r on p.product_id = r.product_id
where p.brand = 'Banana Republic'
group by p.department
order by "Revenue" desc;

-- 7. What is the name and price of the most expensive item?
select p.product_id, p.product_name, r.price
from a_product p
join a_purchase r on p.product_id = r.product_id
order by r.price desc
limit 1;

-- 8. What is the hour of the day with the most purchases?
select (extract('hour' from t.date_time)) as hour, count(p.product_id) as num_purchases
from a_product p
join a_purchase r on p.product_id = r.product_id
join a_transaction t on r.transaction_id = t.transaction_id
group by hour
order by "num_purchases" desc
limit 1;

-- 9. Which brand has the highest sold products? (Corporate Executive, Brand Managers, Store Managers)
SELECT pr.brand, SUM(pu.quantity)
FROM a_product pr, a_purchase pu
WHERE pr.product_id = pu.product_id
GROUP BY pr.brand
ORDER BY SUM(pu.quantity) DESC
LIMIT 1;


-- 10. What are the 5 cheapest (average price) L-size t-shirts from brands that are from the US? (Customers)
SELECT pr.product_name, AVG(pu.price)
FROM a_product pr, a_brand b, a_purchase pu
WHERE pr.subcategory = 'T-Shirt' AND pr.brand = b.brand_name
AND b.country = 'USA'AND pr.product_id = pu.product_id
AND (pu.size = 'L' OR pu.size = 'Large')
GROUP BY pr.product_id
ORDER BY AVG(pu.price)
LIMIT 5;


-- 11. What are the top 10 products with the highest average price increases from 2021 to 2022? (Corporate Executive, Retail Analysts)
WITH price_avgs_22 as (SELECT pr.product_name, 
 AVG(pu.price) as avg_price
	FROM a_product pr, a_purchase pu, a_transaction t
	WHERE EXTRACT('year' FROM t.date_time) = '2022' 
AND t.transaction_id = pu.transaction_id
	AND pu.product_id = pr.product_id 
	GROUP BY pr.product_name 
),
price_avgs_21 as (SELECT pr.product_name, 
 AVG(pu.price) as avg_price
	FROM a_product pr, a_purchase pu, a_transaction t
	WHERE EXTRACT('year' FROM t.date_time) = '2021' 
AND  t.transaction_id = pu.transaction_id
	AND pu.product_id = pr.product_id 
	GROUP BY pr.product_name
)
SELECT a1.product_name, a2.avg_price - a1.avg_price as price_difference
FROM price_avgs_21 a1, price_avgs_22 a2
ORDER BY price_difference DESC
LIMIT 10;


-- Q3. Demo Queries with Results:

-- 1. Banana Republic plans to increase their production and wants to find out which department is 
-- 	  making the most amount in sales. Rank all departments by the total revenue. (repeat)
select p.department, sum(r.price * r.quantity) as "Revenue"
from a_product p 
join a_purchase r on p.product_id = r.product_id
where p.brand = 'Banana Republic'
group by p.department
order by "Revenue" desc;

-- Results:

-- Department Revenue:

-- "Womens"	  242.95
-- "Kids"	  98.96
-- "Mens"	  87.97

-- 2. To get an insight on the popularity of all products sold, what were the top 10 most-purchased
-- 	  items in 2022? (repeat)
select p.product_id, r.product_name, sum(p.quantity) as num_purchases
from a_purchase p
join a_product r on p.product_id = r.product_id
join a_transaction t on p.transaction_id = t.transaction_id
where extract('year' from t.date_time) = 2022
group by p.product_id, r.product_name 
order by sum(p.quantity) desc
limit 10;

-- Results

-- product_id   product_name                    num_purchases

-- 18			"Essential Fleece Joggers"					3
-- 16			"Color Blossom BB Star Pendant"				3
-- 1			"Tee Shirt"									3
-- 20			"V-Neck Sweater"							2
-- 2			"Tee Shirt"									2
-- 9			"Solid Ruffle Trim Belted Wrap Dress"		2
-- 11			"Waffle Knit Draped Dress"					2
-- 12			"BIC Earrings"								2
-- 14			"Stylish Head Scarf"						2
-- 17			"Low-Fi Hi-Tek Nuptse Jacket"				2

-- 3. What were the top 5 store locations that made the greatest year-on-year improvement 
--    in revenue from 2021 to 2022? (repeat)
WITH transaction_totals as (
	select x.transaction_id, x.location, x.date_time, sum(p.price * p.quantity) as total_cost
	from a_purchase p
	join a_transaction x on p.transaction_id = x.transaction_id
	group by x.transaction_id, x.location, x.date_time
),
location_rev_2021 as (
	select t.location, sum(t.total_cost) as yearly_rev
	from transaction_totals t
	where extract('year' from t.date_time) = 2021
	group by t.location
),
location_rev_2022 as (
	select t.location, sum(t.total_cost) as yearly_rev
	from transaction_totals t
	where extract('year' from t.date_time) = 2022
	group by t.location
)
select l.location_id, l.street_address, l.city, l.state_province, l.country, r1.yearly_rev as rev_2021, r2.yearly_rev as rev_2022, r2.yearly_rev - r1.yearly_rev as change_in_rev
from location_rev_2021 r1
join location_rev_2022 r2 on r1.location = r2.location 
join a_location l on r1.location = l.location_id 
where l.type = 'Store'
	and (r2.yearly_rev - r1.yearly_rev) > 0
order by r2.yearly_rev - r1.yearly_rev desc
limit 5;

-- Results

-- location_id, street_address, city, state_province, country, rev_2021, rev_2022, change_in_rev

-- 9	"1111 Robson St"	"Vancouver"	"BC"	"CA"	2900	5944.98	3044.98
-- 11	"2855 Stevens Creek Blvd"	"Santa Clara"	"CA"	"USA"	925.98	3084.96	2158.98
-- 1	"7171 Belred Rd"	"Bellevue"	"WA"	"USA"	74.99	952.95	877.96
-- 8	"5500 112th Blvd NE"	"Dallas"	"TX"	"USA"	49.98	319.99	270.01
-- 13	"260 Yonge Street"	"Toronto"	"ON"	"CA"	144.96	329.98	185.02

-- 4. Customer searching for womens items under $50 and sorting from least to most expensive. (repeat)
select p.product_name as "Item name", p.brand as "Brand", r.price as Price, l.street_address as "Store", l.city as "City"
from a_product p
join a_purchase r on p.product_id = r.product_id
join a_transaction t on r.transaction_id = t.transaction_id
join a_location l on t.location = l.location_id
where p.department = 'Womens' and r.price < 50
order by r.price;

-- Results:

-- item name, brand, price, store, city

-- "BIC Earrings"	"Banana Republic"	3.99	"520 Washington St"	"New York"
-- "Solid Ruffle Trim Belted Wrap Dress"	"Shein"	15.99	"112 Martin Luther King Jr Way"	"Houston"
-- "Solid Ruffle Trim Belted Wrap Dress"	"Shein"	15.99	"520 Washington St"	"New York"
-- "EMERY ROSE Solid Ruffle Hem Smock Dress"	"Shein"	17.99	"520 Washington St"	"New York"
-- "Waffle Knit Draped Dress"	"Shein"	23.99	"520 Washington St"	"New York"
-- "V-Neck Sweater"	"GAP"	24.99	"2855 Stevens Creek Blvd"	"Santa Clara"
-- "Essential Fleece Joggers"	"Adidas"	29.99	"2855 Stevens Creek Blvd"	"Santa Clara"
-- "Stylish Head Scarf"	"Burberry"	37.99	"2855 Stevens Creek Blvd"	"Santa Clara"
-- "Stylish Head Scarf"	"Burberry"	42.99	"Online"	
-- "Tina Shoes"	"Chanel"	44.99	"7171 Belred Rd"	"Bellevue"

-- 5. What are the top 10 products with the highest average price increases from 2021 to 2022?
WITH price_avgs_22 as (SELECT pr.product_name, 
 AVG(pu.price) as avg_price
	FROM a_product pr, a_purchase pu, a_transaction t
	WHERE EXTRACT('year' FROM t.date_time) = '2022' 
AND t.transaction_id = pu.transaction_id
	AND pu.product_id = pr.product_id 
	GROUP BY pr.product_name 
),
price_avgs_21 as (SELECT pr.product_name, 
 AVG(pu.price) as avg_price
	FROM a_product pr, a_purchase pu, a_transaction t
	WHERE EXTRACT('year' FROM t.date_time) = '2021' 
AND  t.transaction_id = pu.transaction_id
	AND pu.product_id = pr.product_id 
	GROUP BY pr.product_name
)
SELECT a1.product_name, a2.avg_price - a1.avg_price as price_difference
FROM price_avgs_21 a1, price_avgs_22 a2
ORDER BY price_difference DESC
LIMIT 10;

-- Results:

-- product_name, price_difference

-- "Tee Shirt"	2925.0100000000000000
--"Waffle Knit Draped Dress"	2920.0100000000000000
--"V-Neck Sweater"	2920.0100000000000000
--"Stylish Head Scarf"	2903.0100000000000000
--"New Mom Skinny Jean"	2867.5100000000000000
--"Hype Blouse"	2785.0100000000000000
--"Web Rubber Slides"	2545.0100000000000000
--"Zippy Wallet"	2095.0000000000000000
--"Tee Shirt"	705.0100000000000000
--"V-Neck Sweater"	700.0100000000000000