USE SushiGo;

-- 1) Identify the most and least profitable menu items (based on ingredient costs versus selling price)

EXPLAIN
SELECT 
    mi.MENU_ITEM_ID AS MENU_ITEM_ID,
    mi.MENU_ITEM_NAME AS MENU_ITEM_NAME,
    mi.MENU_ITEM_PRICE AS SELLING_PRICE,
    ROUND(SUM(mii.MENU_ITEM_INGREDIENT_QUANTITY * i.INGREDIENT_PRICE_PER_UNIT), 2) AS PRODUCTION_COST,
    ROUND(mi.MENU_ITEM_PRICE - SUM(mii.MENU_ITEM_INGREDIENT_QUANTITY * i.INGREDIENT_PRICE_PER_UNIT), 2) AS PROFIT
FROM menu_items mi
LEFT JOIN menu_item_ingredients mii ON mi.MENU_ITEM_ID = mii.MENU_ITEM_ID
LEFT JOIN ingredients i ON mii.INGREDIENT_ID = i.INGREDIENT_ID
GROUP BY mi.MENU_ITEM_ID
ORDER BY PROFIT DESC;

-- Indexes attempted:

-- Creating these indexes made the performance worse
-- by creating each one separately, the indexes were added to possible_keys of the menu_items table
-- but the number of rows evaluated for the table menu_item_ingredients increased (from 1 to 2), it made it worse:
CREATE INDEX idx_menu_items_menu_item_price ON menu_items(MENU_ITEM_PRICE); 
CREATE INDEX INDEX_MENU_ITEMS_MENU_ITEM_NAME ON MENU_ITEMS(MENU_ITEM_NAME); 
CREATE INDEX INDEX_MENU_ITEMS_MENU_ITEM_PRICE_MENU_ITEM_NAME ON MENU_ITEMS(MENU_ITEM_PRICE,MENU_ITEM_NAME); 
CREATE INDEX INDEX_MENU_ITEMS_MENU_ITEM_PRICE_MENU_ITEM_NAME_MENU_ITEM_ID ON MENU_ITEMS(MENU_ITEM_PRICE,MENU_ITEM_NAME,MENU_ITEM_ID); 
CREATE INDEX INDEX_MENU_ITEMS_MENU_ITEM_ID_MENU_ITEM_NAME ON MENU_ITEMS(MENU_ITEM_ID,MENU_ITEM_NAME); 
CREATE INDEX INDEX_MENU_ITEMS_MENU_ITEM_ID_MENU_ITEM_PRICE ON MENU_ITEMS(MENU_ITEM_ID,MENU_ITEM_PRICE); 

---------------------------------------------------------------------------------------------------

-- 2) How can we optimize marketing and logistics strategies based on gender preferences for delivery vs. pickup, considering their average age and spending patterns?

EXPLAIN
SELECT 
    c.CUSTOMER_GENDER AS CUSTOMER_GENDER,
    ROUND(AVG(TIMESTAMPDIFF(YEAR, c.CUSTOMER_DOB, CURDATE())), 0) AS AVERAGE_AGE,
    ROUND(STD(TIMESTAMPDIFF(YEAR, c.CUSTOMER_DOB, CURDATE())), 2) AS STD_AGE,
    MIN(TIMESTAMPDIFF(YEAR, c.CUSTOMER_DOB, CURDATE())) AS MIN_AGE,
    MAX(TIMESTAMPDIFF(YEAR, c.CUSTOMER_DOB, CURDATE())) AS MAX_AGE,
    ROUND(AVG(p.PAYMENT_AMOUNT), 2) AS AVERAGE_SPENT,
    COUNT(o.ORDER_ID) AS TOTAL_ORDERS,
    COUNT(CASE WHEN o.ORDER_TYPE = 'Home Delivery' THEN o.ORDER_ID END) AS TOTAL_DELIVERIES,
    COUNT(CASE WHEN o.ORDER_TYPE = 'Pickup at Store' THEN o.ORDER_ID END) AS TOTAL_PICKUPS,
    ROUND(COUNT(CASE WHEN o.ORDER_TYPE = 'Home Delivery' THEN o.ORDER_ID END) / COUNT(o.ORDER_ID), 2) AS PROP_DELIVERIES,
    ROUND(COUNT(CASE WHEN o.ORDER_TYPE = 'Pickup at Store' THEN o.ORDER_ID END) / COUNT(o.ORDER_ID), 2) AS PROP_PICKUPS
FROM customers c
JOIN orders o ON o.CUSTOMER_ID = c.CUSTOMER_ID
JOIN payments p ON p.ORDER_ID = o.ORDER_ID AND p.PAYMENT_METHOD != 'Store Credit'
GROUP BY c.CUSTOMER_GENDER
ORDER BY AVERAGE_AGE DESC;

-- Indexes attempted:
CREATE INDEX INDEX_PAYMENTS_ORDER_ID_PAYMENT_AMOUNT_PAYMENT_METHOD ON PAYMENTS(ORDER_ID,PAYMENT_AMOUNT,PAYMENT_METHOD);  -- it was chosen as key for the payments table
CREATE INDEX INDEX_PAYMENTS_ORDER_ID_PAYMENT_METHOD ON PAYMENTS(ORDER_ID,PAYMENT_METHOD);  -- it was added to possible keys in the payments table
CREATE INDEX INDEX_PAYMENTS_PAYMENT_METHOD ON PAYMENTS(PAYMENT_METHOD);  -- it was added to possible keys in the payments table
CREATE INDEX INDEX_PAYMENTS_ORDER_ID_PAYMENT_AMOUNT ON PAYMENTS(ORDER_ID,PAYMENT_AMOUNT);  -- it was added to possible keys in the payments table

---------------------------------------------------------------------------------------------------

-- 3) Which customer segments contribute most to revenue and how can we target similar profiles?

EXPLAIN
SELECT 
    CASE
        WHEN TIMESTAMPDIFF(YEAR, c.CUSTOMER_DOB, CURDATE()) BETWEEN 18 AND 25 THEN '18-25'
        WHEN TIMESTAMPDIFF(YEAR, c.CUSTOMER_DOB, CURDATE()) BETWEEN 26 AND 35 THEN '26-35'
        WHEN TIMESTAMPDIFF(YEAR, c.CUSTOMER_DOB, CURDATE()) BETWEEN 36 AND 45 THEN '36-45'
        WHEN TIMESTAMPDIFF(YEAR, c.CUSTOMER_DOB, CURDATE()) BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+' 
    END AS AGE_GROUP,
    o.ORDER_TYPE AS ORDER_TYPE,
    COUNT(o.ORDER_ID) AS TOTAL_ORDERS,
    ROUND(AVG(p.PAYMENT_AMOUNT), 2) AS AVG_ORDER_VALUE, 
    ROUND(SUM(p.PAYMENT_AMOUNT), 2) AS TOTAL_REVENUE,
    ROUND(AVG(c.CUSTOMER_LOYALTY_POINTS), 2) AS AVG_LOYALTY_POINTS,
    ROUND(AVG(o.ORDER_RATING), 2) AS AVG_RATING
FROM customers c
JOIN orders o ON c.CUSTOMER_ID = o.CUSTOMER_ID
JOIN payments p ON p.ORDER_ID = o.ORDER_ID AND p.PAYMENT_METHOD != 'Store Credit'
GROUP BY AGE_GROUP, o.ORDER_TYPE
ORDER BY AGE_GROUP ASC, TOTAL_REVENUE DESC;

-- Indexes attempted:
-- Was chosen as key for the payments table
CREATE INDEX index_payments_order_id_payment_amount_payment_method ON payments(ORDER_ID,PAYMENT_AMOUNT,PAYMENT_METHOD);

---------------------------------------------------------------------------------------------------

-- 4) How do the most popular menu items differ across customers based on their registration date?

EXPLAIN
WITH ranked_popular_menu_items AS (
    SELECT 
        YEAR(c.CUSTOMER_CREATED_DATE) AS CUSTOMER_REGISTRATION_YEAR,
        mi.MENU_ITEM_NAME AS POPULAR_MENU_ITEM_NAME,
        COUNT(oi.MENU_ITEM_ID) AS TOTAL_ORDERS_MENU_ITEM,
        ROW_NUMBER() OVER (
            PARTITION BY YEAR(c.CUSTOMER_CREATED_DATE)
            ORDER BY COUNT(oi.MENU_ITEM_ID) DESC
        ) AS ITEM_RANK
    FROM customers c
    JOIN orders o ON c.CUSTOMER_ID = o.CUSTOMER_ID
    JOIN order_items oi ON o.ORDER_ID = oi.ORDER_ID
    JOIN menu_items mi ON oi.MENU_ITEM_ID = mi.MENU_ITEM_ID
    GROUP BY YEAR(c.CUSTOMER_CREATED_DATE), mi.MENU_ITEM_NAME
)
SELECT 
    CUSTOMER_REGISTRATION_YEAR,
    POPULAR_MENU_ITEM_NAME,
    TOTAL_ORDERS_MENU_ITEM
FROM ranked_popular_menu_items
WHERE ITEM_RANK <= 3
ORDER BY CUSTOMER_REGISTRATION_YEAR DESC, TOTAL_ORDERS_MENU_ITEM DESC;

-- Indexes attempted
CREATE INDEX INDEX_ORDER_ITEMS_ORDER_ID_MENU_ITEM_ID ON ORDER_ITEMS(ORDER_ID,MENU_ITEM_ID);  -- it was chosen as key for the table OI
CREATE INDEX INDEX_ORDERS_ORDER_ID_CUSTOMER_ID ON ORDERS(ORDER_ID,CUSTOMER_ID);  -- it was added to the possible keys in the orders table

---------------------------------------------------------------------------------------------------

-- 5) Analyze the year-over-year performance metrics to identify trends in customer growth, spending, and refunds

EXPLAIN
SELECT
    YEAR(o.ORDER_DATE) AS YEAR,
    COUNT(DISTINCT c.CUSTOMER_ID) AS TOTAL_CUSTOMERS,
    COUNT(DISTINCT CASE 
        WHEN YEAR(c.CUSTOMER_CREATED_DATE) = YEAR(o.ORDER_DATE) THEN c.CUSTOMER_ID
        ELSE NULL
    END) AS NEW_CUSTOMERS,
    COUNT(DISTINCT CASE 
        WHEN YEAR(c.CUSTOMER_CREATED_DATE) < YEAR(o.ORDER_DATE) THEN c.CUSTOMER_ID
        ELSE NULL
    END) AS RETURNING_CUSTOMERS,
    COUNT(DISTINCT e.EMPLOYEE_ID) AS TOTAL_EMPLOYEES,
    COUNT(DISTINCT m.MENU_ITEM_ID) AS TOTAL_MENU_ITEMS,
    COUNT(o.ORDER_ID) AS TOTAL_ORDERS,
    COUNT(CASE WHEN o.ORDER_TYPE = 'Home Delivery' THEN o.ORDER_ID ELSE NULL END) AS TOTAL_DELIVERIES,
    COUNT(CASE WHEN o.ORDER_TYPE = 'Pickup at Store' THEN o.ORDER_ID ELSE NULL END) AS TOTAL_PICKUPS,
    ROUND(SUM(p.PAYMENT_AMOUNT), 2) AS TOTAL_PAYMENT_AMOUNT,
    ROUND(AVG(p.PAYMENT_AMOUNT), 2) AS AVG_PAYMENT_AMOUNT,
    ROUND(COUNT(r.REFUND_ID), 2) AS TOTAL_REFUNDS,
    ROUND(AVG(o.ORDER_RATING), 2) AS AVG_RATING
FROM orders o
LEFT JOIN customers c ON o.CUSTOMER_ID = c.CUSTOMER_ID
LEFT JOIN order_items oi ON o.ORDER_ID = oi.ORDER_ID
LEFT JOIN menu_items m ON oi.MENU_ITEM_ID = m.MENU_ITEM_ID
JOIN payments p ON p.ORDER_ID = o.ORDER_ID AND p.PAYMENT_METHOD != 'Store Credit'
LEFT JOIN refunds r ON r.PAYMENT_ID = p.PAYMENT_ID
LEFT JOIN employees e ON p.EMPLOYEE_ID = e.EMPLOYEE_ID
GROUP BY YEAR(o.ORDER_DATE)
ORDER BY YEAR DESC;

-- Indexes attempted
-- Was chosen as key for the payments table
CREATE INDEX idx_payments_order_id_payment_method ON PAYMENTS(ORDER_ID, PAYMENT_METHOD);

-- it used as key, one previously created composite index (INDEX_ORDER_ITEMS_ORDER_ID_MENU_ITEM_ID) for the OI table
-- and it appears in Extra ('Using index'), if we ran our query without this composite key it appeared Null in Extra,
-- with the key being order_id
-- all of the below indexes were put in the possible keys of the orders table but none was chosen as key
CREATE INDEX INDEX_ORDERS_ORDER_DATE ON ORDERS(ORDER_DATE); 
CREATE INDEX INDEX_ORDERS_ORDER_ID_ORDER_DATE ON ORDERS(ORDER_ID,ORDER_DATE);
CREATE INDEX INDEX_ORDERS_ORDER_ID_ORDER_DATE_ORDER_RATING ON ORDERS(ORDER_ID,ORDER_DATE,ORDER_RATING);
CREATE INDEX INDEX_ORDERS_ORDER_ID_ORDER_DATE_ORDER_RATING_ORDER_TYPE ON ORDERS(ORDER_ID,ORDER_DATE,ORDER_RATING,ORDER_TYPE);
CREATE INDEX INDEX_ORDERS_CUSTOMER_ID_ORDER_DATE ON ORDERS(CUSTOMER_ID, ORDER_DATE);