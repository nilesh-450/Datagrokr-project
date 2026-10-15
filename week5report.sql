-- =====================================================================
-- WEEK 5: SQL DIMENSIONAL REPORT   (PostgreSQL)
-- Covers: Star schema, window function rankings, CTE month-over-month
--         report, ROLLUP, EXPLAIN optimization
-- =====================================================================

DROP TABLE IF EXISTS fact_sales, dim_date, dim_product, dim_customer, dim_store CASCADE;

-- ---------------------------------------------------------------------
-- PART A: STAR SCHEMA  (1 fact table in the middle, 4 dimension tables around it)
-- ---------------------------------------------------------------------
CREATE TABLE dim_date (
    date_key     INT PRIMARY KEY,            -- e.g. 20250115
    full_date    DATE NOT NULL UNIQUE,
    day_of_week  VARCHAR(10) NOT NULL,
    month_num    INT NOT NULL,
    month_name   VARCHAR(10) NOT NULL,
    quarter      INT NOT NULL,
    year         INT NOT NULL
);

CREATE TABLE dim_product (
    product_key  SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category     VARCHAR(50) NOT NULL,
    brand        VARCHAR(50) NOT NULL
);

CREATE TABLE dim_customer (
    customer_key SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    segment      VARCHAR(20) NOT NULL CHECK (segment IN ('Consumer','Corporate','Home Office')),
    city         VARCHAR(60) NOT NULL
);

CREATE TABLE dim_store (
    store_key    SERIAL PRIMARY KEY,
    store_name   VARCHAR(80) NOT NULL,
    city         VARCHAR(60) NOT NULL,
    region       VARCHAR(20) NOT NULL
);

CREATE TABLE fact_sales (
    sale_id      SERIAL PRIMARY KEY,
    date_key     INT NOT NULL REFERENCES dim_date(date_key),
    product_key  INT NOT NULL REFERENCES dim_product(product_key),
    customer_key INT NOT NULL REFERENCES dim_customer(customer_key),
    store_key    INT NOT NULL REFERENCES dim_store(store_key),
    quantity     INT NOT NULL CHECK (quantity > 0),
    revenue      NUMERIC(12,2) NOT NULL CHECK (revenue >= 0),
    cost         NUMERIC(12,2) NOT NULL CHECK (cost >= 0)
);

-- ---------------------------------------------------------------------
-- PART B: DATA
-- ---------------------------------------------------------------------
-- Date dimension: every day from 2025-01-01 to 2025-12-31
INSERT INTO dim_date
SELECT TO_CHAR(d,'YYYYMMDD')::INT, d, TRIM(TO_CHAR(d,'Day')), EXTRACT(MONTH FROM d)::INT,
       TRIM(TO_CHAR(d,'Month')), EXTRACT(QUARTER FROM d)::INT, EXTRACT(YEAR FROM d)::INT
FROM generate_series('2025-01-01'::date, '2025-12-31'::date, '1 day') AS d;

INSERT INTO dim_product (product_name, category, brand) VALUES
('Wireless Earbuds','Electronics','SoundX'),
('Smartphone X','Electronics','TechNova'),
('Laptop Stand','Electronics','DeskPro'),
('Cotton T-Shirt','Fashion','UrbanWear'),
('Running Shoes','Fashion','SprintFit'),
('Mixer Grinder','Home & Kitchen','HomeChef'),
('Water Bottle','Home & Kitchen','HydroMax'),
('SQL Made Easy','Books','LearnPress'),
('Python Crash Course','Books','LearnPress');

INSERT INTO dim_customer (customer_name, segment, city) VALUES
('Aarav Sharma','Consumer','Bengaluru'),('Diya Nair','Consumer','Kochi'),
('Rohan Gowda','Corporate','Mysuru'),('Sneha Patil','Home Office','Pune'),
('Kabir Khan','Corporate','Mumbai'),('Meera Iyer','Consumer','Chennai'),
('Ananya Das','Home Office','Kolkata'),('Ishaan Verma','Corporate','Delhi');

INSERT INTO dim_store (store_name, city, region) VALUES
('Bengaluru Central','Bengaluru','South'),('Mumbai Mall','Mumbai','West'),
('Delhi Hub','Delhi','North'),('Kolkata Square','Kolkata','East');

-- Fact data: 1,200 generated sales spread over the year (random but repeatable)
SELECT setseed(0.42);
INSERT INTO fact_sales (date_key, product_key, customer_key, store_key, quantity, revenue, cost)
SELECT TO_CHAR(DATE '2025-01-01' + r.dn, 'YYYYMMDD')::INT,
       r.pk, r.ck, r.sk, r.qty,
       ROUND((r.qty * pr.price * (0.9 + r.noise * 0.2))::numeric, 2),
       ROUND((r.qty * pr.price * 0.65)::numeric, 2)
FROM (
    -- one random value per generated row
    SELECT g,
           floor(random()*365)::int AS dn,
           1 + floor(random()*9)::int AS pk,
           1 + floor(random()*8)::int AS ck,
           1 + floor(random()*4)::int AS sk,
           1 + floor(random()*4)::int AS qty,
           random() AS noise
    FROM generate_series(1,1200) AS g
) r
JOIN (VALUES (1,2499),(2,18999),(3,899),(4,599),(5,3299),(6,3999),(7,349),(8,450),(9,650))
     AS pr(pk, price) ON pr.pk = r.pk;

-- Sanity check
SELECT COUNT(*) AS fact_rows, SUM(revenue) AS total_revenue FROM fact_sales;

-- ---------------------------------------------------------------------
-- PART C: STAR SCHEMA QUERIES (join fact to dimensions)
-- ---------------------------------------------------------------------
-- Q1 Revenue by category
SELECT p.category, SUM(f.revenue) AS revenue
FROM fact_sales f JOIN dim_product p ON p.product_key = f.product_key
GROUP BY p.category ORDER BY revenue DESC;

-- Q2 Revenue by region and quarter
SELECT s.region, d.quarter, SUM(f.revenue) AS revenue
FROM fact_sales f
JOIN dim_store s ON s.store_key = f.store_key
JOIN dim_date d  ON d.date_key = f.date_key
GROUP BY s.region, d.quarter ORDER BY s.region, d.quarter;

-- Q3 Profit by customer segment
SELECT c.segment, SUM(f.revenue - f.cost) AS profit,
       ROUND(100 * SUM(f.revenue - f.cost) / SUM(f.revenue), 1) AS margin_pct
FROM fact_sales f JOIN dim_customer c ON c.customer_key = f.customer_key
GROUP BY c.segment ORDER BY profit DESC;

-- ---------------------------------------------------------------------
-- PART D: WINDOW FUNCTION RANKINGS
-- ---------------------------------------------------------------------
-- Q4 Rank products by revenue overall (RANK vs DENSE_RANK vs ROW_NUMBER)
SELECT p.product_name, SUM(f.revenue) AS revenue,
       RANK()       OVER (ORDER BY SUM(f.revenue) DESC) AS rnk,
       DENSE_RANK() OVER (ORDER BY SUM(f.revenue) DESC) AS dense_rnk,
       ROW_NUMBER() OVER (ORDER BY SUM(f.revenue) DESC) AS row_num
FROM fact_sales f JOIN dim_product p ON p.product_key = f.product_key
GROUP BY p.product_name;

-- Q5 Rank products WITHIN each category (PARTITION BY)
SELECT category, product_name, revenue,
       RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rank_in_category
FROM (
    SELECT p.category, p.product_name, SUM(f.revenue) AS revenue
    FROM fact_sales f JOIN dim_product p ON p.product_key = f.product_key
    GROUP BY p.category, p.product_name
) t ORDER BY category, rank_in_category;

-- Q6 Top 1 product in every category
SELECT category, product_name, revenue FROM (
    SELECT p.category, p.product_name, SUM(f.revenue) AS revenue,
           RANK() OVER (PARTITION BY p.category ORDER BY SUM(f.revenue) DESC) AS rnk
    FROM fact_sales f JOIN dim_product p ON p.product_key = f.product_key
    GROUP BY p.category, p.product_name
) t WHERE rnk = 1;

-- Q7 Top 3 customers per region
SELECT region, customer_name, revenue, rnk FROM (
    SELECT s.region, c.customer_name, SUM(f.revenue) AS revenue,
           RANK() OVER (PARTITION BY s.region ORDER BY SUM(f.revenue) DESC) AS rnk
    FROM fact_sales f
    JOIN dim_customer c ON c.customer_key = f.customer_key
    JOIN dim_store s    ON s.store_key = f.store_key
    GROUP BY s.region, c.customer_name
) t WHERE rnk <= 3 ORDER BY region, rnk;

-- Q8 Running total of revenue by month
SELECT month_num, month_name, monthly_revenue,
       SUM(monthly_revenue) OVER (ORDER BY month_num) AS running_total
FROM (
    SELECT d.month_num, d.month_name, SUM(f.revenue) AS monthly_revenue
    FROM fact_sales f JOIN dim_date d ON d.date_key = f.date_key
    GROUP BY d.month_num, d.month_name
) m ORDER BY month_num;

-- Q9 Each product's share of its category (window SUM)
SELECT category, product_name, revenue,
       ROUND(100 * revenue / SUM(revenue) OVER (PARTITION BY category), 1) AS pct_of_category
FROM (
    SELECT p.category, p.product_name, SUM(f.revenue) AS revenue
    FROM fact_sales f JOIN dim_product p ON p.product_key = f.product_key
    GROUP BY p.category, p.product_name
) t ORDER BY category, pct_of_category DESC;

-- Q10 Quartile buckets of customers by spend (NTILE)
SELECT customer_name, revenue, NTILE(4) OVER (ORDER BY revenue DESC) AS spend_quartile
FROM (
    SELECT c.customer_name, SUM(f.revenue) AS revenue
    FROM fact_sales f JOIN dim_customer c ON c.customer_key = f.customer_key
    GROUP BY c.customer_name
) t;

-- ---------------------------------------------------------------------
-- PART E: CTE MONTH-OVER-MONTH (MoM) REPORT
-- ---------------------------------------------------------------------
-- Q11 Monthly revenue with previous month and % growth
WITH monthly AS (
    SELECT d.month_num, d.month_name, SUM(f.revenue) AS revenue
    FROM fact_sales f JOIN dim_date d ON d.date_key = f.date_key
    GROUP BY d.month_num, d.month_name
),
with_prev AS (
    SELECT month_num, month_name, revenue,
           LAG(revenue) OVER (ORDER BY month_num) AS prev_revenue
    FROM monthly
)
SELECT month_name, revenue, prev_revenue,
       ROUND(100 * (revenue - prev_revenue) / NULLIF(prev_revenue, 0), 1) AS mom_growth_pct
FROM with_prev ORDER BY month_num;

-- Q12 MoM growth per category (CTE + LAG + PARTITION BY)
WITH cat_month AS (
    SELECT p.category, d.month_num, SUM(f.revenue) AS revenue
    FROM fact_sales f
    JOIN dim_product p ON p.product_key = f.product_key
    JOIN dim_date d    ON d.date_key = f.date_key
    GROUP BY p.category, d.month_num
)
SELECT category, month_num, revenue,
       LAG(revenue) OVER (PARTITION BY category ORDER BY month_num) AS prev_revenue,
       ROUND(100 * (revenue - LAG(revenue) OVER (PARTITION BY category ORDER BY month_num))
             / NULLIF(LAG(revenue) OVER (PARTITION BY category ORDER BY month_num), 0), 1) AS mom_pct
FROM cat_month ORDER BY category, month_num;

-- Q13 Best and worst month using a CTE
WITH monthly AS (
    SELECT d.month_name, SUM(f.revenue) AS revenue
    FROM fact_sales f JOIN dim_date d ON d.date_key = f.date_key
    GROUP BY d.month_name
)
SELECT 'Best month' AS label, month_name, revenue FROM monthly WHERE revenue = (SELECT MAX(revenue) FROM monthly)
UNION ALL
SELECT 'Worst month', month_name, revenue FROM monthly WHERE revenue = (SELECT MIN(revenue) FROM monthly);

-- ---------------------------------------------------------------------
-- PART F: ROLLUP (subtotals and grand total)
-- ---------------------------------------------------------------------
-- Q14 Revenue by category and product, with category subtotals + grand total
SELECT COALESCE(p.category, 'ALL CATEGORIES') AS category,
       COALESCE(p.product_name, 'Subtotal') AS product,
       SUM(f.revenue) AS revenue
FROM fact_sales f JOIN dim_product p ON p.product_key = f.product_key
GROUP BY ROLLUP (p.category, p.product_name)
ORDER BY p.category NULLS LAST, p.product_name NULLS LAST;

-- Q15 Revenue by year > quarter > month with subtotals
SELECT d.year, d.quarter, d.month_name, SUM(f.revenue) AS revenue,
       GROUPING(d.year, d.quarter, d.month_name) AS grouping_level
FROM fact_sales f JOIN dim_date d ON d.date_key = f.date_key
GROUP BY ROLLUP (d.year, d.quarter, d.month_name)
ORDER BY d.year, d.quarter, MIN(d.month_num);

-- Q16 Region > city subtotals
SELECT COALESCE(s.region,'GRAND TOTAL') AS region, COALESCE(s.city,'Region subtotal') AS city,
       SUM(f.revenue) AS revenue
FROM fact_sales f JOIN dim_store s ON s.store_key = f.store_key
GROUP BY ROLLUP (s.region, s.city)
ORDER BY s.region NULLS LAST, s.city NULLS LAST;

-- ---------------------------------------------------------------------
-- PART G: EXPLAIN OPTIMIZATION (before vs after adding indexes)
-- ---------------------------------------------------------------------
-- Make the table big enough to see a difference (about 120k rows)
INSERT INTO fact_sales (date_key, product_key, customer_key, store_key, quantity, revenue, cost)
SELECT date_key, product_key, customer_key, store_key, quantity, revenue, cost
FROM fact_sales, generate_series(1, 99);
ANALYZE fact_sales;

-- BEFORE: no index on date_key, so the database reads every row (Seq Scan)
EXPLAIN ANALYZE
SELECT SUM(revenue) FROM fact_sales WHERE date_key = 20250615;

-- Create indexes on the join / filter columns of the fact table
CREATE INDEX idx_fact_product  ON fact_sales(product_key);
CREATE INDEX idx_fact_date     ON fact_sales(date_key);
CREATE INDEX idx_fact_customer ON fact_sales(customer_key);
CREATE INDEX idx_fact_store    ON fact_sales(store_key);
ANALYZE fact_sales;

-- AFTER: same query now uses the index. Compare "Execution Time" and the plan type
EXPLAIN ANALYZE
SELECT SUM(revenue) FROM fact_sales WHERE date_key = 20250615;

-- Second example: multi-table report plan
EXPLAIN ANALYZE
SELECT p.category, SUM(f.revenue)
FROM fact_sales f
JOIN dim_product p ON p.product_key = f.product_key
WHERE f.date_key BETWEEN 20250101 AND 20250131
GROUP BY p.category;