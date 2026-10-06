-- ============================================================
-- Superstore Sales Analysis | SQL queries (SQLite)
-- Author: Abhinav Kumar
-- Table: orders (one row per order line; cleaned, ISO dates)
-- Run: sqlite3 superstore.db < sql/queries.sql   (after building the db,
--      see README "Run the SQL on its own")
-- ============================================================

-- Q1. Overall KPIs
SELECT ROUND(SUM(sales), 2)                          AS total_sales,
       ROUND(SUM(profit), 2)                         AS total_profit,
       ROUND(100.0 * SUM(profit) / SUM(sales), 2)    AS profit_margin_pct,
       COUNT(DISTINCT order_id)                      AS total_orders,
       COUNT(DISTINCT customer_id)                   AS total_customers,
       ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM orders;

-- Q2. Category performance
SELECT category,
       ROUND(SUM(sales), 2)                        AS sales,
       ROUND(SUM(profit), 2)                       AS profit,
       ROUND(100.0 * SUM(profit) / SUM(sales), 2)  AS margin_pct,
       SUM(quantity)                               AS units
FROM orders
GROUP BY category
ORDER BY profit DESC;

-- Q3. Sub-category profitability
SELECT sub_category,
       ROUND(SUM(sales), 2)                        AS sales,
       ROUND(SUM(profit), 2)                       AS profit,
       ROUND(100.0 * SUM(profit) / SUM(sales), 2)  AS margin_pct
FROM orders
GROUP BY sub_category
ORDER BY profit DESC;

-- Q4a. Regional performance
SELECT region,
       ROUND(SUM(sales), 2)                        AS sales,
       ROUND(SUM(profit), 2)                       AS profit,
       ROUND(100.0 * SUM(profit) / SUM(sales), 2)  AS margin_pct
FROM orders
GROUP BY region
ORDER BY profit DESC;

-- Q4b. Top 10 loss-making states
SELECT state,
       ROUND(SUM(sales), 2)  AS sales,
       ROUND(SUM(profit), 2) AS profit
FROM orders
GROUP BY state
HAVING SUM(profit) < 0
ORDER BY profit ASC
LIMIT 10;

-- Q5. Year-over-year growth (window function LAG)
WITH yearly AS (
    SELECT CAST(strftime('%Y', order_date) AS INTEGER) AS year,
           SUM(sales)  AS sales,
           SUM(profit) AS profit
    FROM orders
    GROUP BY year
)
SELECT year,
       ROUND(sales, 2)  AS sales,
       ROUND(profit, 2) AS profit,
       ROUND(100.0 * (sales - LAG(sales) OVER (ORDER BY year))
                   / LAG(sales) OVER (ORDER BY year), 2) AS sales_growth_pct
FROM yearly
ORDER BY year;

-- Q6. Seasonality: months ranked by total sales
SELECT CAST(strftime('%m', order_date) AS INTEGER) AS month_no,
       ROUND(SUM(sales), 2) AS sales
FROM orders
GROUP BY month_no
ORDER BY sales DESC;

-- Q7. Discount impact on profit (CASE bands)
SELECT CASE
           WHEN discount = 0    THEN '1. No discount'
           WHEN discount <= 0.2 THEN '2. Up to 20%'
           WHEN discount <= 0.4 THEN '3. 21-40%'
           ELSE                      '4. Over 40%'
       END                                        AS discount_band,
       COUNT(*)                                   AS line_items,
       ROUND(SUM(sales), 2)                       AS sales,
       ROUND(SUM(profit), 2)                      AS profit,
       ROUND(100.0 * SUM(profit) / SUM(sales), 2) AS margin_pct
FROM orders
GROUP BY discount_band
ORDER BY discount_band;

-- Q8a. Customer segments
SELECT segment,
       COUNT(DISTINCT customer_id)                 AS customers,
       ROUND(SUM(sales), 2)                        AS sales,
       ROUND(SUM(profit), 2)                       AS profit,
       ROUND(100.0 * SUM(profit) / SUM(sales), 2)  AS margin_pct
FROM orders
GROUP BY segment
ORDER BY sales DESC;

-- Q8b. Top 10 customers by sales
SELECT customer_name,
       segment,
       COUNT(DISTINCT order_id) AS orders,
       ROUND(SUM(sales), 2)     AS sales,
       ROUND(SUM(profit), 2)    AS profit
FROM orders
GROUP BY customer_id, customer_name, segment
ORDER BY sales DESC
LIMIT 10;

-- Q9. Shipping mode vs delivery time
SELECT ship_mode,
       COUNT(DISTINCT order_id) AS orders,
       ROUND(AVG(julianday(ship_date) - julianday(order_date)), 2) AS avg_days_to_ship
FROM orders
GROUP BY ship_mode
ORDER BY avg_days_to_ship;

-- Q10. Repeat customers (CTE)
WITH per_customer AS (
    SELECT customer_id, COUNT(DISTINCT order_id) AS n_orders
    FROM orders
    GROUP BY customer_id
)
SELECT COUNT(*)                                              AS customers,
       SUM(CASE WHEN n_orders > 1 THEN 1 ELSE 0 END)         AS repeat_customers,
       ROUND(100.0 * SUM(CASE WHEN n_orders > 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS repeat_pct,
       ROUND(AVG(n_orders), 2)                               AS avg_orders_per_customer
FROM per_customer;
