<?xml version="1.0" encoding="UTF-8"?><sqlb_project><db path="/Users/austinsalinas/Desktop/BA workbooks/SQL/stores.db" readonly="0" foreign_keys="1" case_sensitive_like="0" temp_store="0" wal_autocheckpoint="1000" synchronous="2"/><attached/><window><main_tabs open="structure browser pragmas query" current="3"/></window><tab_structure><column_width id="0" width="300"/><column_width id="1" width="0"/><column_width id="2" width="100"/><column_width id="3" width="3197"/><column_width id="4" width="0"/><expanded_item id="0" parent="1"/><expanded_item id="1" parent="1"/><expanded_item id="2" parent="1"/><expanded_item id="3" parent="1"/></tab_structure><tab_browse><current_table name="4,9:maincustomers"/><default_encoding codec=""/><browse_table_settings><table schema="main" name="customers" show_row_id="0" encoding="" plot_x_axis="" unlock_view_pk="_rowid_"><sort/><column_widths><column index="1" value="98"/><column index="2" value="175"/><column index="3" value="98"/><column index="4" value="101"/><column index="5" value="108"/><column index="6" value="158"/><column index="7" value="127"/><column index="8" value="103"/><column index="9" value="72"/><column index="10" value="67"/><column index="11" value="74"/><column index="12" value="146"/><column index="13" value="64"/></column_widths><filter_values/><conditional_formats/><row_id_formats/><display_formats/><hidden_columns/><plot_y_axes/><global_filter/></table><table schema="main" name="employees" show_row_id="0" encoding="" plot_x_axis="" unlock_view_pk="_rowid_"><sort/><column_widths><column index="2" value="64"/><column index="3" value="59"/><column index="4" value="59"/><column index="5" value="181"/><column index="6" value="65"/><column index="7" value="60"/><column index="8" value="120"/></column_widths><filter_values/><conditional_formats/><row_id_formats/><display_formats/><hidden_columns/><plot_y_axes/><global_filter/></table><table schema="main" name="offices" show_row_id="0" encoding="" plot_x_axis="" unlock_view_pk="_rowid_"><sort/><column_widths><column index="1" value="65"/><column index="2" value="80"/><column index="4" value="137"/><column index="5" value="77"/><column index="6" value="69"/><column index="7" value="54"/><column index="8" value="67"/><column index="9" value="51"/></column_widths><filter_values/><conditional_formats/><row_id_formats/><display_formats/><hidden_columns/><plot_y_axes/><global_filter/></table></browse_table_settings></tab_browse><tab_sql><sql name="project.sql"> /*
      Introduction:

As part of this project we will be analysing the scale care model datbase using SQL to answer following questions:
Question 1: Which products should we order more of or less of?
Question 2: How should we tailor marketing and communication strategies to customer behaviors?
Question 3: How much can we spend on acquiring new customers?

Database Schema/Summary:

customers : customer  data
employees : all employee information
offices   : sales office information
orders    : customer's sales orders
orderdetails : sales order line for each customerName 
payments  : customer's payment records
products  : product information 
productlines : a list of product line categories
*/

SELECT  &quot;Customers&quot; AS table_name, '13' AS number_of_attributes, COUNT(*)  AS number_of_rows
FROM customers
UNION ALL
SELECT  &quot;Products&quot; AS  table_name, '9' AS number_of_attributes, COUNT(*) AS number_of_rows
FROM products
UNION ALL
SELECT  &quot;ProductLines&quot; AS  table_name, '4' AS number_of_attributes, COUNT(*) AS number_of_rows
FROM productlines
UNION ALL
SELECT  &quot;Orders&quot; AS  table_name, '7' AS number_of_attributes, COUNT(*) AS number_of_rows
FROM orders
UNION ALL
SELECT  &quot;OrderDetails&quot; AS  table_name, '5' AS number_of_attributes, COUNT(*) AS number_of_rows
FROM orderdetails
UNION ALL
SELECT  &quot;Payments&quot; AS  table_name, '4' AS number_of_attributes, COUNT(*) AS number_of_rows
FROM payments
UNION ALL
SELECT  &quot;Employees&quot; AS  table_name, '8' AS number_of_attributes, COUNT(*) AS number_of_rows
FROM employees
UNION ALL
SELECT  &quot;Offices&quot; AS  table_name, '9' AS number_of_attributes, COUNT(*) AS number_of_rows
FROM offices;

--Write  a query to compute the low stock for each product using a correlated subquery
/*Data tables needed: orderdetails , products
low stock = SUM(quantityOrdered) / quantityInStock
productperformance = SUM(quantityOrdered * priceEach)
*/
-- Question 1: Which Products Should We Order More of or Less of?

--Low stock
SELECT productCode, 
       ROUND(SUM(quantityOrdered) * 1.0 / (SELECT quantityInStock
					     FROM products p
					    WHERE od.productCode = p.productCode), 2) AS low_stock
  FROM orderdetails od
 GROUP BY productCode
 ORDER BY low_stock DESC
 LIMIT 10;

 --Product Performance
SELECT productCode, 
       SUM(quantityOrdered * priceEach) AS prod_perf
  FROM orderdetails od
 GROUP BY productCode 
 ORDER BY prod_perf DESC
 LIMIT 10;
 
 -- Write a query to combine low stock and product performance queries using CTE to display priority products for restocking
WITH
low_stock_table AS (
SELECT productCode, 
       ROUND(SUM(quantityOrdered) * 1.0/(SELECT quantityInStock
				           FROM products AS p
					  WHERE od.productCode = p.productCode), 2) AS low_stock
  FROM orderdetails od
 GROUP BY productCode
 LIMIT 10
)
SELECT od.productCode,
	p.productName,
	p.productLine,
	SUM(quantityOrdered*priceEach) AS prod_perf,
	ROUND(SUM(quantityOrdered) * 1.0/(SELECT quantityInStock
					    FROM products AS p
				           WHERE od.productCode = p.productCode), 2) AS low_stock
  FROM orderdetails od
  JOIN products AS p
    ON od.productCode = p.productCode
 WHERE od.productCode IN (SELECT productCode
                         FROM low_stock_table)
   GROUP BY od.productCode
   ORDER BY prod_perf DESC
    LIMIT 10;
 
 --Compute profit by customer
SELECT o.customerNumber,
       SUM(od.quantityOrdered * (od.priceEach-p.buyPrice)) AS profit_by_customer
  FROM products p
 INNER JOIN orderdetails od
    ON p.productCode = od.productCode
 INNER JOIN orders o
    ON od.orderNumber = o.orderNumber
 GROUP BY customerNumber
 ORDER BY profit_by_customer DESC;
 
--Top 5 VIP Customers
 WITH 
 customer_profit_table AS (
      SELECT o.customerNumber,
	     SUM(od.quantityOrdered * (od.priceEach-p.buyPrice)) AS customer_profit
	FROM products p
       INNER JOIN orderdetails AS od
          ON p.productCode = od.productCode
       INNER JOIN orders o
          ON od.orderNumber = o.orderNumber
       GROUP BY o.customerNumber
)
SELECT c.contactLastName,
       c.contactFirstName,
       c.city,
       c.country,
       cpt.customer_profit
  FROM customer_profit_table cpt
 INNER JOIN customers c
    ON cpt.customerNumber=c.customerNumber
 GROUP BY cpt.customerNumber
 ORDER BY customer_profit DESC
 LIMIT 5;
 
  --Top 5 Least Engaged Customers
 WITH 
  customer_profit_table AS (
SELECT  o.customerNumber,
	SUM(od.quantityOrdered * (od.priceEach-p.buyPrice)) AS customer_profit
   FROM products p
  INNER JOIN orderdetails AS od
     ON p.productCode = od.productCode
  INNER JOIN orders o
     ON od.orderNumber = o.orderNumber
  GROUP BY o.customerNumber
)
SELECT c.contactLastName,
       c.contactFirstName,
       c.city,
       c.country,
       cpt.customer_profit
  FROM customer_profit_table cpt
 INNER JOIN customers c
    ON cpt.customerNumber=c.customerNumber
 GROUP BY cpt.customerNumber
 ORDER BY customer_profit ASC
 LIMIT 5;
	
--Customer LTV (average amount of money a customer generates)
 WITH 
  customer_profit_table AS (
SELECT o.customerNumber,
       SUM(od.quantityOrdered * (od.priceEach-p.buyPrice)) AS customer_profit
  FROM products p
 INNER JOIN orderdetails AS od
    ON p.productCode = od.productCode
 INNER JOIN orders o
    ON od.orderNumber = o.orderNumber
 GROUP BY o.customerNumber
)
SELECT AVG(customer_profit) AS lifetime_value
  FROM customer_profit_table cpt;

/* Conclusion 

Question 1: Which products should we order more of or less of?

Across our Product Line, Classic Cars are the greatest contributor to company revenue as their prodcut performance is the greatest.
Meanwhile, Classic Cars represent half of the top 10 low stock products, with the 1968 Ford Mustang Order to InStock  ratio at 13.72 : 1.
Clearly, Classic Cars are the top priority for restocking. 
Motorcycle products are also a significant factor to company revenue. This product category represents 4/10 of both the top 10 product performers and low stock products.

Question 2:  How should we match marketing and communication strategies to customer behaviors?

Recognizing and rewarding our loyal customers is crucial. Organizing exclusive events and initiatives tailored for our VIP customers will foster loyalty, enhance satisfaction,
create exclusivity, and bolster their connection with our brand.To engage less active customers, targeted campaigns and initiatives will be initiated to reignite their interest
and involvement. Identifying their unique preferences and needs will guide the design of compelling promotions and experiences, effectively reigniting their enthusiasm for our 
brand.

Question 3: How much can we spend on acquiring new customers?

LTV helps us identify the average profit one customer will generate for the business. We can use it to predict future profits. For ecxample, if we are to acquire 10 new customers
every month, for the next year, that should generate about $4,684,751.00 in revenue from new business alone. If the LTV average is $39,039.59 then we should look for marketing
strategies that target desnse cities within countries that most contribute to our bottom line (USA, Spain, Denmark). If the marketing plan is strongly likely to generate 10 new 
customers in a specific period of time, for $100,000 in advertising costs, we could potentially secure $290,395 in profit and a new class of customers.

THE END
*/</sql><sql name="SQL 1"></sql><current_tab id="0"/></tab_sql></sqlb_project>
