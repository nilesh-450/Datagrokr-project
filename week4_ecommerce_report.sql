-- =====================================================================
-- WEEK 4: SQL E-COMMERCE REPORT   (PostgreSQL)
-- Covers: DDL constraints, sample data, JOINs, NULL handling,
--         top products, customer spend  (35+ queries)
-- =====================================================================

DROP TABLE IF EXISTS order_items, payments, orders, products, categories, customers CASCADE;

-- ---------------------------------------------------------------------
-- PART A: DDL WITH CONSTRAINTS
-- ---------------------------------------------------------------------
CREATE TABLE customers (
    customer_id   SERIAL PRIMARY KEY,
    full_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(120) NOT NULL UNIQUE,
    city          VARCHAR(60),
    phone         VARCHAR(15),                       -- can be NULL
    signup_date   DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE categories (
    category_id   SERIAL PRIMARY KEY,
    category_name VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE products (
    product_id    SERIAL PRIMARY KEY,
    product_name  VARCHAR(100) NOT NULL,
    category_id   INT NOT NULL REFERENCES categories(category_id),
    price         NUMERIC(10,2) NOT NULL CHECK (price > 0),
    stock_qty     INT NOT NULL DEFAULT 0 CHECK (stock_qty >= 0)
);

CREATE TABLE orders (
    order_id      SERIAL PRIMARY KEY,
    customer_id   INT NOT NULL REFERENCES customers(customer_id),
    order_date    DATE NOT NULL,
    status        VARCHAR(20) NOT NULL DEFAULT 'PLACED'
                  CHECK (status IN ('PLACED','SHIPPED','DELIVERED','CANCELLED')),
    discount_pct  NUMERIC(5,2) CHECK (discount_pct BETWEEN 0 AND 100)  -- NULL = none
);

CREATE TABLE order_items (
    order_id      INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id    INT NOT NULL REFERENCES products(product_id),
    quantity      INT NOT NULL CHECK (quantity > 0),
    unit_price    NUMERIC(10,2) NOT NULL CHECK (unit_price > 0),
    PRIMARY KEY (order_id, product_id)
);

CREATE TABLE payments (
    payment_id    SERIAL PRIMARY KEY,
    order_id      INT NOT NULL UNIQUE REFERENCES orders(order_id),
    method        VARCHAR(20) NOT NULL CHECK (method IN ('UPI','CARD','COD','NETBANKING')),
    paid_on       DATE                                  -- NULL = not paid yet
);

-- ALTER TABLE examples (DDL)
ALTER TABLE customers ADD COLUMN loyalty_points INT DEFAULT 0;
ALTER TABLE customers ADD CONSTRAINT chk_points CHECK (loyalty_points >= 0);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_items_product  ON order_items(product_id);

-- ---------------------------------------------------------------------
-- PART B: SAMPLE DATA
-- ---------------------------------------------------------------------
INSERT INTO customers (full_name, email, city, phone, signup_date) VALUES
('Aarav Sharma',  'aarav@mail.com',  'Bengaluru', '9876500001', '2025-01-10'),
('Diya Nair',     'diya@mail.com',   'Kochi',     '9876500002', '2025-02-14'),
('Rohan Gowda',   'rohan@mail.com',  'Mysuru',    NULL,         '2025-03-05'),
('Sneha Patil',   'sneha@mail.com',  'Pune',      '9876500004', '2025-03-22'),
('Kabir Khan',    'kabir@mail.com',  'Mumbai',    '9876500005', '2025-04-18'),
('Meera Iyer',    'meera@mail.com',  'Chennai',   NULL,         '2025-05-09'),
('Vikram Rao',    'vikram@mail.com', NULL,        '9876500007', '2025-06-01'),
('Ananya Das',    'ananya@mail.com', 'Kolkata',   '9876500008', '2025-06-20'),
('Ishaan Verma',  'ishaan@mail.com', 'Delhi',     '9876500009', '2025-07-15'),
('Priya Menon',   'priya@mail.com',  'Bengaluru', '9876500010', '2025-08-02');   -- Priya never orders

INSERT INTO categories (category_name) VALUES
('Electronics'),('Books'),('Fashion'),('Home & Kitchen'),('Toys');   -- Toys has no products

INSERT INTO products (product_name, category_id, price, stock_qty) VALUES
('Wireless Earbuds',   1, 2499.00, 50),
('Smartphone X',       1, 18999.00, 20),
('Laptop Stand',       1, 899.00, 75),
('SQL Made Easy',      2, 450.00, 100),
('Python Crash Course',2, 650.00, 80),
('Cotton T-Shirt',     3, 599.00, 120),
('Running Shoes',      3, 3299.00, 40),
('Mixer Grinder',      4, 3999.00, 25),
('Water Bottle',       4, 349.00, 200),
('Backpack',           3, 1499.00, 0);                -- out of stock, never sold

INSERT INTO orders (customer_id, order_date, status, discount_pct) VALUES
(1,'2025-09-01','DELIVERED',10),
(1,'2025-09-15','DELIVERED',NULL),
(2,'2025-09-03','DELIVERED',5),
(3,'2025-09-10','CANCELLED',NULL),
(4,'2025-09-12','DELIVERED',NULL),
(5,'2025-10-01','SHIPPED',15),
(5,'2025-10-05','PLACED',NULL),
(6,'2025-10-07','DELIVERED',NULL),
(8,'2025-10-10','DELIVERED',10),
(9,'2025-10-12','PLACED',NULL),
(2,'2025-10-14','DELIVERED',NULL),
(1,'2025-10-20','SHIPPED',5);

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1,1,1,2499),(1,4,2,450),
(2,2,1,18999),
(3,5,1,650),(3,9,2,349),
(4,6,3,599),
(5,7,1,3299),(5,6,2,599),
(6,8,1,3999),(6,3,1,899),
(7,1,2,2499),
(8,4,1,450),(8,5,1,650),
(9,2,1,18999),(9,9,1,349),
(10,6,1,599),(10,7,1,3299),
(11,1,1,2499),(11,3,2,899),
(12,8,1,3999),(12,4,3,450);

INSERT INTO payments (order_id, method, paid_on) VALUES
(1,'UPI','2025-09-01'),(2,'CARD','2025-09-15'),(3,'UPI','2025-09-03'),
(5,'COD','2025-09-14'),(6,'NETBANKING','2025-10-01'),(7,'COD',NULL),
(8,'UPI','2025-10-07'),(9,'CARD','2025-10-10'),(10,'COD',NULL),
(11,'UPI','2025-10-14'),(12,'CARD','2025-10-20');

-- ---------------------------------------------------------------------
-- PART C: 35+ QUERIES
-- ---------------------------------------------------------------------

-- ===== Section 1: Basic SELECT / filtering (Q1-Q8) =====
-- Q1  All customers
SELECT * FROM customers;
-- Q2  Customers from Bengaluru
SELECT full_name, email FROM customers WHERE city = 'Bengaluru';
-- Q3  Products priced above 1000, costliest first
SELECT product_name, price FROM products WHERE price > 1000 ORDER BY price DESC;
-- Q4  Products between 400 and 1000
SELECT product_name, price FROM products WHERE price BETWEEN 400 AND 1000;
-- Q5  Customers whose names start with 'A'
SELECT full_name FROM customers WHERE full_name LIKE 'A%';
-- Q6  Orders placed in October 2025
SELECT * FROM orders WHERE order_date >= '2025-10-01' AND order_date < '2025-11-01';
-- Q7  Orders that are shipped or delivered
SELECT order_id, status FROM orders WHERE status IN ('SHIPPED','DELIVERED');
-- Q8  Five cheapest products
SELECT product_name, price FROM products ORDER BY price ASC LIMIT 5;

-- ===== Section 2: NULL handling (Q9-Q15) =====
-- Q9  Customers with no phone number
SELECT full_name FROM customers WHERE phone IS NULL;
-- Q10 Customers with a city recorded
SELECT full_name, city FROM customers WHERE city IS NOT NULL;
-- Q11 Show 'Unknown' where city is missing
SELECT full_name, COALESCE(city, 'Unknown') AS city FROM customers;
-- Q12 Show 'No phone' where missing
SELECT full_name, COALESCE(phone, 'No phone') AS contact FROM customers;
-- Q13 Treat missing discount as 0
SELECT order_id, COALESCE(discount_pct, 0) AS discount FROM orders;
-- Q14 Orders not yet paid (NULL paid date)
SELECT order_id, method FROM payments WHERE paid_on IS NULL;
-- Q15 NULLIF: avoid divide-by-zero when finding average price per stock unit
SELECT product_name, price / NULLIF(stock_qty, 0) AS price_per_stock_unit FROM products;

-- ===== Section 3: JOINs (Q16-Q23) =====
-- Q16 INNER JOIN: orders with customer names
SELECT o.order_id, c.full_name, o.order_date, o.status
FROM orders o JOIN customers c ON c.customer_id = o.customer_id;
-- Q17 Products with their category
SELECT p.product_name, c.category_name
FROM products p JOIN categories c ON c.category_id = p.category_id;
-- Q18 LEFT JOIN: all customers, including those who never ordered
SELECT c.full_name, o.order_id
FROM customers c LEFT JOIN orders o ON o.customer_id = c.customer_id;
-- Q19 Customers who never placed an order
SELECT c.full_name
FROM customers c LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;
-- Q20 Products never sold
SELECT p.product_name
FROM products p LEFT JOIN order_items oi ON oi.product_id = p.product_id
WHERE oi.order_id IS NULL;
-- Q21 RIGHT JOIN: every category, even with no products
SELECT cat.category_name, p.product_name
FROM products p RIGHT JOIN categories cat ON cat.category_id = p.category_id;
-- Q22 Categories that have no products
SELECT cat.category_name
FROM categories cat LEFT JOIN products p ON p.category_id = cat.category_id
WHERE p.product_id IS NULL;
-- Q23 Full order detail: customer, product, quantity (4-table JOIN)
SELECT o.order_id, c.full_name, p.product_name, oi.quantity, oi.unit_price
FROM orders o
JOIN customers c   ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p    ON p.product_id = oi.product_id
ORDER BY o.order_id;

-- ===== Section 4: Aggregates & top products (Q24-Q30) =====
-- Q24 Total number of orders
SELECT COUNT(*) AS total_orders FROM orders;
-- Q25 Orders per status
SELECT status, COUNT(*) AS orders FROM orders GROUP BY status;
-- Q26 Top 5 products by units sold
SELECT p.product_name, SUM(oi.quantity) AS units_sold
FROM order_items oi JOIN products p ON p.product_id = oi.product_id
GROUP BY p.product_name ORDER BY units_sold DESC LIMIT 5;
-- Q27 Top 5 products by revenue
SELECT p.product_name, SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi JOIN products p ON p.product_id = oi.product_id
GROUP BY p.product_name ORDER BY revenue DESC LIMIT 5;
-- Q28 Revenue per category
SELECT c.category_name, SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN categories c ON c.category_id = p.category_id
GROUP BY c.category_name ORDER BY revenue DESC;
-- Q29 Average, min and max product price per category
SELECT c.category_name, ROUND(AVG(p.price),2) AS avg_price, MIN(p.price) AS min_price, MAX(p.price) AS max_price
FROM products p JOIN categories c ON c.category_id = p.category_id
GROUP BY c.category_name;
-- Q30 Categories with more than 2 products (HAVING)
SELECT c.category_name, COUNT(*) AS product_count
FROM products p JOIN categories c ON c.category_id = p.category_id
GROUP BY c.category_name HAVING COUNT(*) > 2;

-- ===== Section 5: Customer spend (Q31-Q38) =====
-- Q31 Total spend per customer (before discount)
SELECT c.full_name, SUM(oi.quantity * oi.unit_price) AS total_spend
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY c.full_name ORDER BY total_spend DESC;
-- Q32 Spend after discount, ignoring cancelled orders (NULL discount treated as 0)
SELECT c.full_name,
       ROUND(SUM(oi.quantity * oi.unit_price * (1 - COALESCE(o.discount_pct,0)/100)), 2) AS net_spend
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status <> 'CANCELLED'
GROUP BY c.full_name ORDER BY net_spend DESC;
-- Q33 All customers with spend, 0 for those who never bought
SELECT c.full_name, COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_spend
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
LEFT JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY c.full_name ORDER BY total_spend DESC;
-- Q34 Number of orders per customer
SELECT c.full_name, COUNT(o.order_id) AS order_count
FROM customers c LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.full_name ORDER BY order_count DESC;
-- Q35 Average order value
SELECT ROUND(AVG(order_total),2) AS avg_order_value FROM (
    SELECT order_id, SUM(quantity * unit_price) AS order_total FROM order_items GROUP BY order_id
) t;
-- Q36 Customers who spent more than the overall average (subquery)
SELECT full_name, total_spend FROM (
    SELECT c.full_name, SUM(oi.quantity * oi.unit_price) AS total_spend
    FROM customers c JOIN orders o ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id GROUP BY c.full_name
) s
WHERE total_spend > (
    SELECT AVG(total) FROM (SELECT SUM(quantity*unit_price) AS total FROM order_items GROUP BY order_id) x
);
-- Q37 Top 3 customers by spend
SELECT c.full_name, SUM(oi.quantity * oi.unit_price) AS total_spend
FROM customers c JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY c.full_name ORDER BY total_spend DESC LIMIT 3;
-- Q38 Spend by city (missing city shown as Unknown)
SELECT COALESCE(c.city,'Unknown') AS city, SUM(oi.quantity * oi.unit_price) AS total_spend
FROM customers c JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY COALESCE(c.city,'Unknown') ORDER BY total_spend DESC;

-- ===== Section 6: Payments, dates, subqueries, extras (Q39-Q46) =====
-- Q39 Orders by payment method
SELECT method, COUNT(*) AS orders FROM payments GROUP BY method ORDER BY orders DESC;
-- Q40 Delivered orders still marked unpaid (data-quality check)
SELECT o.order_id FROM orders o JOIN payments p ON p.order_id = o.order_id
WHERE o.status = 'DELIVERED' AND p.paid_on IS NULL;
-- Q41 Orders with no payment record
SELECT o.order_id, o.status FROM orders o LEFT JOIN payments p ON p.order_id = o.order_id
WHERE p.payment_id IS NULL;
-- Q42 Monthly order count
SELECT TO_CHAR(order_date,'YYYY-MM') AS month, COUNT(*) AS orders
FROM orders GROUP BY TO_CHAR(order_date,'YYYY-MM') ORDER BY month;
-- Q43 Products costlier than the average product price
SELECT product_name, price FROM products WHERE price > (SELECT AVG(price) FROM products);
-- Q44 Customers who bought Electronics (EXISTS)
SELECT c.full_name FROM customers c WHERE EXISTS (
    SELECT 1 FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p ON p.product_id = oi.product_id
    JOIN categories cat ON cat.category_id = p.category_id
    WHERE o.customer_id = c.customer_id AND cat.category_name = 'Electronics');
-- Q45 Spend band per customer using CASE
SELECT full_name, total_spend,
  CASE WHEN total_spend >= 15000 THEN 'High'
       WHEN total_spend >= 5000  THEN 'Medium'
       ELSE 'Low' END AS spend_band
FROM (
    SELECT c.full_name, COALESCE(SUM(oi.quantity*oi.unit_price),0) AS total_spend
    FROM customers c LEFT JOIN orders o ON o.customer_id = c.customer_id
    LEFT JOIN order_items oi ON oi.order_id = o.order_id GROUP BY c.full_name) t
ORDER BY total_spend DESC;
-- Q46 Low-stock products (fewer than 30 units) with stock status
SELECT product_name, stock_qty,
       CASE WHEN stock_qty = 0 THEN 'OUT OF STOCK' ELSE 'LOW' END AS status
FROM products WHERE stock_qty < 30 ORDER BY stock_qty;

-- ---------------------------------------------------------------------
-- PART D: CONSTRAINT TESTS (each of these should FAIL - screenshot the errors)
-- ---------------------------------------------------------------------
-- Run one at a time; they are commented out so the main script runs cleanly.
-- INSERT INTO products (product_name, category_id, price) VALUES ('Bad', 1, -5);        -- CHECK fails
-- INSERT INTO customers (full_name, email) VALUES ('Dup', 'aarav@mail.com');            -- UNIQUE fails
-- INSERT INTO orders (customer_id, order_date) VALUES (999, '2025-11-01');              -- FOREIGN KEY fails
-- INSERT INTO orders (customer_id, order_date, status) VALUES (1,'2025-11-01','LOST');  -- CHECK fails
-- INSERT INTO customers (email) VALUES ('noname@mail.com');                             -- NOT NULL fails
