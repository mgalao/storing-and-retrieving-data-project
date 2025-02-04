-- Create Database
CREATE DATABASE IF NOT EXISTS SushiGo
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE SushiGo;

-- 1) Customers Table
CREATE TABLE IF NOT EXISTS customers (
    CUSTOMER_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    CUSTOMER_FIRST_NAME VARCHAR(50) NOT NULL,
    CUSTOMER_LAST_NAME VARCHAR(50) NOT NULL,
    CUSTOMER_EMAIL VARCHAR(100) UNIQUE NOT NULL,
    CUSTOMER_PHONE VARCHAR(15) NOT NULL,
    CUSTOMER_GENDER ENUM('Male', 'Female', 'Other') DEFAULT NULL,
    CUSTOMER_DOB DATE NOT NULL,
    CUSTOMER_LOYALTY_POINTS SMALLINT DEFAULT 0,
    CUSTOMER_CREATED_DATE DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_loyalty_points
        CHECK (CUSTOMER_LOYALTY_POINTS BETWEEN 0 AND 10000) -- Ensures loyalty points are between 0 and 10000
);

-- 2) Orders Table
CREATE TABLE IF NOT EXISTS orders (
    ORDER_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    ORDER_DATE DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ORDER_PRICE DECIMAL(5, 2) NOT NULL,
    ORDER_DISCOUNT_PERCENT TINYINT DEFAULT 0,
    ORDER_TYPE ENUM('Home Delivery', 'Pickup at Store') NOT NULL,
    ORDER_DELIVERY_ADDRESS VARCHAR(200) DEFAULT NULL,
    ORDER_RATING TINYINT  DEFAULT NULL,
    CUSTOMER_ID INT NOT NULL,
    FOREIGN KEY (CUSTOMER_ID) REFERENCES customers(CUSTOMER_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_order_rating_value
        CHECK (ORDER_RATING BETWEEN 1 AND 5),  -- Ensures rating is between 1 and 5
    CONSTRAINT chk_discount_percent
        CHECK (ORDER_DISCOUNT_PERCENT BETWEEN 0 AND 100),  -- Ensures discount percentage is between 0 and 100
    CONSTRAINT chk_order_address
        CHECK (
            (ORDER_TYPE = 'Home Delivery' AND ORDER_DELIVERY_ADDRESS IS NOT NULL) OR  -- Address is required for home delivery
            (ORDER_TYPE = 'Pickup at Store' AND ORDER_DELIVERY_ADDRESS IS NULL)  -- Address should be null for pickup at store
        )
);

-- 3) Employees Table
CREATE TABLE IF NOT EXISTS employees (
    EMPLOYEE_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    EMPLOYEE_FIRST_NAME VARCHAR(50) NOT NULL,
    EMPLOYEE_LAST_NAME VARCHAR(50) NOT NULL,
    EMPLOYEE_EMAIL VARCHAR(100) UNIQUE,
    EMPLOYEE_PHONE VARCHAR(15),
    EMPLOYEE_SALARY DECIMAL(7, 2) NOT NULL,
    EMPLOYEE_START_DATE DATE NOT NULL,
    EMPLOYEE_END_DATE DATE DEFAULT NULL,
    MANAGER_ID INT DEFAULT NULL,
    FOREIGN KEY (MANAGER_ID) REFERENCES employees(EMPLOYEE_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- 4) Payments Table
CREATE TABLE IF NOT EXISTS payments (
    PAYMENT_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    PAYMENT_DATE DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PAYMENT_AMOUNT DECIMAL(5, 2) NOT NULL,
    PAYMENT_METHOD ENUM('Credit/Debit Card', 'Cash', 'Store Credit') NOT NULL,
    PAYMENT_TIN VARCHAR(9) DEFAULT NULL,  -- Tax Identification Number
    ORDER_ID INT NOT NULL,
    EMPLOYEE_ID INT DEFAULT NULL,
    FOREIGN KEY (ORDER_ID) REFERENCES orders(ORDER_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (EMPLOYEE_ID) REFERENCES employees(EMPLOYEE_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_tin_format
        CHECK (PAYMENT_TIN REGEXP '^[0-9]{9}$')
);

-- 5) Refunds Table
CREATE TABLE IF NOT EXISTS refunds (
    REFUND_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    REFUND_DATE DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    REFUND_AMOUNT DECIMAL(5, 2) NOT NULL,
    REFUND_REASON ENUM(
		'Missing items',
        'Incorrect items',
        'Item Issues',
        'Incorrect orders',
        'Undelivered orders',
        'Late deliveries'
	) NOT NULL,
    REFUND_METHOD ENUM('Credit/Debit Card', 'Cash', 'Store Credit') NOT NULL,
    PAYMENT_ID INT NOT NULL,
    EMPLOYEE_ID INT NOT NULL, -- Employee approving or managing refunds
    FOREIGN KEY (PAYMENT_ID) REFERENCES payments(PAYMENT_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (EMPLOYEE_ID) REFERENCES employees(EMPLOYEE_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- 6) Menu Items Table
CREATE TABLE IF NOT EXISTS menu_items (
    MENU_ITEM_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    MENU_ITEM_NAME VARCHAR(200) NOT NULL,
    MENU_ITEM_DESCRIPTION TEXT DEFAULT NULL,
    MENU_ITEM_PRICE DECIMAL(5, 2) NOT NULL,
    MENU_ITEM_IS_AVAILABLE BOOLEAN DEFAULT TRUE,
    MENU_ITEM_CREATED_DATE DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    MENU_ITEM_DISCONTINUED_DATE DATETIME DEFAULT NULL,
    MENU_ITEM_DISCONTINUED_REASON TEXT DEFAULT NULL,
    MENU_LAST_UPDATED DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    EMPLOYEE_ID INT NOT NULL, -- Employee who created or updated the menu item
    FOREIGN KEY (EMPLOYEE_ID) REFERENCES employees(EMPLOYEE_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- 7) Junction Table: Order Items Table
CREATE TABLE IF NOT EXISTS order_items (
    ORDER_ID INT NOT NULL,
    MENU_ITEM_ID INT NOT NULL,
    ORDER_ITEM_QUANTITY TINYINT NOT NULL DEFAULT 1,
    FOREIGN KEY (ORDER_ID) REFERENCES orders(ORDER_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (MENU_ITEM_ID) REFERENCES menu_items(MENU_ITEM_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- 8) Ingredients Table
CREATE TABLE IF NOT EXISTS ingredients (
    INGREDIENT_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    INGREDIENT_NAME VARCHAR(100) NOT NULL,
    INGREDIENT_PRICE_PER_UNIT DECIMAL(8, 4) NOT NULL,
    INGREDIENT_STOCK_QUANTITY FLOAT NOT NULL,
    INGREDIENT_MEASUREMENT_UNIT ENUM('g', 'ml', 'unit') NOT NULL,
    INGREDIENT_LAST_UPDATED DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 9) Junction Table: Menu Item Ingredients Table
CREATE TABLE IF NOT EXISTS menu_item_ingredients (
    MENU_ITEM_ID INT NOT NULL,
    INGREDIENT_ID INT NOT NULL,
    MENU_ITEM_INGREDIENT_QUANTITY FLOAT NOT NULL,
    MENU_ITEM_MEASUREMENT_UNIT ENUM('g', 'ml', 'unit') NOT NULL,
    PRIMARY KEY (MENU_ITEM_ID, INGREDIENT_ID),
    FOREIGN KEY (MENU_ITEM_ID) REFERENCES menu_items(MENU_ITEM_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    FOREIGN KEY (INGREDIENT_ID) REFERENCES ingredients(INGREDIENT_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- 10) Logs Table
CREATE TABLE IF NOT EXISTS menu_item_logs (
    LOG_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    LOG_DATE DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LOG_TYPE ENUM(
        'Price Changed',
        'Availability Changed',
        'Price and Availability Changed'
    ) NOT NULL,
    MENU_ITEM_OLD_PRICE DECIMAL(5, 2) DEFAULT NULL,
    MENU_ITEM_NEW_PRICE DECIMAL(5, 2) DEFAULT NULL,
    MENU_ITEM_OLD_AVAILABILITY BOOLEAN DEFAULT NULL,
    MENU_ITEM_NEW_AVAILABILITY BOOLEAN DEFAULT NULL,
    MENU_ITEM_ID INT NOT NULL,
    CONSTRAINT fk_menu_item
        FOREIGN KEY (MENU_ITEM_ID) REFERENCES menu_items (MENU_ITEM_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

---------------------------------------------------------------------------------------------------

-- Insert data into the employees table
INSERT INTO employees (
    EMPLOYEE_FIRST_NAME, 
    EMPLOYEE_LAST_NAME, 
    EMPLOYEE_EMAIL, 
    EMPLOYEE_PHONE, 
    EMPLOYEE_SALARY, 
    EMPLOYEE_START_DATE, 
    EMPLOYEE_END_DATE, 
    MANAGER_ID
)
VALUES
('Hiroshi', 'Tanaka', 'hiroshi.tanaka@restaurant.com', '+351-912345678', 3500.75, '2021-11-20', NULL, NULL), 
('Carlos', 'Nunes', 'carlos.nunes@restaurant.com', '+351-910123456', 3600.00, '2021-12-01', NULL, NULL),   
('Yumi', 'Kobayashi', 'yumi.kobayashi@restaurant.com', '+351-923456789', 1400.50, '2021-12-05', NULL, 1), 
('Ana', 'Santos', 'ana.santos@restaurant.com', '+351-945678901', 1350.30, '2021-11-25', NULL, 2),      
('João', 'Pereira', 'joao.pereira@restaurant.com', '+351-956789012', 1200.00, '2021-12-10', NULL, 2),
('Maria', 'Costa', 'maria.costa@restaurant.com', '+351-967890123', 1250.25, '2021-11-30', NULL, 2),
('António', 'Silva', 'antonio.silva@restaurant.com', '+351-978901234', 3100.00, '2021-12-15', NULL, 2),
('Sofia', 'Ferreira', 'sofia.ferreira@restaurant.com', '+351-989012345', 1300.50, '2021-11-28', NULL, 2),
('Rita', 'Mendes', 'rita.mendes@restaurant.com', '+351-921234567', 1275.75, '2021-12-20', NULL, 2),
('Pedro', 'Alves', 'pedro.alves@restaurant.com', '+351-932345678', 1250.00, '2021-12-18', NULL, 2),
('Helena', 'Martins', 'helena.martins@restaurant.com', '+351-943456789', 1225.50, '2022-11-15', NULL, 2),
('Miguel', 'Rocha', 'miguel.rocha@restaurant.com', '+351-954567890', 1280.00, '2022-12-01', NULL, 2);

-- Insert data into the menu_items table
INSERT INTO menu_items (
    MENU_ITEM_NAME,
    MENU_ITEM_DESCRIPTION,
    MENU_ITEM_PRICE,
    MENU_ITEM_IS_AVAILABLE,
    MENU_ITEM_CREATED_DATE,
    MENU_ITEM_DISCONTINUED_DATE,
    MENU_ITEM_DISCONTINUED_REASON,
    EMPLOYEE_ID
)
VALUES
('Combo Mix 30pc', 'A delicious mix of 30 sushi pieces', 28.00, TRUE, '2021-11-15', NULL, '2023-05-01', 2),
('Vin Festa 56pc', 'A premium assortment of 56 sushi pieces', 46.00, TRUE, '2021-11-20', NULL, '2023-06-10', 2),
('Salmon Mix 15pc', '15 pieces of sushi featuring salmon', 18.00, TRUE, '2021-12-05', NULL, '2024-02-01', 2),
('Vin Salmon 21pc', '21-piece premium salmon sushi selection', 22.00, TRUE, '2021-12-10', NULL, '2023-08-20', 2),
('Tempura Special Fried 22pc', 'Crispy tempura-fried sushi, 22 pieces', 25.00, TRUE, '2022-01-10', NULL, '2024-01-15', 2),
('Poke bowl tuna', 'Tuna poke bowl with fresh ingredients', 12.50, TRUE, '2021-12-20', NULL, '2023-03-05', 2),
('Poke bowl salmon', 'Salmon poke bowl with fresh ingredients', 12.50, TRUE, '2021-12-25', NULL, '2023-07-30', 2),
('Poke bowl ebi fry', 'Crispy fried shrimp poke bowl', 12.00, TRUE, '2023-02-10', NULL, '2024-03-10', 2),
('California roll', 'Roll with salmon, avocado, and cream cheese', 6.50, TRUE, '2021-11-01', NULL, '2023-04-15', 2),
('Tuna rolls', 'Roll with tuna, cream cheese, and cucumber', 6.50, TRUE, '2021-11-10', NULL, '2023-09-05', 2),
('Salmon Nigiri', '2 pieces of fresh salmon nigiri', 3.50, TRUE, '2021-11-05', NULL, '2024-01-20', 2),
('Nigiri Tuna', '2 pieces of fresh tuna nigiri', 3.50, TRUE, '2021-11-10', NULL, '2023-06-18', 2),
('Sashimi Six', '6 pieces of assorted sashimi', 6.50, TRUE, '2021-11-25', NULL, '2024-02-28', 2),
('Sashimi Salmon', '6 pieces of fresh salmon sashimi', 6.50, TRUE, '2021-12-01', NULL, '2023-11-10', 2),
('Dragon eye roll', '12 pieces of dragon eye sushi roll', 13.00, TRUE, '2022-01-15', NULL, '2023-12-15', 2),
('Salmon Mango Hot Rolls', '12 pieces of hot salmon mango Philadelphia roll', 12.00, TRUE, '2022-02-10', NULL, '2024-01-05', 2),
('Flaming Hot Salmon Rolls', '8 pieces of flaming salmon rolls', 9.99, TRUE, '2021-12-10', NULL, '2023-06-25', 2),
('SPecial Tuna Rolls', '8 pieces of special tuna rolls', 9.99, TRUE, '2021-12-20', NULL, '2023-09-15', 2),
('Temakizushi Salmon', '2 hand-rolled sushi cones with salmon', 5.00, TRUE, '2023-05-01', NULL, '2024-02-10', 2),
('Temakizushi Tuna', '2 hand-rolled sushi cones with tuna', 5.00, TRUE, '2023-05-15', NULL, '2024-03-01', 2),
('Gunkan Tuna', '2 pieces of gunkan sushi with tuna', 5.00, TRUE, '2021-12-01', NULL, '2023-05-10', 2),
('Gunkan Salmon', '2 pieces of gunkan sushi with salmon', 5.00, TRUE, '2021-12-05', NULL, '2023-07-20', 2),
('Tartare Salmon Avocado', 'Fresh salmon tartare with avocado', 12.00, TRUE, '2023-06-01', NULL, '2024-01-25', 2),
('Chirashi Salmon Tuna Mix', 'Mixed salmon and tuna chirashi', 14.50, TRUE, '2023-06-15', NULL, '2024-02-18', 2),
('Shrimp Ramen', 'Shrimp ramen with your choice of base (miso/shoyu/kimuchi)', 13.50, FALSE, '2021-11-01', '2022-12-31', '2022-09-01', 2),
('Chicken Noodle', 'Noodle with chicken', 14.50, FALSE, '2021-11-15', '2022-12-31', '2022-08-20', 2),
('Prawn Gyoza', '5 pieces of prawn gyoza dumplings', 4.99, TRUE, '2022-03-01', NULL, '2023-11-30', 2),
('Shrimp Bao', 'Shrimp-filled bao bun', 6.99, TRUE, '2022-03-15', NULL, '2024-01-10', 2),
('Mochi Ice Cream', 'Assorted mochi ice cream combo', 6.50, TRUE, '2022-04-01', NULL, '2023-12-20', 2),
('Mochi', 'Traditional mochi dessert', 3.50, TRUE, '2022-04-10', NULL, '2024-01-30', 2);

-- Insert data into the ingredients table
INSERT INTO ingredients (
    INGREDIENT_NAME,
    INGREDIENT_PRICE_PER_UNIT,
    INGREDIENT_MEASUREMENT_UNIT,
    INGREDIENT_STOCK_QUANTITY,
    INGREDIENT_LAST_UPDATED
)
VALUES
('Salmon', 0.01, 'g', 5000, '2024-12-01'),
('Tuna', 0.02, 'g', 8000, '2024-12-01'),
('Rice', 0.001, 'g', 2000, '2024-12-05'),
('Nori (Seaweed)', 0.01, 'unit', 5000, '2024-12-10'),
('Cucumber', 0.001, 'g', 1000, '2024-12-20'),
('Avocado', 0.002, 'g', 3000, '2024-12-25'),
('Cream Cheese', 0.001, 'g', 2300, '2024-11-15'),
('Shrimp', 0.007, 'g', 2400, '2024-11-20'),
('Mango', 0.002, 'g', 1000, '2024-11-25'),
('Tempura Batter', 0.0005, 'g', 35.0, '2024-12-01'),
('Soy Sauce', 0.002, 'ml', 10000, '2024-10-15'),
('Ginger', 0.0001, 'g', 1000, '2024-10-20'),
('Wasabi', 0.002, 'g', 500, '2024-10-25'),
('Sugar', 0.0001, 'g', 1000, '2024-12-01'),
('Vinegar',0.0001, 'ml', 1200, '2024-12-05'),
('Ice Cream',0.003,'g',500,'2024-12-05');

-- Insert data into the menu_item_ingredients table
INSERT INTO menu_item_ingredients (
    MENU_ITEM_ID,
    INGREDIENT_ID,
    MENU_ITEM_MEASUREMENT_UNIT,
    MENU_ITEM_INGREDIENT_QUANTITY
)
VALUES
(1, 1, 'g', 200),  -- Combo mix 30pc: Salmon
(1, 2, 'g', 200),  -- Combo mix 30pc: Tuna
(1, 3, 'g', 450),  -- Combo mix 30pc: Rice
(1, 4, 'unit', 10), -- Combo mix 30pc: Nori
(2, 1, 'g', 300),  -- Vin festa 56pc: Salmon
(2, 2, 'g', 300),  -- Vin festa 56pc: Tuna
(2, 3, 'g', 800),  -- Vin festa 56pc: Rice
(3, 1, 'g', 200),  -- Salmon mix 15pc: Salmon
(3, 3, 'g', 300),  -- Salmon mix 15pc: Rice
(4, 3, 'g', 600),  -- Salmon mix 15pc: Rice
(4, 1, 'g', 400),  -- Salmon mix 15pc: Rice
(5, 8, 'g', 300),  -- Tempura special fried 22pc: Shrimp
(5, 10, 'g', 200), -- Tempura special fried 22pc: Tempura Batter
(5, 3, 'g', 400),  -- Tempura special fried 22pc: Rice
(6, 2, 'g', 150),  -- Poke bowl tuna: Tuna
(6, 5, 'g', 100),  -- Poke bowl tuna: Cucumber
(6, 6, 'g', 100),  -- Poke bowl tuna: Avocado
(7, 1, 'g', 150),  -- Poke bowl salmon: Salmon
(7, 6, 'g', 100),  -- Poke bowl salmon: Avocado
(7, 5, 'g', 100),  -- Poke bowl salmon: Cucumber
(8, 8, 'g', 150),  -- Poke bowl ebi fry: Shrimp
(8, 10, 'g', 100), -- Poke bowl ebi fry: Tempura Batter
(8, 6, 'g', 100),  -- Poke bowl ebi fry: Avocado
(9, 1, 'g', 100),  -- California Roll: Salmon
(9, 6, 'g', 50),   -- California Roll: Avocado
(9, 7, 'g', 30),   -- California Roll: Cream Cheese
(10, 2, 'g', 100), -- Tuna roll: Tuna
(10, 5, 'g', 50),  -- Tuna roll: Cucumber
(10, 7, 'g', 30),  -- Tuna roll: Cream Cheese
(11, 1, 'g', 100), -- Nigiri Salmon: Salmon
(12, 2, 'g', 100), -- Nigiri Tuna: Tuna
(13, 1, 'g', 120),  -- Sashimi Six: Salmon
(13, 2, 'g', 120),  -- Sashimi Six: Tuna
(14, 1, 'g', 180),  -- Sashimi Salmon: Salmon
(15, 1, 'g', 150),  -- Dragon eye roll: Salmon
(15, 3, 'g', 200),  -- Dragon eye roll: Rice
(15, 4, 'unit', 3), -- Dragon eye roll: Nori
(16, 1, 'g', 150),   -- Salmon Mango Hot Rolls: Salmon
(16, 9, 'g', 100),   -- Salmon Mango Hot Rolls: Mango
(16, 7, 'g', 50),    -- Salmon Mango Hot Rolls: Cream Cheese
(16, 3, 'g', 200),   -- Salmon Mango Hot Rolls: Rice
(17, 1, 'g', 120),   -- Flaming Hot Salmon Rolls: Salmon
(17, 3, 'g', 150),   -- Flaming Hot Salmon Rolls: Rice
(17, 4, 'unit', 2),  -- Flaming Hot Salmon Rolls: Nori
(18, 2, 'g', 120),   -- Special Tuna Rolls: Tuna
(18, 3, 'g', 150),   -- Special Tuna Rolls: Rice
(18, 4, 'unit', 2),  -- Special Tuna Rolls: Nori
(19, 1, 'g', 80),    -- Temakizushi Salmon: Salmon
(19, 3, 'g', 100),   -- Temakizushi Salmon: Rice
(19, 4, 'unit', 1),  -- Temakizushi Salmon: Nori
(20, 2, 'g', 80),    -- Temakizushi Tuna: Tuna
(20, 3, 'g', 100),   -- Temakizushi Tuna: Rice
(20, 4, 'unit', 1),  -- Temakizushi Tuna: Nori
(21, 2, 'g', 60),    -- Gunkan Tuna: Tuna
(21, 3, 'g', 60),    -- Gunkan Tuna: Rice
(21, 4, 'unit', 1),  -- Gunkan Tuna: Nori
(22, 1, 'g', 60),    -- Gunkan Salmon: Salmon
(22, 3, 'g', 60),    -- Gunkan Salmon: Rice
(22, 4, 'unit', 1),  -- Gunkan Salmon: Nori
(23, 1, 'g', 150),   -- Tartare Salmon Avocado: Salmon
(23, 6, 'g', 100),   -- Tartare Salmon Avocado: Avocado
(24, 1, 'g', 150),   -- Chirashi Mix: Salmon
(24, 2, 'g', 150),   -- Chirashi Mix: Tuna
(24, 3, 'g', 300),   -- Chirashi Mix: Rice
(25, 8, 'g', 150),   -- Shrimp Ramen: Shrimp
(25, 11, 'ml', 300), -- Shrimp Ramen: Soy Sauce
(26, 3, 'g', 250),   -- Chicken Noodle: Rice
(26, 11, 'ml', 50),  -- Chicken Noodle: Soy Sauce
(27, 8, 'g', 100),   -- Prawn Gyoza: Shrimp
(27, 10, 'g', 150),  -- Prawn Gyoza: Tempura Batter
(28, 8, 'g', 100),   -- Shrimp Bao: Shrimp
(28, 3, 'g', 100),   -- Shrimp Bao: Rice
(29, 14, 'g', 200),  -- Mochi Ice Cream: Sugar
(29, 3, 'g', 150),   -- Mochi Ice Cream: Rice
(29,16,'g',50),      -- Mochi Ice Cream: Ice Cream
(30, 14, 'g', 100),  -- Traditional Mochi: Sugar
(30, 3, 'g', 200);   -- Traditional Mochi: Rice

-- Insert data into the customers table
INSERT INTO customers (
    CUSTOMER_ID, 
    CUSTOMER_FIRST_NAME, 
    CUSTOMER_LAST_NAME, 
    CUSTOMER_EMAIL, 
    CUSTOMER_PHONE, 
    CUSTOMER_GENDER, 
    CUSTOMER_DOB, 
    CUSTOMER_LOYALTY_POINTS, 
    CUSTOMER_CREATED_DATE
)
VALUES 
(1, 'João', 'Silva', 'joao.silva@example.com', '+351912345678', 'Male', '1989-06-15', 50, '2022-01-02'), -- 35 years
(2, 'Maria', 'Santos', 'maria.santos@example.com', '+351912345679', 'Female', '1995-03-10', 200, '2022-01-02'),
(3, 'Pedro', 'Ferreira', 'pedro.ferreira@example.com', '+351913456789', 'Male', '1990-08-25', 0, '2022-01-02'), -- 34 years
(4, 'Anna', 'Schmidt', 'anna.schmidt@example.com', '+491987654321', 'Female', '1986-12-01', 80, '2022-01-02'), -- 38 years
(5, 'Ricardo', 'Costa', 'ricardo.costa@example.com', '+351912345013', 'Male', '1998-08-12', 0, '2022-01-02'),
(6, 'Helena', 'Rodrigues', 'helena.rodrigues@example.com', '+351912345014', 'Female', '1997-09-15', 90, '2022-01-02'),
(7, 'Carlos', 'Pereira', 'carlos.pereira@example.com', '+351912345011', 'Male', '1992-02-20', 80, '2022-01-03'),
(8, 'Beatriz', 'Silveira', 'beatriz.silveira@example.com', '+351912345018', 'Female', '1987-10-05', 120, '2022-01-03'), -- 37 years
(9, 'Teresa', 'Fernandes', 'teresa.fernandes@example.com', '+351912345033', 'Female', '1990-06-13', 130, '2022-01-04'),
(10, 'Miguel', 'Hernandez', 'miguel.hernandez@example.com', '+346987654321', 'Male', '1984-02-14', 90, '2022-01-05'), -- 40 years
(11, 'Rahul', 'Chowdhury', 'rahul.chowdhury@example.com', '+8801712345678', 'Male', '1995-03-20', 70, '2022-01-05'),
(12, 'Luciana', 'Fernandez', 'luciana.fernandez@example.com', '+346765432109', 'Female', '1996-04-01', 120, '2022-01-07'),
(13, 'Emma', 'Williams', 'emma.williams@example.com', '+447912345678', 'Female', '1994-11-18', 120, '2022-01-24'),
(14, 'Daniel', 'Castro', 'daniel.castro@example.com', '+351912345040', 'Male', '1988-01-12', 0, '2022-02-01'), -- 36 years
(15, 'Sami', 'Khan', 'sami.khan@example.com', '+8801912345678', 'Male', '1994-06-21', 90, '2022-02-03'),
(16, 'Sophia', 'Nguyen', 'sophia.nguyen@example.com', '+61412345678', 'Female', '1993-05-23', 100, '2022-02-03'),
(17, 'Clara', 'Almeida', 'clara.almeida@example.com', '+351912345020', 'Female', '2000-06-15', 0, '2022-02-03'),
(18, 'Tiago', 'Neves', 'tiago.neves@example.com', '+351912345021', 'Male', '1995-02-14', 70, '2022-02-04'),
(19, 'Aisha', 'Mohammed', 'aisha.mohammed@example.com', '+971501234567', 'Female', '1994-12-01', 80, '2022-02-10'),
(20, 'Lucas', 'Müller', 'lucas.mueller@example.com', '+4915731234567', 'Male', '1989-10-03', 95, '2022-02-20'), -- 35 years
(21, 'Hugo', 'Correia', 'hugo.correia@example.com', '+351912345028', 'Male', '1997-04-21', 75, '2022-02-20'),
(22, 'Laura', 'Gutierrez', 'laura.gutierrez@example.com', '+346912345678', 'Female', '1990-09-13', 90, '2022-02-20'),
(23, 'Aya', 'Yamada', 'aya.yamada@example.com', '+813412345678', 'Female', '1993-11-01', 100, '2022-05-15'),
(24, 'Manuel', 'Carvalho', 'manuel.carvalho@example.com', '+351912345026', 'Male', '1993-11-30', 0, '2022-06-01'),
(25, 'Fatima', 'Ahmed', 'fatima.ahmed@example.com', '+8801798765432', 'Female', '1992-11-30', 70, '2022-06-10'),
(26, 'Isabel', 'Monteiro', 'isabel.monteiro@example.com', '+351912345047', 'Female', '1994-12-19', 90, '2022-06-20'),
(27, 'Sara', 'Johansson', 'sara.johansson@example.com', '+46702233445', 'Female', '1986-03-08', 85, '2022-07-01'), -- 38 years
(28, 'Chen', 'Wei', 'chen.wei@example.com', '+8613123456789', 'Male', '1996-01-10', 85, '2022-07-10'),
(29, 'Carolina', 'Vieira', 'carolina.vieira@example.com', '+351912345043', 'Female', '1999-07-28', 0, '2022-07-25'),
(30, 'João', 'Silva', 'joao.silva1@example.com', '+351912345678', 'Male', '1988-06-15', 50, '2022-08-01'), -- 36 years
(31, 'João', 'Silva', 'joao.silva2@example.com', '+351912345200', 'Male', '1992-06-15', 50, '2023-01-25'),
(32, 'Maria', 'Santos', 'maria.santos2@example.com', '+351912345201', 'Female', '1995-03-10', 200, '2023-02-01'),
(33, 'Pedro', 'Ferreira', 'pedro.ferreira2@example.com', '+351913456800', 'Male', '1990-08-25', 0, '2023-02-15'),
(34, 'Helena', 'Rodrigues', 'helena.rodrigues2@example.com', '+351912345202', 'Female', '1997-09-15', 90, '2023-02-25'),
(35, 'Carlos', 'Pereira', 'carlos.pereira2@example.com', '+351912345203', 'Male', '1992-02-20', 80, '2023-03-01'),
(36, 'Beatriz', 'Silveira', 'beatriz.silveira2@example.com', '+351912345204', 'Female', '1998-10-05', 120, '2023-03-15'),
(37, 'Tiago', 'Neves', 'tiago.neves2@example.com', '+351912345205', 'Male', '1995-02-14', 70, '2023-03-20'),
(38, 'Isabel', 'Monteiro', 'isabel.monteiro2@example.com', '+351912345206', 'Female', '1994-12-19', 90, '2023-04-05'),
(39, 'Ricardo', 'Costa', 'ricardo.costa2@example.com', '+351912345207', 'Male', '1998-08-12', 0, '2023-04-15'),
(40, 'Clara', 'Almeida', 'clara.almeida2@example.com', '+351912345208', 'Female', '2000-06-15', 0, '2023-04-25'),
(41, 'Manuel', 'Carvalho', 'manuel.carvalho2@example.com', '+351912345209', 'Male', '1994-11-30', 0, '2023-02-10'),
(42, 'Hugo', 'Correia', 'hugo.correia2@example.com', '+351912345210', 'Male', '1995-04-21', 75, '2023-02-20'),
(43, 'Carolina', 'Vieira', 'carolina.vieira2@example.com', '+351912345211', 'Female', '1990-07-28', 0, '2023-03-01'),
(44, 'Sophia', 'Alves', 'sophia.alves2@example.com', '+351912345212', 'Female', '1996-06-12', 0, '2023-03-15'),
(45, 'Daniel', 'Castro', 'daniel.castro2@example.com', '+351912345213', 'Male', '1993-01-12', 0, '2023-03-25'),
(46, 'Miguel', 'Hernandez', 'miguel.hernandez2@example.com', '+351912345214', 'Male', '1989-02-14', 90, '2023-04-10'),
(47, 'Laura', 'Gutierrez', 'laura.gutierrez2@example.com', '+351912345215', 'Female', '1990-09-13', 90, '2023-06-20'),
(48, 'João', 'Silva', 'joao.silva3@example.com', '+351912345216', 'Male', '1992-06-15', 50, '2023-06-05'),
(49, 'Isabel', 'Monteiro', 'isabel.monteiro3@example.com', '+351912345217', 'Female', '1993-12-19', 90, '2024-01-15'),
(50, 'Teresa', 'Fernandes', 'teresa.fernandes2@example.com', '+351912345218', 'Female', '1992-06-13', 130, '2024-01-25'),
(51, 'Lucas', 'Vieira', 'lucas.vieira@example.com', '+351912345219', 'Male', '1994-03-21', 70, '2024-02-01'),
(52, 'Ava', 'Rodrigues', 'ava.rodrigues@example.com', '+351912345220', 'Female', '1995-07-15', 50, '2024-02-10'),
(53, 'Sara', 'Pereira', 'sara.pereira@example.com', '+351912345221', 'Female', '1990-01-28', 85, '2024-02-20'),
(54, 'Olivia', 'Mendes', 'olivia.mendes@example.com', '+351912345222', 'Female', '1993-10-05', 80, '2024-02-05'),
(55, 'Helena', 'Fernandes', 'helena.fernandes@example.com', '+351912345223', 'Female', '1994-05-18', 100, '2024-02-15'),
(56, 'Fatima', 'Carvalho', 'fatima.carvalho@example.com', '+351912345224', 'Other', '2007-11-14', 75, '2024-02-25'), -- Other Gender (17 yrs)
(57, 'Beatriz', 'Vieira', 'beatriz.vieira@example.com', '+351912345225', 'Female', '1991-08-12', 90, '2024-03-10'),
(58, 'Carlos', 'Silva', 'carlos.silva2@example.com', '+351912345226', 'Other', '2006-04-17', 70, '2024-03-20'), -- Other Gender (18 yrs)
(59, 'Ana', 'Rodrigues', 'ana.rodrigues@example.com', '+351912345227', 'Other', '2008-02-23', 0, '2024-03-30'), -- Other Gender (16 yrs)
(60, 'Miguel', 'Costa', 'miguel.costa@example.com', '+351912345228', 'Other', '2005-08-30', 50, '2024-09-10'); -- Other Gender (19 yrs)

-- Insert data into the orders table
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
(1, '2022-01-10', 56.00, 10, 'Home Delivery', 'Rua Augusta 100, Lisbon', 5, 12),
(2, '2022-01-15', 18.00, 0, 'Pickup at Store', NULL, 4, 5),
(3, '2022-02-01', 37.50, 10, 'Home Delivery', 'Avenida da Liberdade 200, Lisbon', 5, 8),
(4, '2022-02-18', 25.00, 0, 'Home Delivery', 'Rua do Carmo 50, Lisbon', 4, 15),
(5, '2022-03-05', 12.00, 10, 'Pickup at Store', NULL, 5, 9),
(6, '2022-03-15', 13.00, 0, 'Home Delivery', 'Rua Garrett 120, Lisbon', 5, 7),
(7, '2022-04-01', 6.50, 0, 'Home Delivery', 'Avenida Almirante Reis 300, Lisbon', 5, 18),
(8, '2022-04-15', 13.00, 0, 'Home Delivery', 'Rua Castilho 80, Lisbon', 4, 4),
(9, '2022-04-30', 19.50, 0, 'Home Delivery', 'Rua dos Fanqueiros 60, Lisbon', 5, 10),
(10, '2022-05-05', 3.50, 10, 'Pickup at Store', NULL, 3, 3),
(11, '2022-05-15', 13.00, 0, 'Home Delivery', 'Rua de São Bento 180, Lisbon', 4, 21),
(12, '2022-05-20', 12.00, 0, 'Pickup at Store', NULL, 4, 6),
(13, '2022-06-01', 28.98, 10, 'Home Delivery', 'Rua da Prata 45, Lisbon', 5, 2),
(14, '2022-06-10', 15.00, 0, 'Home Delivery', 'Largo do Chiado 5, Lisbon', 5, 16),
(15, '2022-06-25', 17.00, 0, 'Home Delivery', 'Praça do Comércio 10, Lisbon', 4, 14),
(16, '2022-07-01', 25.00, 0, 'Pickup at Store', NULL, 4, 1),
(17, '2022-07-15', 50.96, 0, 'Home Delivery', 'Rua de Santa Catarina 150, Lisbon', 5, 23),
(18, '2022-08-01', 46.00, 0, 'Home Delivery', 'Avenida 5 de Outubro 100, Lisbon', 4, 19),
(19, '2022-08-10', 18.00, 10, 'Pickup at Store', NULL, 4, 3),
(20, '2022-08-20', 18.00, 0, 'Home Delivery', 'Rua Dom João V 60, Lisbon', 5, 25),
(21, '2022-09-01', 29.00, 0, 'Home Delivery', 'Rua de Arroios 25, Lisbon', 4, 17),
(22, '2022-09-10', 18.00, 0, 'Home Delivery', 'Rua Castilho 15, Lisbon', 5, 30),
(23, '2022-09-15', 17.50, 0, 'Home Delivery', 'Rua Alexandre Herculano 120, Lisbon', 5, 11),
(24, '2022-10-01', 12.00, 0, 'Pickup at Store', NULL, 5, 27),
(25, '2022-10-10', 23.98, 10, 'Home Delivery', 'Rua da Alegria 45, Lisbon', 4, 28),
(26, '2022-10-20', 28.00, 0, 'Home Delivery', 'Praça do Rossio 100, Lisbon', 5, 22),
(27, '2022-11-01', 17.00, 0, 'Home Delivery', 'Rua Poço do Borratém 55, Lisbon', 5, 9),
(28, '2022-11-10', 19.50, 0, 'Home Delivery', 'Rua da Misericórdia 15, Lisbon', 5, 26),
(29, '2022-11-25', 22.00, 0, 'Pickup at Store', NULL, 5, 4),
(30, '2022-12-01', 12.00, 0, 'Home Delivery', 'Rua Maria Andrade 80, Lisbon', 4, 13),
(31, '2022-12-15', 34.50, 10, 'Home Delivery', 'Avenida Berna 45, Lisbon', 4, 20),
(32, '2022-12-25', 45.50, 0, 'Home Delivery', 'Rua José Estêvão 90, Lisbon', 5, 14),
(33, '2023-01-10', 12.50, 0, 'Pickup at Store', NULL, 4, 1),
(34, '2023-01-15', 42.50, 0, 'Home Delivery', 'Rua Carlos Mardel 10, Lisbon', 5, 29),
(35, '2023-01-30', 32.50, 0, 'Home Delivery', 'Rua Pascoal de Melo 70, Lisbon', 5, 7),
(36, '2023-02-10', 25.00, 0, 'Home Delivery', 'Rua dos Anjos 120, Lisbon', 5, 5),
(37, '2023-02-15', 7.00, 0, 'Home Delivery', 'Avenida Paris 30, Lisbon', 5, 6),
(38, '2023-02-28', 6.50, 0, 'Home Delivery', 'Rua António Pedro 60, Lisbon', 5, 17),
(39, '2023-03-01', 41.00, 0, 'Home Delivery', 'Rua da Madalena 80, Lisbon', 4, 20),
(40, '2023-03-15', 19.98, 0, 'Pickup at Store', NULL, 5, 30),
(41, '2023-03-20', 39.50, 0, 'Home Delivery', 'Rua do Salitre 45, Lisbon', 4, 11),
(42, '2023-03-25', 12.50, 0, 'Home Delivery', 'Rua Rosa Araújo 100, Lisbon', 5, 8),
(43, '2023-04-01', 32.50, 0, 'Home Delivery', 'Avenida de Roma 150, Lisbon', 5, 3),
(44, '2023-04-10', 35.49, 10, 'Pickup at Store', NULL, 4, 23),
(45, '2023-04-20', 15.00, 0, 'Home Delivery', 'Rua do Norte 90, Lisbon', 5, 24),
(46, '2023-05-01', 19.48, 0, 'Home Delivery', 'Rua dos Douradores 20, Lisbon', 5, 12),
(47, '2023-05-10', 62.50, 0, 'Home Delivery', 'Rua Ferreira Borges 60, Lisbon', 5, 19),
(48, '2023-05-15', 36.00, 0, 'Home Delivery', 'Rua dos Remédios 120, Lisbon', 5, 25),
(49, '2023-06-01', 18.47, 0, 'Pickup at Store', NULL, 5, 18),
(50, '2023-06-15', 23.98, 0, 'Home Delivery', 'Rua do Telhal 80, Lisbon', 5, 10),
(51, '2023-07-01', 56.00, 10, 'Home Delivery', 'Rua Augusta 12, Lisbon', 5, 31),
(52, '2023-07-10', 18.00, 0, 'Pickup at Store', NULL, 4, 32),
(53, '2023-07-20', 37.50, 0, 'Home Delivery', 'Avenida da Liberdade 200, Lisbon', 5, 33),
(54, '2023-08-05', 25.00, 0, 'Home Delivery', 'Rua do Carmo 50, Lisbon', 4, 34),
(55, '2023-08-12', 24.00, 10, 'Home Delivery', 'Rua Garrett 75, Lisbon', 5, 35),
(56, '2023-08-25', 46.00, 0, 'Pickup at Store', NULL, 5, 36),
(57, '2023-09-01', 44.00, 0, 'Home Delivery', 'Rua Castilho 120, Lisbon', 5, 37),
(58, '2023-09-15', 6.50, 0, 'Home Delivery', 'Avenida Almirante Reis 300, Lisbon', 4, 38),
(59, '2023-09-25', 36.49, 10, 'Home Delivery', 'Rua dos Fanqueiros 10, Lisbon', 5, 39),
(60, '2023-10-10', 3.50, 0, 'Pickup at Store', NULL, 3, 40),
(61, '2023-10-25', 7.00, 0, 'Home Delivery', 'Rua de São Bento 180, Lisbon', 4, 31),
(62, '2023-11-01', 12.50, 0, 'Home Delivery', 'Rua da Prata 40, Lisbon', 5, 41),
(63, '2023-11-15', 9.99, 0, 'Pickup at Store', NULL, 4, 42),
(64, '2023-11-25', 19.98, 10, 'Home Delivery', 'Largo do Chiado 10, Lisbon', 5, 43),
(65, '2023-12-01', 13.00, 0, 'Home Delivery', 'Rua Alexandre Herculano 150, Lisbon', 4, 44),
(66, '2023-12-15', 12.00, 0, 'Home Delivery', 'Rua de Arroios 25, Lisbon', 5, 45),
(67, '2023-12-20', 29.97, 0, 'Home Delivery', 'Rua Dom João V 70, Lisbon', 5, 46),
(68, '2024-01-05', 10.00, 0, 'Pickup at Store', NULL, 4, 47),
(69, '2024-01-15', 5.00, 10, 'Home Delivery', 'Avenida 5 de Outubro 80, Lisbon', 4, 48),
(70, '2024-01-25', 10.00, 0, 'Home Delivery', 'Rua Carlos Mardel 30, Lisbon', 5, 49),
(71, '2024-02-10', 12.00, 0, 'Home Delivery', 'Rua Castilho 15, Lisbon', 4, 50),
(72, '2024-02-20', 12.00, 0, 'Home Delivery', 'Rua Maria Andrade 90, Lisbon', 5, 51),
(73, '2024-03-01', 13.50, 0, 'Home Delivery', 'Rua Alexandre Herculano 200, Lisbon', 5, 52),
(74, '2024-03-15', 14.50, 0, 'Pickup at Store', NULL, 5, 53),
(75, '2024-03-25', 12.98, 10, 'Home Delivery', 'Rua de Arroios 30, Lisbon', 4, 54),
(76, '2024-04-10', 20.97, 0, 'Home Delivery', 'Rua António Pedro 45, Lisbon', 5, 55),
(77, '2024-04-20', 6.99, 0, 'Home Delivery', 'Rua Rosa Araújo 150, Lisbon', 5, 56),
(78, '2024-05-05', 13.98, 0, 'Home Delivery', 'Rua dos Anjos 80, Lisbon', 5, 57),
(79, '2024-05-15', 28.00, 0, 'Pickup at Store', NULL, 5, 58),
(80, '2024-05-25', 46.00, 0, 'Home Delivery', 'Rua dos Remédios 90, Lisbon', 4, 59),
(81, '2024-09-10', 18.00, 0, 'Home Delivery', 'Rua do Salitre 100, Lisbon', 4, 60),
(82, '2024-06-10', 25.00, 0, 'Home Delivery', 'Avenida de Roma 90, Lisbon', 5, 31),
(83, '2024-06-20', 12.50, 10, 'Pickup at Store', NULL, 4, 33),
(84, '2024-07-05', 24.00, 0, 'Home Delivery', 'Rua Poço do Borratém 55, Lisbon', 5, 34),
(85, '2024-07-15', 6.50, 0, 'Home Delivery', 'Praça do Rossio 70, Lisbon', 5, 35),
(86, '2024-07-25', 10.50, 0, 'Home Delivery', 'Rua Maria Andrade 40, Lisbon', 5, 36),
(87, '2024-08-10', 7.00, 0, 'Home Delivery', 'Rua dos Douradores 20, Lisbon', 5, 39),
(88, '2024-08-20', 6.50, 0, 'Home Delivery', 'Rua Pascoal de Melo 60, Lisbon', 5, 41),
(89, '2024-08-30', 13.00, 0, 'Home Delivery', 'Rua Ferreira Borges 70, Lisbon', 4, 45),
(90, '2024-09-10', 19.98, 0, 'Pickup at Store', NULL, 5, 50),
(91, '2024-09-20', 15.00, 0, 'Home Delivery', 'Rua Rosa Araújo 30, Lisbon', 4, 52),
(92, '2024-09-25', 15.00, 0, 'Home Delivery', 'Rua António Pedro 120, Lisbon', 5, 54),
(93, '2024-10-05', 12.00, 0, 'Home Delivery', 'Rua Castilho 70, Lisbon', 5, 56),
(94, '2024-10-15', 9.99, 10, 'Pickup at Store', NULL, 4, 57),
(95, '2024-10-20', 10.00, 0, 'Home Delivery', 'Rua José Estêvão 110, Lisbon', 5, 58),
(96, '2024-10-25', 6.99, 0, 'Home Delivery', 'Rua Ferreira Borges 60, Lisbon', 5, 60),
(97, '2024-11-01', 18.00, 0, 'Home Delivery', 'Rua dos Anjos 70, Lisbon', 5, 33),
(98, '2024-11-10', 13.00, 0, 'Home Delivery', 'Rua do Norte 90, Lisbon', 5, 38),
(99, '2024-11-15', 9.99, 0, 'Pickup at Store', NULL, 5, 40),
(100, '2024-11-20', 13.98, 0, 'Home Delivery', 'Rua de São Bento 100, Lisbon', 5, 45);

-- Insert data into the order_items table
INSERT INTO order_items (
    ORDER_ID,
    MENU_ITEM_ID,
    ORDER_ITEM_QUANTITY
)
VALUES
(1, 1, 2),  
(13, 18, 2), (13, 19, 1),  
(2, 3, 1),  
(14, 20, 1), (14, 22, 2),  
(3, 6, 3),  
(4, 5, 1),  
(15, 23, 1), (15, 24, 1),  
(16, 25, 1),  
(5, 8, 1),  
(17, 28, 3), (17, 29, 1),  
(18, 30, 2), (18, 1, 1),  
(6, 9, 2),  
(7, 10, 1),  
(19, 2, 1), (19, 3, 2),  
(8, 11, 2),  
(20, 6, 1), (20, 7, 2),  
(21, 8, 1), (21, 9, 2),  
(9, 12, 3),  
(10, 13, 1),  
(22, 10, 1), (22, 11, 2),  
(23, 12, 1), (23, 13, 3),  
(11, 15, 2),  
(24, 15, 1), (24, 17, 1),  
(25, 18, 2), (25, 19, 1),  
(16, 26, 1), -- Ramen shrimp
(29, 27, 1), -- Pasta chicken  
(26, 20, 3), (26, 21, 1),  
(27, 22, 1), (27, 23, 2),  
(28, 24, 1), (28, 25, 1),  
(30, 29, 1), (30, 30, 2),
(31, 1, 1),  
(32, 3, 2), (32, 4, 1),  
(33, 6, 1),  
(34, 5, 2), (34, 8, 1),  
(35, 9, 3),  
(36, 10, 1), (36, 11, 2),  
(37, 12, 2),  
(38, 13, 1),  
(39, 15, 3), (39, 16, 2),  
(40, 17, 2),  
(41, 18, 1), (41, 19, 2),  
(42, 20, 3),  
(43, 22, 1), (43, 23, 1),  
(44, 24, 2),  
(45, 25, 1), (45, 28, 2),  
(46, 29, 1), (46, 30, 2),  
(47, 1, 2),  
(48, 3, 1), (48, 6, 3),  
(49, 4, 1),  
(50, 5, 1), (50, 9, 2),  
(51, 10, 2),  
(52, 11, 3),  
(53, 12, 1), (53, 15, 2),  
(54, 16, 1), (54, 17, 2),  
(55, 18, 2),  
(56, 19, 1),  
(57, 20, 3), (57, 22, 2),  
(58, 23, 1),  
(59, 24, 1), (59, 25, 2),  
(60, 28, 2), (60, 29, 1),
(61, 1, 2),
(62, 3, 1),
(63, 6, 3),
(64, 5, 1),
(65, 9, 2),
(66, 10, 1),
(67, 12, 2),
(68, 15, 1),
(69, 18, 3),
(70, 20, 1),
(71, 23, 2),
(72, 24, 1),
(73, 2, 2), (73, 4, 1),
(74, 5, 1), (74, 6, 2),
(75, 8, 1), (75, 9, 3),
(76, 10, 2), (76, 11, 1),
(77, 12, 1), (77, 13, 2),
(78, 15, 2), (78, 16, 1),
(79, 17, 3), (79, 18, 2),
(80, 19, 1), (80, 20, 2),
(81, 22, 3), (81, 23, 1),
(82, 24, 2), (82, 25, 1),
(83, 28, 3), (83, 29, 2),
(84, 30, 1), (84, 3, 2),
(85, 4, 1), (85, 5, 2),
(86, 6, 3), (86, 7, 1),
(87, 8, 1), (87, 9, 2),
(88, 10, 1), (88, 11, 2),
(89, 12, 3), (89, 13, 1),
(90, 15, 1), (90, 16, 2),
(91, 17, 2), (91, 18, 1),
(92, 19, 3), (92, 20, 1),
(93, 22, 2), (93, 23, 3),
(94, 24, 1), (94, 25, 2),
(95, 28, 1), (95, 29, 2),
(96, 30, 3), (96, 1, 1),
(97, 2, 2), (97, 4, 1),
(98, 5, 2), (98, 6, 1),
(99, 7, 3), (99, 8, 2),
(100, 9, 1), (100, 10, 2);

-- Insert data into the payments table
INSERT INTO payments (
    PAYMENT_DATE,
    PAYMENT_AMOUNT,
    PAYMENT_METHOD,
    PAYMENT_TIN,
    ORDER_ID,
    EMPLOYEE_ID
)
VALUES 
('2022-01-10', 68.88, 'Credit/Debit Card', NULL, 1, NULL),
('2022-01-15', 22.14, 'Cash', NULL, 2, 4),
('2022-02-01', 46.13, 'Credit/Debit Card', NULL, 3, NULL),
('2022-02-18', 30.75, 'Credit/Debit Card', NULL, 4, NULL),
('2022-03-05', 14.76, 'Credit/Debit Card', NULL, 5, 5),
('2022-03-15', 16.00, 'Credit/Debit Card', NULL, 6, NULL),
('2022-04-01', 8.00, 'Credit/Debit Card', NULL, 7, NULL),
('2022-04-15', 16.00, 'Credit/Debit Card', NULL, 8, NULL),
('2022-04-30', 24.00, 'Credit/Debit Card', NULL, 9, NULL),
('2022-05-05', 4.31, 'Cash', NULL, 10, 5),
('2022-05-15', 10.00, 'Credit/Debit Card', NULL, 11, NULL),
('2022-05-15', 6.00, 'Store Credit', NULL, 11, NULL),
('2022-05-20', 14.76, 'Credit/Debit Card', NULL, 12, NULL),
('2022-06-01', 35.69, 'Credit/Debit Card', NULL, 13, NULL),
('2022-06-10', 18.45, 'Credit/Debit Card', NULL, 14, NULL),
('2022-06-25', 20.91, 'Credit/Debit Card', NULL, 15, NULL),
('2022-07-01', 30.75, 'Cash', NULL, 16, 4),
('2022-07-15', 62.00, 'Credit/Debit Card', NULL, 17, NULL),
('2022-08-01', 56.58, 'Credit/Debit Card', NULL, 18, NULL),
('2022-08-10', 22.14, 'Credit/Debit Card', NULL, 19, 4),
('2022-08-20', 22.14, 'Credit/Debit Card', NULL, 20, NULL),
('2022-09-01', 35.67, 'Credit/Debit Card', NULL, 21, NULL),
('2022-09-10', 22.14, 'Credit/Debit Card', NULL, 22, NULL),
('2022-09-15', 21.53, 'Credit/Debit Card', NULL, 23, NULL),
('2022-10-01', 14.76, 'Cash', NULL, 24, 6),
('2022-10-10', 29.53, 'Credit/Debit Card', NULL, 25, NULL),
('2022-10-20', 34.44, 'Credit/Debit Card', NULL, 26, NULL),
('2022-11-01', 20.91, 'Credit/Debit Card', NULL, 27, NULL),
('2022-11-10', 23.99, 'Credit/Debit Card', NULL, 28, NULL),
('2022-11-25', 27.14, 'Credit/Debit Card', NULL, 29, 6),
('2022-12-01', 14.76, 'Credit/Debit Card', NULL, 30, NULL),
('2022-12-15', 42.47, 'Credit/Debit Card', NULL, 31, NULL),
('2022-12-25', 56.00, 'Credit/Debit Card', NULL, 32, NULL),
('2023-01-10', 15.38, 'Credit/Debit Card', NULL, 33, 5),
('2023-01-15', 52.25, 'Credit/Debit Card', NULL, 34, NULL),
('2023-01-30', 39.98, 'Credit/Debit Card', NULL, 35, NULL),
('2023-02-10', 30.75, 'Credit/Debit Card', NULL, 36, NULL),
('2023-02-15', 8.61, 'Credit/Debit Card', NULL, 37, NULL),
('2023-02-28', 8.00, 'Credit/Debit Card', NULL, 38, NULL),
('2023-03-01', 50.43, 'Credit/Debit Card', NULL, 39, 1),
('2023-03-15', 24.58, 'Cash', NULL, 40, NULL),
('2023-03-20', 48.64, 'Credit/Debit Card', NULL, 41, NULL),
('2023-03-25', 15.38, 'Credit/Debit Card', NULL, 42, NULL),
('2023-04-01', 39.98, 'Credit/Debit Card', NULL, 43, NULL),
('2023-04-10', 43.59, 'Credit/Debit Card', NULL, 44, 5),
('2023-04-20', 18.45, 'Credit/Debit Card', NULL, 45, NULL),
('2023-05-01', 23.83, 'Credit/Debit Card', NULL, 46, NULL),
('2023-05-10', 76.88, 'Credit/Debit Card', NULL, 47, NULL),
('2023-05-15', 44.28, 'Credit/Debit Card', NULL, 48, NULL),
('2023-06-01', 22.72, 'Store Credit', NULL, 49, 4),
('2023-06-15', 29.53, 'Credit/Debit Card', NULL, 50, NULL),
('2023-07-01', ROUND((56.00 * 1.23) * 0.9, 2), 'Credit/Debit Card', "123456002", 51, 6),
('2023-07-10', ROUND(18.00 * 1.23, 2), 'Cash', NULL, 52, NULL),
('2023-07-20', ROUND((37.50 * 1.23) * 0.8, 2), 'Credit/Debit Card', "123456003", 53, 8),
('2023-07-20', ROUND((37.50 * 1.23) * 0.2, 2), 'Store Credit', NULL, 53, NULL),
('2023-08-05', ROUND(25.00 * 1.23, 2), 'Credit/Debit Card', "123456004", 54, NULL),
('2023-08-12', ROUND((24.00 * 1.23) * 0.9, 2), 'Credit/Debit Card', "123456005", 55, 9),
('2023-08-25', ROUND(46.00 * 1.23, 2), 'Cash', NULL, 56, 11),
('2023-09-01', ROUND((44.00 * 1.23) * 0.9, 2), 'Credit/Debit Card', "123456006", 57, NULL),
('2023-09-01', ROUND((44.00 * 1.23) * 0.1, 2), 'Store Credit', NULL, 57, NULL),
('2023-09-15', ROUND(6.50 * 1.23, 2), 'Cash', NULL, 58, 10),
('2023-09-25', ROUND((36.49 * 1.23) * 0.9, 2), 'Credit/Debit Card', "123456007", 59, NULL),
('2023-10-10', ROUND(3.50 * 1.23, 2), 'Store Credit', NULL, 60, NULL),
('2023-10-25', ROUND(7.00 * 1.23, 2), 'Credit/Debit Card', "123456008", 61, 7),
('2023-11-01', ROUND(12.50 * 1.23, 2), 'Cash', NULL, 62, NULL),
('2023-11-15', ROUND(9.99 * 1.23, 2), 'Credit/Debit Card', "123456009", 63, 6),
('2023-11-25', ROUND((19.98 * 1.23) * 0.9, 2), 'Credit/Debit Card', "123456010", 64, NULL),
('2023-12-01', ROUND(13.00 * 1.23, 2), 'Credit/Debit Card', "123456011", 65, 12),
('2023-12-15', ROUND(12.00 * 1.23, 2), 'Cash', NULL, 66, NULL),
('2023-12-20', ROUND(29.97 * 1.23, 2), 'Credit/Debit Card', "123456012", 67, 5),
('2024-01-05', ROUND(10.00 * 1.23, 2), 'Cash', NULL, 68, NULL),
('2024-01-15', ROUND((5.00 * 1.23) * 0.9, 2), 'Credit/Debit Card', "123456013", 69, NULL),
('2024-01-25', ROUND(10.00 * 1.23, 2), 'Credit/Debit Card', "123456014", 70, NULL),
('2024-02-10', ROUND(12.00 * 1.23, 2), 'Cash', NULL, 71, 8),
('2024-02-20', ROUND(12.00 * 1.23, 2), 'Credit/Debit Card', "123456015", 72, NULL),
('2024-03-01', ROUND(13.50 * 1.23, 2), 'Credit/Debit Card', "123456016", 73, 10),
('2024-03-15', ROUND((14.50 * 1.23) * 0.8, 2), 'Credit/Debit Card', "123456017", 74, NULL),
('2024-03-15', ROUND((14.50 * 1.23) * 0.2, 2), 'Store Credit', NULL, 74, NULL),
('2024-03-25', ROUND((12.98 * 1.23) * 0.9, 2), 'Credit/Debit Card', "123456018", 75, 9),
('2024-04-10', ROUND((20.97 * 1.23) * 0.8, 2), 'Credit/Debit Card', "123456001", 76, NULL),
('2024-04-10', ROUND((20.97 * 1.23) * 0.2, 2), 'Store Credit', NULL, 76, 7),
('2024-04-20', ROUND(6.99 * 1.23, 2), 'Cash', NULL, 77, 10),
('2024-05-05', ROUND((13.98 * 1.23) * 0.7, 2), 'Credit/Debit Card', "123456002", 78, 8),
('2024-05-05', ROUND((13.98 * 1.23) * 0.3, 2), 'Store Credit', NULL, 78, NULL),
('2024-05-15', ROUND(28.00 * 1.23, 2), 'Store Credit', NULL, 79, 11),
('2024-05-25', ROUND((46.00 * 1.23) * 0.9, 2), 'Credit/Debit Card', "123456003", 80, 9),
('2024-05-25', ROUND((46.00 * 1.23) * 0.1, 2), 'Store Credit', NULL, 80, NULL),
('2024-06-01', ROUND(18.00 * 1.23, 2), 'Cash', NULL, 81, NULL),
('2024-06-10', ROUND(25.00 * 1.23, 2), 'Credit/Debit Card', "123456004", 82, NULL),
('2024-06-20', ROUND((12.50 * 1.23) * 0.9, 2), 'Credit/Debit Card', "123456005", 83, 6),
('2024-07-05', ROUND((24.00 * 1.23) * 0.8, 2), 'Credit/Debit Card', "123456006", 84, NULL),
('2024-07-05', ROUND((24.00 * 1.23) * 0.2, 2), 'Store Credit', NULL, 84, NULL),
('2024-07-15', ROUND(6.50 * 1.23, 2), 'Cash', NULL, 85, NULL),
('2024-07-25', ROUND(10.50 * 1.23, 2), 'Credit/Debit Card', "123456007", 86, 12),
('2024-08-10', ROUND((7.00 * 1.23) * 0.9, 2), 'Credit/Debit Card', "123456008", 87, NULL),
('2024-08-10', ROUND((7.00 * 1.23) * 0.1, 2), 'Store Credit', NULL, 87, NULL),
('2024-08-20', ROUND(6.50 * 1.23, 2), 'Cash', NULL, 88, 10),
('2024-08-30', ROUND((13.00 * 1.23) * 0.7, 2), 'Credit/Debit Card', "123456009", 89, 7),
('2024-08-30', ROUND((13.00 * 1.23) * 0.3, 2), 'Store Credit', NULL, 89, NULL),
('2024-09-10', ROUND(19.98 * 1.23, 2), 'Credit/Debit Card', "123456010", 90, NULL),
('2024-09-20', ROUND(15.00 * 1.23, 2), 'Credit/Debit Card', "123456011", 91, 9),
('2024-09-25', ROUND(15.00 * 1.23, 2), 'Cash', NULL, 92, NULL),
('2024-10-05', ROUND(12.00 * 1.23, 2), 'Credit/Debit Card', "123456012", 93, 8),
('2024-10-15', ROUND((9.99 * 1.23) * 0.9, 2), 'Credit/Debit Card', "123456013", 94, NULL),
('2024-10-20', ROUND(10.00 * 1.23, 2), 'Cash', NULL, 95, NULL),
('2024-10-25', ROUND(6.99 * 1.23, 2), 'Credit/Debit Card', "123456014", 96, 11),
('2024-11-01', ROUND((18.00 * 1.23) * 0.8, 2), 'Credit/Debit Card', "123456015", 97, NULL),
('2024-11-01', ROUND((18.00 * 1.23) * 0.2, 2), 'Store Credit', NULL, 97, NULL),
('2024-11-10', ROUND(13.00 * 1.23, 2), 'Cash', NULL, 98, NULL),
('2024-11-15', ROUND(9.99 * 1.23, 2), 'Credit/Debit Card', "123456016", 99, 12),
('2024-11-20', ROUND((13.98 * 1.23) * 0.9, 2), 'Credit/Debit Card', "123456017", 100, 6),
('2024-11-20', ROUND((13.98 * 1.23) * 0.1, 2), 'Store Credit', NULL, 100, NULL);

-- Insert data into the refunds table
INSERT INTO refunds (
    REFUND_DATE,
    REFUND_AMOUNT,
    REFUND_REASON,
    REFUND_METHOD,
    PAYMENT_ID,
    EMPLOYEE_ID
)
VALUES
('2022-01-20', 15.00, 'Missing items', 'Credit/Debit Card', 1, 2),
('2022-02-05', 7.25, 'Incorrect items', 'Credit/Debit Card', 3, 2),
('2022-03-10', 14.76, 'Item Issues', 'Cash', 7, 2),
('2022-04-02', 8.00, 'Undelivered orders', 'Cash', 7, 2),
('2022-06-12', 3.00, 'Late deliveries', 'Credit/Debit Card', 14, 2),
('2022-09-15', 11.34, 'Incorrect orders', 'Credit/Debit Card', 22, 2),
('2022-10-05', 3.50, 'Item Issues', 'Cash', 24, 2),
('2023-03-26', 15.38, 'Incorrect orders', 'Credit/Debit Card', 33, 2),
('2023-04-15', 6.50, 'Missing items', 'Cash', 44, 2),
('2023-05-20', 22.57, 'Incorrect items', 'Credit/Debit Card', 47, 2);