-- 1. Product Sales
-- You need to create a report on whether customers who purchased the product named '2TB Red 5400 rpm SATA III 3.5 Internal NAS HDD' buy the product below or not.
-- 1. 'Polk Audio - 50 W Woofer - Black' -- (other_product)
-- To generate this report, you are required to use the appropriate SQL Server Built-in functions or expressions as well as basic SQL knowledge.

SELECT TOP 3 d.customer_id, d.first_name, d.last_name, 
CASE WHEN d.customer_id IN
(SELECT d.customer_id
FROM sale.order_item a
JOIN product.product b
ON a.product_id = b.product_id
JOIN sale.orders c
ON a.order_id = c.order_id
JOIN sale.customer d
ON c.customer_id = d.customer_id
WHERE b.product_name = 'Polk Audio - 50 W Woofer - Black')
THEN 'YES' ELSE 'NO' END AS other_product
FROM sale.order_item a
JOIN product.product b
ON a.product_id = b.product_id
JOIN sale.orders c
ON a.order_id = c.order_id
JOIN sale.customer d
ON c.customer_id = d.customer_id
WHERE b.product_name = '2TB Red 5400 rpm SATA III 3.5 Internal NAS HDD'
ORDER BY d.customer_id


-- 2. Conversion Rate
-- Below you see a table of the actions of customers visiting the website by clicking on two different types of advertisements given by an E-Commerce company. Write a query to return the conversion rate for each Advertisement type.


CREATE TABLE sale.Actions(
[Visitor_ID] INT PRIMARY KEY IDENTITY (1,1),
[Adv_Type] CHAR(1) NOT NULL,
[Action] NVARCHAR(MAX) NOT NULL	
	);

INSERT INTO sale.Actions ([Adv_Type],[Action]) VALUES
('A','Left'),
('A','Order'),
('B','Left'),
('A','Order'),
('A','Review'),
('A','Left'),
('B','Left'),
('B','Order'),
('B','Review'),
('A','Review')

SELECT Adv_Type,
	((SELECT COUNT(1) 
	FROM sale.actions b
	WHERE a.Adv_Type = b.Adv_Type
	AND Action='Order'
	GROUP BY Adv_Type)*1.0/
	(SELECT COUNT(1) 
	FROM sale.actions b
	WHERE a.Adv_Type = b.Adv_Type
	GROUP BY Adv_Type)*1.0)
FROM sale.actions a
GROUP BY Adv_Type