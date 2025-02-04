DROP TRIGGER IF EXISTS logs_menu_update;

-- 1) Trigger to log updates to menu items price and availability
DELIMITER $$
CREATE TRIGGER logs_menu_update
AFTER UPDATE ON menu_items
FOR EACH ROW
BEGIN
    -- Check if either the price or availability has changed
    IF OLD.MENU_ITEM_PRICE != NEW.MENU_ITEM_PRICE 
       OR OLD.MENU_ITEM_IS_AVAILABLE != NEW.MENU_ITEM_IS_AVAILABLE THEN
       -- Insert a log entry
        INSERT INTO menu_item_logs (
            MENU_ITEM_ID,
            LOG_DATE,
            LOG_TYPE,
            MENU_ITEM_OLD_PRICE,
            MENU_ITEM_NEW_PRICE,
            MENU_ITEM_OLD_AVAILABILITY,
            MENU_ITEM_NEW_AVAILABILITY
        )
        VALUES (
            NEW.MENU_ITEM_ID,
            CURRENT_TIMESTAMP,
            CASE 
                WHEN OLD.MENU_ITEM_PRICE != NEW.MENU_ITEM_PRICE 
                     AND OLD.MENU_ITEM_IS_AVAILABLE != NEW.MENU_ITEM_IS_AVAILABLE 
                     THEN 'Price and Availability Changed'
                WHEN OLD.MENU_ITEM_PRICE != NEW.MENU_ITEM_PRICE 
                     THEN 'Price Changed'
                WHEN OLD.MENU_ITEM_IS_AVAILABLE != NEW.MENU_ITEM_IS_AVAILABLE 
                     THEN 'Availability Changed'
            END,
            OLD.MENU_ITEM_PRICE,
            NEW.MENU_ITEM_PRICE,
            OLD.MENU_ITEM_IS_AVAILABLE,
            NEW.MENU_ITEM_IS_AVAILABLE
        );
    END IF;
END$$
DELIMITER ;

-- Test updating price
UPDATE menu_items 
SET
	MENU_ITEM_PRICE = 24,
	EMPLOYEE_ID = 1
WHERE MENU_ITEM_ID = 1;

-- Test updating availability
UPDATE menu_items
SET
	MENU_ITEM_IS_AVAILABLE = 0,
	EMPLOYEE_ID = 2 
WHERE MENU_ITEM_ID = 1;

-- Test updating price and availability
UPDATE menu_items 
SET
	MENU_ITEM_PRICE = 28, 
    MENU_ITEM_IS_AVAILABLE = 1,
	EMPLOYEE_ID = 3
WHERE MENU_ITEM_ID = 1;

-- Verify the menu items table
SELECT * FROM menu_items;

-- Verify the log table
SELECT * FROM menu_item_logs;

---------------------------------------------------------------------------------------------------

DROP TRIGGER IF EXISTS stock_update_after_order;

-- 2) Trigger to update ingredient stock after an order is inserted

DELIMITER $$
CREATE TRIGGER stock_update_after_order
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    -- Deduct the required ingredient quantities
    -- based on the ordered menu item
    UPDATE ingredients i
    INNER JOIN menu_item_ingredients mi 
        ON i.INGREDIENT_ID = mi.INGREDIENT_ID
    SET i.INGREDIENT_STOCK_QUANTITY = 
        i.INGREDIENT_STOCK_QUANTITY -
			(mi.MENU_ITEM_INGREDIENT_QUANTITY * NEW.ORDER_ITEM_QUANTITY),
        i.INGREDIENT_LAST_UPDATED = CURRENT_TIMESTAMP
    WHERE mi.MENU_ITEM_ID = NEW.MENU_ITEM_ID;
END$$
DELIMITER ;

-- Test the trigger

-- Step 1: Add a new order to the orders table
INSERT INTO orders (
    ORDER_ID, 
    ORDER_DATE, 
    ORDER_PRICE, 
    ORDER_DISCOUNT_PERCENT, 
    ORDER_TYPE, 
    ORDER_DELIVERY_ADDRESS, 
    ORDER_RATING, 
    CUSTOMER_ID
)
VALUES
(101, '2024-12-15', 84.00, 0, 'Home Delivery', 'Rua Augusta 100, Lisbon', 5, 12);

-- Step 2: Add the ordered menu item(s) to the order_items table
INSERT INTO order_items (ORDER_ID, MENU_ITEM_ID, ORDER_ITEM_QUANTITY)
VALUES (101, 1, 3);

-- Verify the order menu_item_ingredients table
SELECT * FROM menu_item_ingredients;

-- Verify the ingredients table
SELECT * FROM ingredients;