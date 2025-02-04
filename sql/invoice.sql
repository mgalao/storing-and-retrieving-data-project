USE SushiGo;

-- 1) Invoice Header View
CREATE OR REPLACE VIEW invoice_header AS
SELECT
    -- Customer Information
    p.PAYMENT_ID AS INVOICE_ID,
    p.PAYMENT_DATE AS INVOICE_DATE,
    CONCAT(c.CUSTOMER_FIRST_NAME, ' ', c.CUSTOMER_LAST_NAME) AS CUSTOMER_NAME,
    p.PAYMENT_TIN AS CUSTOMER_TIN,
    CASE 
        WHEN o.ORDER_TYPE = 'Home Delivery' THEN o.ORDER_DELIVERY_ADDRESS
        ELSE 'Pickup Order - No Address'
    END AS DELIVERY_ADDRESS,

    -- Company Information
    'SushiGo!' AS COMPANY_NAME,                                                                                                                                                                
    '213803110' AS COMPANY_TIN,
    'Campus de Campolide, 1070-312 Lisbon' AS COMPANY_ADDRESS,
    'support@sushigo.com' AS COMPANY_EMAIL,
    'www.sushigo.com' AS COMPANY_WEBSITE,
    
    -- Initial Payment Information
    o.ORDER_PRICE AS SUBTOTAL,
    
    -- Discount Information
    ROUND(CASE 
        WHEN o.ORDER_DISCOUNT_PERCENT > 0 THEN 
            o.ORDER_PRICE * o.ORDER_DISCOUNT_PERCENT / 100
        ELSE 
            0
    END, 2) AS DISCOUNT_AMOUNT,

    -- Tax Information
    0.23 AS TAX_RATE,  -- Tax rate (23%)
    ROUND((o.ORDER_PRICE - 
        CASE 
            WHEN o.ORDER_DISCOUNT_PERCENT > 0 THEN 
                o.ORDER_PRICE * o.ORDER_DISCOUNT_PERCENT / 100
            ELSE 
                0
        END) * 0.23, 2) AS TAX_AMOUNT,
    
    -- Final Payment Information
    ROUND(o.ORDER_PRICE - 
        CASE 
            WHEN o.ORDER_DISCOUNT_PERCENT > 0 THEN 
                o.ORDER_PRICE * o.ORDER_DISCOUNT_PERCENT / 100
            ELSE 
                0
        END + ROUND((o.ORDER_PRICE - 
            CASE 
                WHEN o.ORDER_DISCOUNT_PERCENT > 0 THEN 
                    o.ORDER_PRICE * o.ORDER_DISCOUNT_PERCENT / 100
                ELSE 
                    0
            END) * 0.23, 2), 2) AS TOTAL -- Amount paid (after discount and tax)
FROM payments p
JOIN orders o ON p.ORDER_ID = o.ORDER_ID
JOIN customers c ON o.CUSTOMER_ID = c.CUSTOMER_ID
WHERE p.PAYMENT_METHOD IN ('Credit/Debit Card', 'Cash');

---------------------------------------------------------------------------------------------------

-- 2) Invoice Item Details View
CREATE OR REPLACE VIEW invoice_item_details AS
SELECT 
    p.PAYMENT_ID AS INVOICE_ID,
    mi.MENU_ITEM_NAME AS ITEM_NAME,
    oi.ORDER_ITEM_QUANTITY AS ITEM_QUANTITY,
    mi.MENU_ITEM_PRICE AS ITEM_UNIT_PRICE,
    ROUND(oi.ORDER_ITEM_QUANTITY * mi.MENU_ITEM_PRICE, 2) AS ITEM_TOTAL
FROM payments p
JOIN order_items oi ON p.ORDER_ID = oi.ORDER_ID
JOIN menu_items mi ON oi.MENU_ITEM_ID = mi.MENU_ITEM_ID
WHERE p.PAYMENT_METHOD IN ('Credit/Debit Card', 'Cash');

---------------------------------------------------------------------------------------------------

-- Get invoice header
SELECT * 
FROM invoice_header
WHERE INVOICE_ID = 68;

-- Verify payments table
SELECT * FROM payments
WHERE ORDER_ID = 65;
-- Verify orders table
SELECT * FROM orders
WHERE ORDER_ID = 65;
-- Verify customers table
SELECT * FROM customers
WHERE CUSTOMER_ID = 44;



-- Get invoice item details
SELECT * 
FROM invoice_item_details 
WHERE INVOICE_ID = 68;

-- Verify payments table
SELECT * FROM payments
WHERE ORDER_ID = 65;
-- Verify order_items table
SELECT * FROM order_items
WHERE ORDER_ID = 65;
-- Verify menu_items table
SELECT * FROM menu_items
WHERE MENU_ITEM_ID = 9;