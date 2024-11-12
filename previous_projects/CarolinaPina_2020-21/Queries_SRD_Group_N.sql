USE isports;

#QUERIES - STEP G:

#Note: In the case some query returns an error, the 7th line can be uncommented and executed, to avoid it.
#This is related to the SQL versions (the newer versions shouldn't have any issue regarding this).
#SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

#1)
SELECT concat(c.`FIRST_NAME`, ' ', c.`SURNAME`) as `Customer Name`, o.`DATE_OF_PURCHASE` as `Date of Purchase`, p.`PRODUCT_NAME` as `Product Name`
FROM CUSTOMER c, `ORDER` o, PRODUCT p, INVOICE i
WHERE c.cust_id = i.cust_id and o.invoice_id = i.invoice_id and o.product_id = p.product_id 
and o.`DATE_OF_PURCHASE` between '2018-04-12' and '2019-03-11';

#2)
#Criteria to define the best customers: the ones that have spent the most money on the company's products
SELECT concat(c.`FIRST_NAME`, ' ', c.`SURNAME`) as `Customer Name`, 
sum((o.QUANTITY)*(p.PRODUCT_PRICE-(p.PRODUCT_PRICE*p.PRODUCT_DISCOUNT)))*(1+i.TAX_RATE) as `Money Spent`
FROM CUSTOMER c, `ORDER` o, PRODUCT p, INVOICE i
WHERE c.cust_id = i.cust_id and o.invoice_id = i.invoice_id and o.product_id = p.product_id 
GROUP BY `Customer Name`
ORDER BY `Money Spent` DESC
LIMIT 3;

#3)
SELECT concat(min(o.`DATE_OF_PURCHASE`), ' - ', max(o.`DATE_OF_PURCHASE`)) as PeriodOfSales, 
sum((o.QUANTITY)*(p.PRODUCT_PRICE-(p.PRODUCT_PRICE*p.PRODUCT_DISCOUNT))) as TotalSales, 
#We assume that year = 365 days and month = 30 days
round(sum((o.QUANTITY)*(p.PRODUCT_PRICE-(p.PRODUCT_PRICE*p.PRODUCT_DISCOUNT)))/(datediff(max(o.`DATE_OF_PURCHASE`), min(o.`DATE_OF_PURCHASE`))/365), 2) as YearlyAverage,
round(sum((o.QUANTITY)*(p.PRODUCT_PRICE-(p.PRODUCT_PRICE*p.PRODUCT_DISCOUNT)))/(datediff(max(o.`DATE_OF_PURCHASE`), min(o.`DATE_OF_PURCHASE`))/30), 2) as MonthlyAverage
FROM CUSTOMER c, `ORDER` o, PRODUCT p, INVOICE i
WHERE c.cust_id = i.cust_id and o.invoice_id = i.invoice_id and o.product_id = p.product_id;

#4)
select co.COUNTRY_NAME, l.CITY, SUM((o.QUANTITY)*(p.PRODUCT_PRICE-(p.PRODUCT_PRICE*p.PRODUCT_DISCOUNT))) as Total_price
from product as p
join `order` o on p.PRODUCT_ID=O.PRODUCT_ID
join invoice i on o.INVOICE_ID=i.INVOICE_ID
join customer c on c.CUST_ID=i.CUST_ID
join location l on c.LOCATION_ID=l.LOCATION_ID
join country co on l.COUNTRY_ID=co.COUNTRY_ID
group by co.COUNTRY_ID, l.CITY;

#5)
select distinct(concat(l.STREET_ADDRESS, ", ", l.POSTAL_CODE, ", ", l.CITY)) as Location
#, p.PRODUCT_NAME, r.RATING
from location l
join customer c on c.LOCATION_ID=l.LOCATION_ID
join rating r on c.CUST_ID=r.CUST_ID
join product p on r.PRODUCT_ID=p.PRODUCT_ID;
#If we wanted to highlight the products and each rating, we would uncomment the 46th line