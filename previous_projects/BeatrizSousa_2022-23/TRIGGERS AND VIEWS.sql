USE CULTURAL_SEATS;

# VIEWS OF THE INVOICE

CREATE OR REPLACE VIEW INVOICE_HEAD_TOTALS AS 
SELECT (P.PURCHASE_ID - 1000) AS INVOICE_NUMBER, P.PURCHASE_DATE AS DATE_OF_ISSUE, 
 CONCAT(C.FIRST_NAME, ' ', C.LAST_NAME) AS CLIENT_NAME,
 A.STREET AS STREET_ADDRESS, A.CITY AS CITY, A.STATE_PROVINCE AS STATE,
 CO.COUNTRY_NAME AS COUNTRY, A.ZIP_CODE AS ZIP_CODE, SUM(P.QUANTITY * T.PRICE) AS SUB_TOTAL,
 "CULTURAL_SEATS" AS COMPANY_NAME, "GERAL@CULTURALSEATS.PT" AS COMPANY_EMAIL,
 "CAMPUS DE CAMPOLIDE, 1070-312 LISBOA, PORTUGAL" AS COMPANY_ADDRESS,
 PA.DISCOUNTS AS DISCOUNT, "6%" AS TAX_RATE, ROUND(SUM(P.QUANTITY * T.PRICE) * 0.06, 2) AS TAX,
 ROUND(SUM(P.QUANTITY * T.PRICE) * 1.06 - PA.DISCOUNTS, 2) AS TOTAL,
 ROUND(SUM(P.QUANTITY * T.PRICE) * 1.06 - PA.DISCOUNTS, 2) AS INVOICE_TOTAL
FROM CUSTOMER AS C
JOIN ADDRESS AS A ON C.ADDRESS_ID = A.ADDRESS_ID
JOIN COUNTRY AS CO ON A.COUNTRY_ID = CO.COUNTRY_ID
JOIN PURCHASE AS P ON P.CUSTOMER_ID = C.CUSTOMER_ID
JOIN TICKET AS T ON T.PURCHASE_ID = P.PURCHASE_ID
JOIN PAYMENT AS PA ON PA.PURCHASE_ID = P.PURCHASE_ID
GROUP BY INVOICE_NUMBER
;

CREATE OR REPLACE VIEW INVOICE_DETAILS AS 
SELECT (P.PURCHASE_ID - 1000) AS INVOICE_NUMBER, 
 CONCAT('TICKET N.', T.TICKET_ID, ' ', E.TYPE_OF_EVENT, ' OF THE ARTIST ', A.ARTIST_NAME) AS DESCRIPTION, 
 T.PRICE AS UNIT_COST, '1' AS QUANTITY, T.PRICE AS AMOUNT
FROM TICKET AS T
JOIN EVENT AS E ON E.EVENT_ID = T.EVENT_ID
JOIN ARTIST AS A ON A.EVENT_ID = E.EVENT_ID
JOIN PURCHASE AS P ON P.PURCHASE_ID = T.PURCHASE_ID
;

# EXAMPLE OF SEEING AN INVOICE
SELECT * 
FROM INVOICE_DETAILS
WHERE INVOICE_NUMBER = 3;



# TRIGGER 1-----------------------------------------------------------------------------------------------------

DELIMITER $$
CREATE TRIGGER AFTER_TICKET_INSERT
AFTER INSERT
ON TICKET
FOR EACH ROW
BEGIN
	UPDATE EVENT
    INNER JOIN TICKET ON TICKET.EVENT_ID = EVENT.EVENT_ID
    SET PLACES_AVAILABLE = PLACES_AVAILABLE - 1
    WHERE TICKET_ID = NEW.TICKET_ID;
END $$
DELIMITER ;

# HERE WE CAN SEE ON EVENT 408 THE NUMBER OF PLACES AVAILABLE IS 1997
SELECT *
FROM EVENT;

INSERT INTO `TICKET` (`TICKET_ID`, `CUSTOMER_ID`, `EVENT_ID`, `PURCHASE_ID`, `SECTOR`, `PRICE`, `SEAT`) VALUES    
(231, 110, 408, 1005, "MIDDLE SEATS FRONT", 30.00, "J19");

# AFTER WE INSERT A TICKET FOR THIS EVENT WE CAN SEE THE NUMBER OF PLACES AVAILABLE IS ONLY 1996
SELECT *
FROM EVENT;


# TRIGGER 2----------------------------------------------------------------------------------------------------

# THE OBJECTIVE OF OUR COMPANY IS NOT ONLY TO PROVIDE THE BEST SERVICE TO OUR EXISTING CUSTOMERS, BUT ALSO TO ATRACT NEW ONES. 
# SO, WE USUALLY GIVE A 10% DISCOUNT TO THE FIRST BUY OF THE CUSTOMERS
# IN ORDER TO KEEP TRACK OF THE NEW CUSTOMERS WE INSERT A LINE IN A LOG TABLE, EVERYTIME A CUSTOMER IS INSERTED IN OUR DATABASE
CREATE TABLE IF NOT EXISTS `LOG` (
	`LOG_ID` INTEGER UNSIGNED AUTO_INCREMENT,
	`TIME` DATETIME,
    `CUSTOMER_ID` INTEGER,
	`NAME_CUSTOMER` VARCHAR(50),
	`EMAIL` VARCHAR(40),
    `SENT_STATUS` VARCHAR(3), # YES IF AN EMAIL WITH THE DISCOUNT WAS ALREADY SENT TO THIS NEW CUSTOMER AND NO OTHERWISE
    `USED_DISCOUNT` VARCHAR(3), # YES IF THE CUSTOMER ALREADY USED THE DISCOUNT AND NO OTHERWISE
    PRIMARY KEY (`LOG_ID`)
) ;

# HERE WE HAVE THE CREATED LOG TABLE THAT IS EMPTY
SELECT *
FROM LOG;

DELIMITER $$
CREATE TRIGGER AFTER_CUSTOMER_INSERT
AFTER INSERT
ON CUSTOMER
FOR EACH ROW
BEGIN
	INSERT INTO `LOG` (`TIME`, `CUSTOMER_ID`, `NAME_CUSTOMER`, `EMAIL`, `SENT_STATUS`, `USED_DISCOUNT`) VALUES
	(NOW(), NEW.CUSTOMER_ID, CONCAT(NEW.FIRST_NAME, ' ', NEW.LAST_NAME), NEW.EMAIL, 'NO', 'NO');
END $$
DELIMITER ;

# WHEN WE INSERT A NEW CUSTOMER
INSERT INTO `CUSTOMER` (`CUSTOMER_ID`, `FIRST_NAME`, `LAST_NAME`, `BIRTH_DATE`, `GENDER`, `NATIONALITY`, `ADDRESS_ID`, `EMAIL`, `ID_CARD`, `PHONE_NUMBER`, `TAX_NUMBER`) VALUES    
(130, "FICTITIOUS", "PERSON", "1990-10-29", "MALE", "GERMAN", 618, "FPERSON@GMAIL.COM", "4820952991", "+49(0)0372093693 ", "981936078");

# THE LOG TABLE HAS A NEW OBSERVATION WITH THE DETAILS
SELECT * 
FROM LOG;



# IF WE WANTED TO REGISTER THAT WE ALREADY SENT THE EMAIL WITH THE DISCOUNT WE DO THIS 
UPDATE LOG
SET SENT_STATUS = "YES"
WHERE LOG_ID = 1;