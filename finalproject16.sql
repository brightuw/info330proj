-- INFO 330 BB Project Assignment 4: Database Implementation
-- Group 16 - Bright, Megan, Ryu, Ryan

-- Q0. brighth.db
--     the tables in our project will be notated with an "a_" before each table name.

-- Q1. [create table statements here]

-- Q2. 10 SQL Statements
-- 1. In 2022, what were the top 10 products that were purchased the most often?
SELECT p.product_id, r.product_name, COUNT(product_id)
FROM a_purchase p
JOIN a_product r on p.product_id = r.product_id
JOIN a_transaction t on p.transaction_id = t.transaction_id
WHERE EXTRACT('year' FROM t.date_time) = 2022,
GROUP BY p.product_id, r.product_name, 
ORDER BY COUNT(product_id) DESC,
LIMIT 10;

-- 2. Which store location has the highest average number of transactions per month? 
WITH all_transactions_per_month AS (
	SELECT t.store, EXTRACT('month' FROM t.date_time), EXTRACT('year' FROM t.date_time), COUNT(*) 
	FROM a_transaction t
	GROUP BY t.store, EXTRACT('month' FROM t.date_time), EXTRACT('year' FROM t.date_time)
),
average_transactions_per_month AS (
	SELECT a.store, AVG(a.count)
	FROM all_transactions_per_month a
	GROUP BY a.store
),
SELECT s.store_id, s.address, s.city, s.state, s.country, v.avg AS avg_transactions_per_month
FROM average_transactions_per_month v
JOIN a_store s on avg.store = s.store_id
WHERE v.avg = MAX(v.avg);

-- 3.What are the top 10 store locations that made the greatest year-on-year improvement in revenue from 2021 to 2022? 
WITH transaction_totals AS (
	SELECT x.transaction_id, x.store, SUM(p.price * p.quantity) AS total_cost
	FROM a_purchase p
	JOIN a_transaction x on p.transaction_id = x.transaction_id
	GROUP BY x.transaction_id, x.store
),
store_rev_2021 AS (
	SELECT t.store, SUM(t.total_cost) AS yearly_rev
	FROM transaction_totals t
	WHERE EXTRACT('year' FROM t.date_time) = 2021
	GROUP BY t.store
),
store_rev_2022 AS (
	SELECT t.store, SUM(t.total_cost) AS yearly_rev
	FROM transaction_totals t
	WHERE EXTRACT('year' FROM t.date_time) = 2022
	GROUP BY t.store
),
SELECT s.store_id, s.address, s.city, s.state, s.country, r1.yearly_rev AS rev_2021, r2.yearly_rev AS rev_2022, r2.yearly_rev - r1.yearly_rev AS change_in_rev
FROM store_rev_2021 r1
JOIN store_rev_2022 r2 on r1.store = r2.store 
JOIN a_store s on r1.store = s.store_id 
ORDER BY r2.yearly_rev - r1.yearly_rev DESC,
LIMIT 10;
