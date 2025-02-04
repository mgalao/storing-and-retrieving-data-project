CREATE VIEW invoice_head AS
SELECT 
    au.UNIT_ID AS CUSTOMER_ID,
    au.UNIT_NAME AS CUSTOMER_NAME,
    CURRENT_DATE AS INVOICE_DATE,
    SUM(s.SERVICE_PRICE) AS TOTAL_AMOUNT
FROM administrative_units au
JOIN ratings r ON au.UNIT_ID = r.UNIT_ID -- Assuming ratings could track usage
JOIN services s ON r.RATING_SERVICE_TYPE = s.SERVICE_NAME
GROUP BY au.UNIT_ID, au.UNIT_NAME;

CREATE VIEW invoice_details AS
SELECT 
    au.UNIT_ID AS CUSTOMER_ID,
    au.UNIT_NAME AS CUSTOMER_NAME,
    s.SERVICE_NAME,
    s.SERVICE_DESCRIPTION,
    1 AS QUANTITY, -- Assuming 1 unit for simplicity
    s.SERVICE_PRICE AS UNIT_PRICE,
    s.SERVICE_PRICE AS TOTAL_PRICE
FROM administrative_units au
JOIN ratings r ON au.UNIT_ID = r.UNIT_ID
JOIN services s ON r.RATING_SERVICE_TYPE = s.SERVICE_NAME;