--- Select Data
SELECT * FROM orders_dataset;
SELECT * FROM customers_dataset;
SELECT * FROM geolocation_dataset;
SELECT * FROM order_items_dataset;
SELECT * FROM order_payments_dataset;
SELECT * FROM product_dataset;
SELECT * FROM review_dataset;
SELECT * FROM sellers_dataset;   


---- Product Sales Analysis by Category

SELECT product_category_name, 
		COUNT(order_id) AS total_order 
	FROM order_items_dataset AS oi
		LEFT JOIN product_dataset AS pd 
		ON oi.product_id = pd.product_id
GROUP BY product_category_name
ORDER BY total_order DESC;

---- Product Pricing Analysis

SELECT pd.product_category_name,
       MAX(oi.price) AS max_price,
       MIN(oi.price) AS min_price,
       AVG(oi.price) AS Average_price
	FROM order_items_dataset AS oi
	LEFT JOIN product_dataset AS pd 
    ON oi.product_id = pd.product_id
GROUP BY pd.product_category_name
ORDER BY product_category_name ASC;

--- Sales Timing Analysis

SELECT DATE_FORMAT(order_purchase_timestamp, '%M') AS month_name,
        EXTRACT(YEAR FROM order_purchase_timestamp) AS years,
        COUNT(order_id) AS total_order
	FROM orders_dataset
GROUP BY month_name, years
ORDER BY years DESC;


--- Payment Method Analysis
SELECT payment_type,
		COUNT(payment_value) AS total_payment
    FROM order_payments_dataset
GROUP BY payment_type
ORDER BY total_payment DESC;

--- Installment Payment Analysis

SELECT total_installments,
        COUNT(order_id) numbers_orders
    FROM
(SELECT order_id,
        SUM(payment_installments) AS total_installments
	FROM order_payments_dataset
 GROUP BY order_id
) AS sbqr
GROUP BY total_installments 
ORDER BY total_installments;


--- Delivery Timeliness Analysis

SELECT order_id,
       order_delivered_customer_date,
       order_estimated_delivery_date,
       TIMESTAMPDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date) AS delivery_diff_days,
       CASE
           WHEN TIMESTAMPDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date) < 0 THEN 'Lebih Awal'
           WHEN TIMESTAMPDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date) = 0 THEN 'Tepat Waktu'
           ELSE 'Terlambat'
       END AS delivery_status
	FROM orders_dataset
WHERE order_delivered_customer_date IS NOT NULL AND order_estimated_delivery_date IS NOT NULL;

--- Customer Demographics Analysis

SELECT customer_city, 
       customer_state, 
       COUNT(customer_zip_code_prefix) AS number_of_customers_zip_code
	FROM customers_dataset
GROUP BY customer_city, customer_state
ORDER BY customer_state, customer_city;


--- Customer Satisfaction Analysis Based on Review Scores

SELECT order_id, review_id,
    CASE WHEN review_score >= 4 THEN 'hight'
         ELSE 'low'
        END AS rate_score
	FROM review_dataset;
    

--- Seller Performance Analysis

SELECT o.seller_id,
       COUNT(o.order_item_id) AS total_order
	FROM order_items_dataset AS o
	LEFT JOIN sellers_dataset s
	ON o.seller_id = s.seller_id
GROUP BY o.seller_id;


--- Seller Location Analysis
SELECT DISTINCT seller_state, 
       seller_city, 
       COUNT(seller_id) AS total_seller 
	FROM sellers_dataset 
GROUP BY seller_state, seller_city
ORDER BY seller_state ASC;


--- How many unique customers are registered in each city?

SELECT s.seller_city,
         COUNT( DISTINCT od.customer_id) AS unique_customer
	FROM sellers_dataset AS s
	LEFT JOIN order_items_dataset AS O
	ON s.seller_id = o.seller_id
	LEFT JOIN orders_dataset As od 
	ON o.order_id = od.order_id
GROUP BY s.seller_city;


--- Which five postal codes have the highest number of customers?
SELECT s.seller_city, 
        seller_zip_code_prefix,
		COUNT(od.customer_id) AS unique_customer
	FROM sellers_dataset AS s
	LEFT JOIN order_items_dataset AS O
	ON s.seller_id = o.seller_id
	LEFT JOIN orders_dataset As od 
	ON o.order_id = od.order_id
GROUP BY s.seller_city, seller_zip_code_prefix
ORDER BY unique_customer DESC
LIMIT 5;


--- Whats the total payment value for each payment method?

SELECT payment_type,
		COUNT(payment_value) AS total_payment_value
	FROM order_payments_dataset
 GROUP BY payment_type;
 

--- How many orders (order_id) are registered under each order status (order_status)?

SELECT order_status, 
        SUM(order_id) AS amount_order
	FROM orders_dataset
GROUP BY order_status
ORDER BY amount_order ASC;


--- How many products (product_id) are sold by each seller (seller_id)?

SELECT seller_id, 
        SUM(product_id) AS amount_product
	FROM order_items_dataset
GROUP BY seller_id;


--- What is the average product weight (product_weight_g) for each product length (product_length_cm)?

SELECT product_length_cm,
		ROUND(AVG(product_weight_g), 2) AS average_weight
 FROM product_dataset
GROUP BY product_length_cm;


--- What are the top five products with the highest number of photos (product_photos_qty)?

SELECT product_category_name, 
        SUM(product_photos_qty) AS amount_photos 
	FROM product_dataset
GROUP BY product_category_name
ORDER BY amount_photos DESC
LIMIT 5;


--- How many reviews (review_id) has each product (product_id) received?

SELECT o.product_id, 
        pd.product_category_name,
        SUM(review_id) AS amount_review
	FROM review_dataset as r
	LEFT JOIN order_items_dataset AS o
	ON r.order_id = o.order_id
	LEFT JOIN product_dataset pd 
	ON o.product_id = pd.product_id
GROUP BY o.product_id, pd.product_category_name;



--- 1. Task • Annual Customer Activity Growth Analysis

--- a) Show the average number of monthly active users for each year

SELECT 
		EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
		EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
		COUNT(DISTINCT customer_id) AS monthly_active_users
	FROM orders_dataset
GROUP BY 
		EXTRACT(YEAR FROM order_purchase_timestamp), 
		EXTRACT(MONTH FROM order_purchase_timestamp)
ORDER BY 
    year, month;


--- b) Show the number of new customers for each year

SELECT 
		YEAR(first_order_timestamp) AS year,
		COUNT(customer_id) AS new_customers_count
	FROM (
    SELECT 
        customer_id,
        MIN(order_purchase_timestamp) AS first_order_timestamp
    FROM 
        orders_dataset
    GROUP BY 
        customer_id
) AS first_orders
GROUP BY 
    YEAR(first_order_timestamp)
ORDER BY 
    year;


--- c) Show the number of customers who made more than one purchase (repeat orders) for each year

SELECT order_id,
		amount_customer
	FROM
		(SELECT order_id, SUM(customer_id) AS amount_customer
	FROM orders_dataset
	GROUP BY order_id
	) AS amount_order
	WHERE amount_customer > 1
GROUP BY order_id;



--- d) Show the average number of orders placed by customers for each year

WITH orders_per_customer_per_year AS (
    SELECT 
        customer_id,
        EXTRACT(year FROM order_purchase_timestamp) AS years,
        COUNT(order_id) AS order_count
    FROM 
        orders_dataset
    GROUP BY 
        customer_id, years
)
SELECT 
		years,
		AVG(order_count) AS average_orders_per_customer
	FROM 
    orders_per_customer_per_year
GROUP BY 
    years
ORDER BY 
    years;


--- Task • Annual Product Category Quality Analysis

--- a) Create a table that includes the total company revenue for each year
 
SELECT od.order_status,
       SUM(Revenue) AS total_revenue,
       years
	FROM
    (SELECT oi.order_id,
            SUM(oi.price + oi.freight_value) AS Revenue,
            EXTRACT(YEAR FROM od.order_purchase_timestamp) AS years
	FROM order_items_dataset AS oi
	LEFT JOIN orders_dataset AS od ON oi.order_id = od.order_id
     GROUP BY oi.order_id, years
    ) AS revenue_per_order
LEFT JOIN orders_dataset AS od ON revenue_per_order.order_id = od.order_id
GROUP BY od.order_status, years;


---- b) Create a table that includes the total number of canceled orders for each year

SELECT EXTRACT(YEAR FROM order_purchase_timestamp) AS years,
       COUNT(*) AS total_canceled_orders
    FROM orders_dataset
    WHERE order_status = 'canceled'
    GROUP BY years
    ORDER BY years;
    
    

--- c) Create a table that lists the product categories that generate the highest total revenue for each year

WITH yearly_revenue AS (
    SELECT
        p.product_category_name AS kategori,
        EXTRACT(YEAR FROM o.order_purchase_timestamp) AS tahun,
        SUM(oi.price + oi.freight_value) AS total_pendapatan,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.order_purchase_timestamp) ORDER BY SUM(oi.price + oi.freight_value) DESC) AS ranking
    FROM
        orders_dataset o
        JOIN order_items_dataset oi ON o.order_id = oi.order_id
        JOIN product_dataset p ON oi.product_id = p.product_id
    GROUP BY
        kategori, tahun
)
SELECT
		kategori,
		tahun,
		total_pendapatan
	FROM
    yearly_revenue
	WHERE
    ranking = 1;
    


--- d) Create a table that lists the product categories with the highest number of canceled orders for each year

WITH cancelled_orders AS (
    SELECT
        p.product_category_name AS kategori,
        EXTRACT(YEAR FROM o.order_purchase_timestamp) AS tahun,
        COUNT(o.order_id) AS jumlah_cancel_order
    FROM
        orders_dataset o
        JOIN order_items_dataset oi ON o.order_id = oi.order_id
        JOIN product_dataset p ON oi.product_id = p.product_id
    WHERE
        o.order_status = 'canceled'
    GROUP BY
        kategori, tahun
),
ranked_cancelled_orders AS (
    SELECT
        kategori,
        tahun,
        jumlah_cancel_order,
        ROW_NUMBER() OVER (PARTITION BY tahun ORDER BY jumlah_cancel_order DESC) AS ranking
    FROM
        cancelled_orders
)
SELECT
		kategori,
		tahun,
		jumlah_cancel_order
	FROM
		ranked_cancelled_orders
	WHERE
    ranking = 1;
    

---- Show the total usage count of each payment type all-time

SELECT payment_type, 
       COUNT(*) AS usage_count
	FROM order_payments_dataset
GROUP BY payment_type
ORDER BY usage_count DESC;


--- Menampilkan detail informasi jumlah penggunaan masing-masing tipe pembayaran untuk setiap tahun
SELECT YEAR(order_purchase_timestamp) AS year, 
       payment_type, 
       COUNT(*) AS usage_count
	FROM orders_dataset o
	JOIN order_payments_dataset op ON o.order_id = op.order_id
GROUP BY YEAR(order_purchase_timestamp), payment_type
ORDER BY year, usage_count DESC;


SELECT EXTRACT(YEAR FROM order_purchase_timestamp) AS years,
		EXTRACT(MONTH FROM order_purchase_timestamp) AS months,
        p.product_category_name,
		oi.price
	FROM orders_dataset AS o
	LEFT JOIN order_items_dataset AS oi
	ON o.order_id = oi.order_id
	LEFT JOIN product_dataset AS p
	ON p.product_id = oi.product_id
GROUP BY years,months, oi.price, p.product_category_name