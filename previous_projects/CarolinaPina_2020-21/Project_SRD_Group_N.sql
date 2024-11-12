#DROP DATABASE isports;
CREATE DATABASE IF NOT EXISTS isports;
USE isports;

#TABLES - STEP B:

CREATE TABLE IF NOT EXISTS `customer` (
  `CUST_ID` INT AUTO_INCREMENT,
  `FISCAL_NUMBER` INT(15) DEFAULT NULL,
  `FIRST_NAME` VARCHAR(50) NOT NULL,
  `SURNAME` VARCHAR(50) DEFAULT NULL,
  `AGE` INT(3) NOT NULL,
  `EMAIL` VARCHAR(200) DEFAULT NULL,
  `PHONE_NUMBER` VARCHAR(13) DEFAULT NULL,
  `LOCATION_ID` INT DEFAULT NULL,
  PRIMARY KEY (`CUST_ID`)
);

CREATE TABLE IF NOT EXISTS `location` (
  `LOCATION_ID` INT AUTO_INCREMENT NOT NULL,
  `STREET_ADDRESS` VARCHAR(40) NOT NULL,
  `POSTAL_CODE` VARCHAR(12) NOT NULL,
  `CITY` VARCHAR(30) NOT NULL,
  `STATE_PROVINCE` VARCHAR(25) DEFAULT NULL,
  `COUNTRY_ID` VARCHAR(2) NOT NULL,
  PRIMARY KEY (`LOCATION_ID`)
) ;

CREATE TABLE IF NOT EXISTS `country` (
  `COUNTRY_ID` VARCHAR(3) NOT NULL,
  `COUNTRY_NAME` VARCHAR(40) NOT NULL,
  `REGION_ID` INT NOT NULL,
  PRIMARY KEY (`COUNTRY_ID`)
);

CREATE TABLE IF NOT EXISTS `region` (
  `REGION_ID` INT AUTO_INCREMENT NOT NULL,
  `REGION_NAME` VARCHAR(25) NOT NULL,
  PRIMARY KEY (`REGION_ID`)
);

CREATE TABLE IF NOT EXISTS `warehouse` (
  `WAREHOUSE_ID` INT NOT NULL AUTO_INCREMENT,
  `EMAIL` VARCHAR(50) NOT NULL,
  `PHONE_NUMBER` VARCHAR(15) NOT NULL,
  `LOCATION_ID` INT NOT NULL,
  PRIMARY KEY (`WAREHOUSE_ID`)
  );
  
  CREATE TABLE IF NOT EXISTS `product` (
  `PRODUCT_ID` INT AUTO_INCREMENT NOT NULL,
  `PRODUCT_NAME` VARCHAR(50) NOT NULL,
  `PRODUCT_PRICE` DECIMAL(8,2) NOT NULL, #Current price
  `PRODUCT_DESCRIPTION` VARCHAR(100) DEFAULT NULL,
  `PRODUCT_DISCOUNT` FLOAT(2,2) DEFAULT '0.00',
  PRIMARY KEY (`PRODUCT_ID`)
);

CREATE TABLE IF NOT EXISTS `promotion` (
   `PROMOTION_ID` INT AUTO_INCREMENT NOT NULL,
   `PROMOTION_CODE` VARCHAR(20) NOT NULL,
   `PROMOTION_DESCRIPTION` VARCHAR(100) NOT NULL,
   `DATE_START` DATETIME DEFAULT NULL,
   `DATE_END` DATETIME DEFAULT NULL,
   `PROMOTION_VALUE` FLOAT(2,2) DEFAULT '0.00',
   PRIMARY KEY (`PROMOTION_ID`)
);

CREATE TABLE IF NOT EXISTS `stock` (
  `PRODUCT_ID` INT NOT NULL, #PK and FK
  `WAREHOUSE_ID` INT NOT NULL, #PK and FK
  `QUANTITY` INT(5) NOT NULL,
  `LAST_DATE` DATETIME DEFAULT NOW(), #Last date the stock was updated
  PRIMARY KEY (`PRODUCT_ID`, `WAREHOUSE_ID`)
);

CREATE TABLE IF NOT EXISTS `invoice` (
  `INVOICE_ID` INT AUTO_INCREMENT NOT NULL,
  `DATE_OF_ISSUE` DATETIME DEFAULT NOW(),
  `TOTAL` INT DEFAULT '0.00',
  `TAX_RATE` FLOAT(2,2) DEFAULT '0.23',
  `CUST_ID` INT NOT NULL,
  `PROMOTION_ID` INT DEFAULT NULL,
  PRIMARY KEY (`INVOICE_ID`)
) ;

CREATE TABLE IF NOT EXISTS `order` (
  `INVOICE_ID` INT NOT NULL,
  `PRODUCT_ID` INT NOT NULL,
  `WAREHOUSE_ID` INT NOT NULL,
  `QUANTITY` INT(5) NOT NULL, #Quantity of the product that was bought
  `DATE_OF_PURCHASE` DATETIME DEFAULT NOW(),
  PRIMARY KEY (`INVOICE_ID`, `PRODUCT_ID`, `WAREHOUSE_ID`)
) ;

CREATE TABLE IF NOT EXISTS `rating` (
  `RATING_ID` INT AUTO_INCREMENT NOT NULL,
  `CUST_ID` INT NOT NULL,
  `PRODUCT_ID` INT NOT NULL,
  `RATING_DATE` DATETIME DEFAULT NOW(), 
  `RATING` INT DEFAULT NULL,
  `COMMENT` VARCHAR(100) DEFAULT NULL,
  PRIMARY KEY (`RATING_ID`)
);

#FOREIGN KEY'S DEFINITION:

ALTER TABLE `country`
ADD CONSTRAINT `fk_country_1`
  FOREIGN KEY (`REGION_ID`)
  REFERENCES `region` (`REGION_ID`)
  ON DELETE RESTRICT
  ON UPDATE CASCADE;

ALTER TABLE `location`
ADD CONSTRAINT `fk_location_1`
  FOREIGN KEY (`COUNTRY_ID`)
  REFERENCES `country` (`COUNTRY_ID`)
  ON DELETE RESTRICT
  ON UPDATE CASCADE;

ALTER TABLE `warehouse`
ADD CONSTRAINT `fk_warehouse_1`
  FOREIGN KEY (`LOCATION_ID`)
  REFERENCES `location` (`LOCATION_ID`)
  ON DELETE RESTRICT
  ON UPDATE CASCADE;

ALTER TABLE `customer`
ADD CONSTRAINT `fk_customer_1`
  FOREIGN KEY (`LOCATION_ID`)
  REFERENCES `location` (`LOCATION_ID`)
  ON DELETE RESTRICT
  ON UPDATE CASCADE;

ALTER TABLE `stock`
ADD CONSTRAINT `fk_stock_1`
  FOREIGN KEY (`WAREHOUSE_ID`)
  REFERENCES `warehouse` (`WAREHOUSE_ID`)
  ON DELETE RESTRICT
  ON UPDATE CASCADE,
ADD CONSTRAINT `fk_stock_2`
  FOREIGN KEY (`PRODUCT_ID`)
  REFERENCES `product` (`PRODUCT_ID`)
  ON DELETE RESTRICT
  ON UPDATE CASCADE;

ALTER TABLE `order`
ADD CONSTRAINT `fk_order_1`
  FOREIGN KEY (`PRODUCT_ID`)
  REFERENCES `product` (`PRODUCT_ID`)
  ON DELETE RESTRICT
  ON UPDATE CASCADE,
ADD CONSTRAINT `fk_order_2`
  FOREIGN KEY (`INVOICE_ID`)
  REFERENCES `invoice` (`INVOICE_ID`)
  ON DELETE RESTRICT
  ON UPDATE CASCADE,
ADD CONSTRAINT `fk_order_3`
  FOREIGN KEY (`WAREHOUSE_ID`)
  REFERENCES `warehouse` (`WAREHOUSE_ID`)
  ON DELETE RESTRICT
  ON UPDATE CASCADE;

ALTER TABLE `invoice`
ADD CONSTRAINT `fk_invoice_1`
  FOREIGN KEY (`PROMOTION_ID`)
  REFERENCES `promotion` (`PROMOTION_ID`)
  ON DELETE RESTRICT
  ON UPDATE CASCADE,
ADD CONSTRAINT `fk_invoice_2`
  FOREIGN KEY (`CUST_ID`)
  REFERENCES `customer` (`CUST_ID`)
  ON DELETE RESTRICT
  ON UPDATE CASCADE;
  
ALTER TABLE `rating`
ADD CONSTRAINT `fk_rating_1`
  FOREIGN KEY (`CUST_ID`)
  REFERENCES `customer` (`CUST_ID`)
  ON DELETE RESTRICT
  ON UPDATE CASCADE,
ADD CONSTRAINT `fk_rating_2`
  FOREIGN KEY (`PRODUCT_ID`)
  REFERENCES `product` (`PRODUCT_ID`)
  ON DELETE RESTRICT
  ON UPDATE CASCADE;

#INSERTS - STEP F:

insert into `region` (`region_id`, `region_name`) values
(1, 'Europe'),
(2, 'America');

INSERT INTO `country` (`COUNTRY_ID`, `COUNTRY_NAME`, `REGION_ID`) VALUES
('AR', 'Argentina', 2),
('BE', 'Belgium', 1),
('BR', 'Brazil', 2),
('CZ', 'Czech Republic', 2),
('SW', 'Switzerland', 1),
('FL', 'Finland', 1),
('DE', 'Germany', 1),
('DK', 'Denmark', 1),
('EC', 'Ecuador', 2),
('FR', 'France', 1),
('CL', 'Colombia', 2),
('PL', 'Poland', 1),
('IT', 'Italy', 1),
('SLO', 'Slovenia', 1),
('MX', 'Mexico', 2),
('NL', 'Netherlands', 1),
('PT', 'Portugal',1),
('SP', 'Spain', 1),
('UK', 'United Kingdom', 1);

INSERT INTO `location` (`LOCATION_ID`, `STREET_ADDRESS`, `POSTAL_CODE`, `CITY`, `STATE_PROVINCE`, `COUNTRY_ID`) VALUES
(1, '97 Avenida Columbano Bordalo Pinheiro', '1099-456', 'Lisboa', 'Lisboa', 'PT'),
(2, '93091 Calle della Testa', 10934, 'Venice', 'Veneto', 'IT'),
(3, 'Cl 64 No. 69-20, C.P 11001', '4460-120', 'Guifões', 'Porto', 'PT'),
(4, '1006 de Marzo y Villavicencio', 10606, 'Guayas', 'Guayaquil', 'EC'),
(5, 'Hálkova 1559', 47151, 'Svor', 'Liberecký kraj', 'CZ'),
(6, 'Avda. Enrique Peinador 46', 37175, 'Pereña De La Ribera', 'Salamanca', 'SP'),
(7, 'Tarup Byvej 53', 1257, 'Kobenhavn K', 'Region Sjlland', 'DK'),
(8, '29  Place de la Madeleine', 75010, 'Paris', 'Île-de-France', 'FR'),
(9, 'Rue Libert 309', 7340, 'Warquignies', 'Hainaut', 'BE'),
(10, 'Sahantie 93', 33180, 'Tampere', 'Pirkanmaa', 'FL'),
(11, 'ul. Generala Kosciuszki Tadeusza 104', '30-114', 'Kraków', NULL, 'PL'),
(12, '94  rue de la République', 54300, 'Lunéville', 'Lorraine', 'FR'),
(13, 'Paraguay 80', 03579, 'Sella', 'Alicante', 'SP'),
(14, '8204 Arthur St', 540198, 'London', NULL, 'UK'),
(15, '49 Sutton Wick Lane', 'AB56 9GQ', 'Bridge Of Tynet', 'Moray', 'UK'),
(16, '9702 Chester Road', 9629850293, 'Stretford', 'Manchester', 'UK'),
(17, 'Schwanthalerstr. 7031', 80925, 'Munich', 'Bavaria', 'DE'),
(18, 'Rua Frei Caneca 1360', '01307-002', 'Sao Paulo', 'Sao Paulo', 'BR'),
(19, '20 Rue des Corps-Saints', 1730, 'Geneva', 'Geneve', 'SW'),
(20, 'Murtenstrasse 921', 3095, 'Bern', 'BE', 'SW'),
(21, 'Pieter Breughelstraat 837', '3029SK', 'Utrecht', 'Utrecht', 'NL'),
(22, 'Mariano Escobedo 9991', 11932, 'Mexico City', 'Distrito Federal', 'MX');

insert into `customer` (`FISCAL_NUMBER`, `FIRST_NAME`, `SURNAME`, `AGE`, `LOCATION_ID`) values
(129395929, 'Sofia', 'Pereira', 20, 1),
(272392100, 'Carolina', 'Gomes', 23, 3),
(338889119, 'Joana', 'Silva', 42, 2),
(493948231, 'Marta', 'Afonso', 57,4),
(557853562, 'Beatriz', 'Pina', 48, 7),
(629048283, 'Matilde', 'Gonçalves', 70, 9),
(766278392, 'João', 'Silva', 18, 13),
(822425355, 'António', 'Sousa', 37, 1),
(945234277, 'Pedro', 'Torres', 59, 18),
(102484848, 'Rodrigo', 'Jones', 26, 9),
(118635238, 'Mariana', 'Rocha', 60, 21),
(122234244, 'Manuel', 'Alves', 19, 17),
(130768900, 'Rui', 'Marques', 31, 2),
(143454345, 'Francisco', 'Baptista', 90, 6),
(150087900, 'Vasco', 'Maia', 22, 20),
(167119629, 'Americo', 'Craveiro', 18, 12),
(174326366, 'Alice', 'Pereira', 23, 5),
(189796007, 'Carolina', 'Ferreira', 42, 14),
(192332233, 'Joana', 'Ferraz', 50, 14),
(200202022, 'Marta', 'Albuquerque', 65, 3),
(213009877, 'Beatriz', 'Martins', 33, 13),
(226788653, 'Matilde', 'Sampaio', 55, 22),
(230810827, 'João', 'Martins', 47, 8),
(242920111, 'José', 'Almeida', 42, 3),
(252892840, 'Maria', 'Pereira', 24, 10),
(264095320, 'Rui', 'Soares', 27, 15),
(272639123, 'Nuno', 'Pereira', 72, 1),
(282047402, 'Manuel', 'Maria', 61, 12),
(291739396, 'Gabriela', 'Santos', 35, 5),
(303849477, 'Francisco', 'Costa', 50, 3);

insert into `warehouse` (`WAREHOUSE_ID`, `EMAIL`, `PHONE_NUMBER`, `LOCATION_ID`) values
(1, 'w1.isports@gmail.com', '+351 212344334', 1),
(2, 'w2.isports@gmail.com', '+51 757 68072', 11),
(3, 'w3.isports@gmail.com', '+(21) 4901-4868', 18);

insert into `product` (`PRODUCT_ID`, `PRODUCT_NAME`,`PRODUCT_PRICE`) values
(1, 'Basket Ball', 13.99),
(2, 'Bicycle', 169.99),
(3, 'Elliptical', 9.75),
(4, 'Bottle', 7.30),
(5, 'Gloves', 10.99),
(6, 'Skate', 19.99),
(7, 'Skiis', 250.00),
(8, 'Helmet',9.75),
(9, 'Sneakers', 9.75),
(10, 'Football Ball', 13.99),
(11, 'Training jacket', 17.99),
(12, 'Swimming suit', 20.50),
(13, 'Yoga mat', 30.75),
(14, 'Punching bags', 149.00),
(15, 'Indoor bike', 199.99),
(16, 'Treadmills', 349.00),
(17, 'Weights', 24.00),
(18, 'Hiking shoes',34.99),
(19, 'Running shorts', 7.99),
(20, 'Volleyball', 7.99),
(31, 'Football  shin pads',12.99),
(21, 'Football jersey', 12.75),
(22, 'Team sports bag', 20.50),
(23, 'Skipping rope', 4.75),
(24, 'Mountaineering jacket', 49.99),
(25, 'Swimming caps', 4.99),
(26, 'Swimming goggles', 5.75),
(27, 'Football cleats', 34.99),
(28, 'Tennis racket', 19.99),
(29, 'Tent', 149.99),
(30, 'Ice skates', 15.00);

insert into `promotion` (`PROMOTION_ID`, `PROMOTION_CODE`, `PROMOTION_DESCRIPTION`) values
(1, 'XMAS18', 'Christmas promotion for 2018'),
(2, 'XMAS19', 'Christmas promotion for 2019'),
(3, 'XMAS20', 'Christmas promotion for 2020'),
(4, 'BF18', 'Black Friday promotion for 2018'),
(5, 'BF19', 'Black Friday promotion for 2019'),
(6, 'BF20', 'Black Friday promotion for 2020');

insert into `stock` (`PRODUCT_ID`,`WAREHOUSE_ID`,`QUANTITY`, `LAST_DATE`) values
(1, 1,30,'2018-01-01'),
(1, 2,30,'2018-01-01'),
(1, 3,30,'2018-01-01'),
(2, 1,30,'2018-01-01'),
(2, 2,30,'2018-01-01'),
(2, 3,30,'2018-01-01'),
(3, 1,30,'2018-01-01'),
(3, 2,30,'2018-01-01'),
(3, 3,30,'2018-01-01'),
(4, 3,30,'2018-01-01'),
(4, 1,30,'2018-01-01'),
(4, 2,30,'2018-01-01'),
(5, 1,30,'2018-01-01'),
(5, 2,30,'2018-01-01'),
(5, 3,30,'2018-01-01'),
(6, 1,30,'2018-01-01'),
(6, 2,30,'2018-01-01'),
(6, 3,30,'2018-01-01'),
(7, 1,30,'2018-01-01'),
(7, 3,30,'2018-01-01'),
(8, 1,30,'2018-01-01'),
(8, 2,30,'2018-01-01'),
(8, 3,30,'2018-01-01'),
(9, 1,30,'2018-01-01'),
(9, 2,30,'2018-01-01'),
(9, 3,30,'2018-01-01'),
(10, 1,30,'2018-01-01'),
(10, 2,30,'2018-01-01'),
(10, 3,30,'2018-01-01'),
(11, 1,30,'2018-01-01'),
(11, 2,30,'2018-01-01'),
(11, 3,30,'2018-01-01'),
(12, 1,30,'2018-01-01'),
(12, 2,30,'2018-01-01'),
(13, 3,30,'2018-01-01'),
(14, 1,30,'2018-01-01'),
(14, 2,30,'2018-01-01'),
(14, 3,30,'2018-01-01'),
(15, 1,30,'2018-01-01'),
(15, 2,30,'2018-01-01'),
(15, 3,30,'2018-01-01'),
(16, 1,30,'2018-01-01'),
(16, 2,30,'2018-01-01'),
(17, 3,30,'2018-01-01'),
(17, 1,30,'2018-01-01'),
(17, 2,30,'2018-01-01'),
(18, 1,30,'2018-01-01'),
(18, 2,30,'2018-01-01'),
(18, 3,30,'2018-01-01'),
(19, 1,30,'2018-01-01'),
(19, 2,30,'2018-01-01'),
(19, 3,30,'2018-01-01'),
(20, 1,30,'2018-01-01'),
(20, 2,30,'2018-01-01'),
(20, 3,30,'2018-01-01'),
(21, 1,30,'2018-01-01'),
(21, 2,30,'2018-01-01'),
(21, 3,30,'2018-01-01'),
(22, 1,30,'2018-01-01'),
(22, 2,30,'2018-01-01'),
(22, 3,30,'2018-01-01'),
(23, 1,30,'2018-01-01'),
(23, 2,30,'2018-01-01'),
(23, 3,30,'2018-01-01'),
(24, 1,30,'2018-01-01'),
(24, 2,30,'2018-01-01'),
(24, 3,30,'2018-01-01'),
(25, 1,30,'2018-01-01'),
(25, 2,30,'2018-01-01'),
(25, 3,30,'2018-01-01'),
(26, 1,30,'2018-01-01'),
(26, 2,30,'2018-01-01'),
(26, 3,30,'2018-01-01'),
(27, 1,30,'2018-01-01'),
(27, 2,30,'2018-01-01'),
(27, 3,30,'2018-01-01'),
(28, 1,30,'2018-01-01'),
(28, 2,30,'2018-01-01'),
(28, 3,30,'2018-01-01'),
(29, 1,30,'2018-01-01'),
(29, 2,30,'2018-01-01'),
(29, 3,30,'2018-01-01'),
(30, 1,30,'2018-01-01'),
(30, 2,30,'2018-01-01'),
(30, 3,30,'2018-01-01');

insert into `invoice` (`INVOICE_ID`,`CUST_ID`,`DATE_OF_ISSUE`,`PROMOTION_ID`) values
(1, 1,'2018-04-12', 1),
(2, 7,'2018-07-03', 1),
(3, 30,'2018-07-04', 2),
(4, 15,'2018-09-10', NULL),
(5, 6,'2018-10-07', NULL),
(6, 23,'2018-10-11', NULL),
(7, 5,'2018-11-15', NULL),
(8, 5,'2018-12-02', NULL),
(9, 10,'2018-12-17', NULL),
(10, 23,'2019-03-11', NULL),
(11, 20,'2019-05-03', NULL),
(12, 9,'2019-07-14', NULL),
(13, 27,'2019-08-01', NULL),
(14, 22,'2019-08-16', NULL),
(15, 12,'2019-09-22', NULL),
(16, 2,'2019-09-30', NULL),
(17, 4,'2019-10-06', NULL),
(18, 18,'2019-10-13', NULL),
(19, 30,'2019-10-29', NULL),
(20, 18,'2019-11-07', NULL),
(21, 5,'2020-02-12', NULL),
(22, 3,'2020-02-12', NULL),
(23, 13,'2020-06-20', NULL),
(24, 16,'2020-07-08', NULL),
(25, 29,'2020-07-17', NULL),
(26, 11,'2020-08-27', NULL),
(27, 25,'2020-09-04', NULL),
(28, 6,'2020-09-27', NULL),
(29, 8,'2020-10-11', NULL),
(30, 21,'2020-11-30', NULL);

insert into `order` (`INVOICE_ID`,`PRODUCT_ID`,`WAREHOUSE_ID`,`QUANTITY`,`DATE_OF_PURCHASE`) values
(1, 18,1,1,'2018-04-12'),
(1, 18,2,2,'2018-04-12'),
(2, 1,1,2,'2018-07-03'),
(3, 9,1,3,'2018-07-04'),
(3, 2,1,1,'2018-07-04'),
(3, 28,1,2,'2018-07-04'),
(4, 20,3,3,'2018-09-10'),
(5, 15,1,1,'2018-10-07'),
(5, 17,2,1,'2018-10-07'),
(6, 6,1,1,'2018-10-11'),
(7, 12,1,1,'2018-11-15'),
(7, 25,2,2,'2018-11-15'),
(8, 26,1,1,'2018-12-02'),
(9, 1,3,1,'2018-12-17'),
(10, 8,3,1,'2019-03-11'),
(10, 4,3,3,'2019-03-11'),
(11, 3,2,1,'2019-05-03'),
(11, 13,2,1,'2019-05-03'),
(12, 11,1,5,'2019-07-14'),
(13, 10,2,2,'2019-08-01'),
(13, 27,3,1,'2019-08-01'),
(14, 27,1,1,'2019-08-16'),
(15, 18,3,1,'2019-09-22'),
(15, 24,2,1,'2019-09-22'),
(15, 29,3,1,'2019-09-22'),
(16, 14,1,1,'2019-09-30'),
(17, 23,3,1,'2019-10-06'),
(18, 28,2,2,'2019-10-13'),
(19, 10,2,2,'2019-10-29'),
(19, 10,3,3,'2019-10-29'),
(20, 4,2,1,'2019-11-07'),
(20, 5,2,1,'2019-11-07'),
(20, 8,2,1,'2019-11-07'),
(20, 9,3,1,'2019-11-07'),
(21, 23,1,3,'2020-02-12'),
(22, 23,2,2,'2020-02-12'),
(23, 5,2,2,'2020-06-20'),
(23, 30,2,1,'2020-06-20'),
(24, 3,3,1,'2020-07-08'),
(25, 10,2,1,'2020-07-17'),
(25, 3,3,1,'2020-07-17'),
(26, 2,2,1,'2020-08-27'),
(27, 21,1,1,'2020-09-04'),
(27, 20,1,2,'2020-09-04'),
(28, 26,1,1,'2020-09-27'),
(29, 22,3,4,'2020-10-11'),
(29, 12,1,2,'2020-10-11'),
(29, 12,2,1,'2020-10-11'),
(30, 13,2,1,'2020-11-30'),
(30, 13,3,1,'2020-11-30');

insert into `rating` (`CUST_ID`,`PRODUCT_ID`,`RATING`) values
(1, 18, 4),
(7, 1, 5),
(30, 2, 3),
(15, 20, 5),
(23, 6, 4),
(5, 12, 5),
(5, 25, 3),
(10, 1, 4),
(23, 8, 5),
(23, 4, 4),
(20, 3, 5),
(20, 13, 2),
(27, 10, 4),
(27, 27, 4),
(22, 27, 5),
(12, 18, 4),
(12, 24, 4),
(12, 29, 3),
(2, 14, 5),
(4, 23, 2),
(18, 28, 5),
(30, 10, 4),
(18, 4, 5),
(18, 5, 5),
(18, 8, 2),
(18, 9, 4),
(5, 23, 4),
(29, 10, 5),
(29, 3, 5),
(11, 2, 4),
(25, 21, 3),
(25, 20, 4),
(6, 26, 5),
(8, 12, 3),
(21, 13, 5);

#TRIGGERS - STEP C:

#1) one that updates the stock of products after the customer completes an order.
delimiter $$
create trigger update_stock 
before insert
on `order`
for each row
begin

if exists (select 1 from stock s where new.quantity <= s.quantity) then 
update stock s
set s.quantity = s.quantity-new.quantity, s.last_date = new.date_of_purchase
where new.quantity <= s.quantity and new.product_id = s.product_id and 
new.warehouse_id = s.warehouse_id;

else if exists (select 1 from stock s where new.quantity > s.quantity) then 
	SIGNAL SQLSTATE '45000'
	set message_text = 'There is not enough stock!';
    
end if;
end if;

end $$
delimiter ;

#2) a trigger that inserts a row in a “log” table if the price of a product is updated.
Create Table IF NOT EXISTS log (
	ID integer unsigned auto_increment Primary Key, 	
    usr varchar(30),
	TS datetime,
	OLD_PRICE DECIMAL(8,2),
    NEW_PRICE DECIMAL(8,2),
	PRODUCTID integer (10));
    
delimiter $$
create trigger update_price
after update
on PRODUCT
for each row
Begin
	insert into log(TS, usr, PRODUCTID, OLD_PRICE, NEW_PRICE) values
    (now(), user(), NEW.PRODUCT_ID, OLD.PRODUCT_PRICE, NEW.PRODUCT_PRICE);
End $$
delimiter ;

#inserts and updates to test the triggers
#testing Trigger 1
-- insert into `invoice` (`INVOICE_ID`,`CUST_ID`) values
-- (31, 1),
-- (32, 7),
-- (33, 30);

-- insert into `order` (`INVOICE_ID`,`PRODUCT_ID`,`WAREHOUSE_ID`,`QUANTITY`,`DATE_OF_PURCHASE`) values
-- (31, 18,1,15,'2020-12-01'),
-- (31, 18,2,2,'2020-12-01'),
-- (32, 1,1,2,'2020-12-05'),
-- (33, 9,1,3,'2020-12-10');

-- select * from `stock`;
-- select * from `order`;

#testing Trigger 2
-- update PRODUCT set product_price = 44.99
-- where product_id = 3;

-- update PRODUCT set product_price = 5.99
-- where product_id = 4;

-- select * from `log`;

#EXTRA COLUMN TO ADD THE CUSTOMERS FROM PENTAHO - STEP D:

ALTER TABLE `customer`
ADD `SEGMENTATION` varchar(255) DEFAULT NULL;

#VIEWS - STEP H:

#View example for Invoice with ID = 3, if we wanted to change the invoice, we could replace the INVOICE_ID on the where clause:
create view details_3 as 
select p.PRODUCT_NAME as "Product Name", (p.PRODUCT_PRICE-(p.PRODUCT_PRICE*p.PRODUCT_DISCOUNT)) as Price, 
SUM(o.QUANTITY) as "Total Quantity", SUM(o.QUANTITY)*(p.PRODUCT_PRICE-(p.PRODUCT_PRICE*p.PRODUCT_DISCOUNT)) as Amount
from product as p
join `order` o on p.PRODUCT_ID=O.PRODUCT_ID
join invoice i on o.INVOICE_ID=i.INVOICE_ID
where i.INVOICE_ID=3
group by p.PRODUCT_ID;

#View example for Invoice with ID = 3, if we wanted to change the invoice, we could replace the INVOICE_ID on the where clause:
create view heading_and_total_3 as 
select i.INVOICE_ID as `Invoice Number`, i.DATE_OF_ISSUE as `Date of Issue`, 
concat(c.FIRST_NAME, " ", c.SURNAME) as `Client Name`, l.STREET_ADDRESS as `Street Adress`, 
concat(l.CITY, ", ", l.STATE_PROVINCE, ", ", co.COUNTRY_NAME) as `City, State, Country`, l.POSTAL_CODE as `Zip Code`, 
"Rua Mouco 35, Cascais, Lisboa, Portugal, 2750-514, 
216 971 724, isports@gmail.com, www.isports.pt" as `Isports`, TOTAL.Subtotal , ifnull((pr.PROMOTION_VALUE*TOTAL.Subtotal), 0)  as Discount, i.TAX_RATE as `Tax Rate`, 
(i.TAX_RATE* TOTAL.Subtotal) as Tax, (TOTAL.Subtotal-ifnull((pr.PROMOTION_VALUE*TOTAL.Subtotal),0)+(i.TAX_RATE*TOTAL.Subtotal)) as `Invoice Total`
from invoice as i
join customer c on c.CUST_ID=i.CUST_ID 
join location l on l.LOCATION_ID=c.LOCATION_ID 
join country co on co.COUNTRY_ID=l.COUNTRY_ID
LEFT join promotion pr on pr.PROMOTION_ID=i.PROMOTION_ID
join (select i.INVOICE_ID, SUM((o.QUANTITY)*(p.PRODUCT_PRICE-(p.PRODUCT_PRICE*p.PRODUCT_DISCOUNT))) as Subtotal
from product as p
join `order` o on p.PRODUCT_ID=O.PRODUCT_ID
join invoice i on o.INVOICE_ID=i.INVOICE_ID
group by i.INVOICE_ID ) AS TOTAL
on TOTAL.INVOICE_ID=i.INVOICE_ID
where i.INVOICE_ID=3;