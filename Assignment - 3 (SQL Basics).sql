/*
Discount Effects
Generate a report including product IDs and discount effects on whether the increase in the discount rate positively impacts the number of orders for the products.
In this assignment, you are expected to generate a solution using SQL with a logical approach. */


SELECT * FROM sale.orders;
SELECT * FROM sale.order_item
ORDER BY product_id;


SELECT A.product_id,A.product_name, B.list_price,B.discount, C.order_date, SUM(B.quantity) AS qt_sold
FROM product.product A
LEFT JOIN sale.order_item B
ON A.product_id=B.product_id
LEFT JOIN sale.orders C
ON B.order_id=C.order_id
GROUP BY  A.product_id, A.product_name, B.list_price,B.discount,C.order_date
ORDER BY A.product_id, C.order_date;




WITH CTE AS(
SELECT A.product_id,A.product_name, B.list_price,B.discount, SUM(B.quantity) AS qt_sold,
AVG(SUM(B.quantity*1.0)) OVER (PARTITION BY A.product_id ) AS ort,-- ORDER BY B.discount ROWS BETWEEN 1 PRECEDING AND CURRENT ROW

ROW_NUMBER () OVER (PARTITION BY A.product_id ORDER BY B.discount DESC) AS row_nu


FROM product.product A
LEFT JOIN sale.order_item B
ON A.product_id=B.product_id
GROUP BY  A.product_id, A.product_name, B.list_price,B.discount
--ORDER BY A.product_id,B.discount
)

SELECT *,

CASE 
	WHEN COUNT(product_id) OVER (PARTITION BY product_id )=4 
		THEN '4'
END AS CNT,
FIRST_VALUE (qt_sold) OVER (PARTITION BY product_id ORDER BY discount DESC) AS lst
FROM CTE;


WITH CTE AS(
SELECT A.product_id,A.product_name, B.list_price,B.discount, SUM(B.quantity) AS qt_sold,
(SUM(B.quantity)+LEAD (SUM(B.quantity)) OVER (PARTITION BY A.product_id ORDER BY B.discount DESC))*1.0/2 as avg22,
AVG(SUM(B.quantity*1.0)) OVER (PARTITION BY A.product_id ) AS ort
FROM product.product A
LEFT JOIN sale.order_item B
ON A.product_id=B.product_id
GROUP BY  A.product_id, A.product_name, B.list_price,B.discount
),

CTE2 AS(
SELECT A.product_id, B.discount,
FIRST_VALUE (SUM(B.quantity)) OVER (PARTITION BY A.product_id ORDER BY B.discount) AS lst
FROM product.product A
LEFT JOIN sale.order_item B
ON A.product_id=B.product_id
GROUP BY  A.product_id, A.product_name, B.list_price,B.discount
)

SELECT DISTINCT CTE.product_id,
CASE 
	WHEN COUNT(CTE.product_id) OVER (PARTITION BY CTE.product_id )=4
		THEN CASE 
				WHEN FIRST_VALUE (CTE.avg22) OVER (PARTITION BY CTE.product_id ORDER BY CTE.discount DESC)>CTE.ort
				THEN 'Positive'
				WHEN FIRST_VALUE (CTE.avg22) OVER (PARTITION BY CTE.product_id ORDER BY CTE.discount DESC)<CTE.ort
				THEN 'Negative'
				ELSE 'Neutral'
			END
	WHEN COUNT(CTE.product_id) OVER (PARTITION BY CTE.product_id )>=2
		THEN CASE 
				WHEN FIRST_VALUE (CTE.avg22) OVER (PARTITION BY CTE.product_id ORDER BY CTE.discount DESC)>CTE2.lst
				THEN 'Positive'
				WHEN FIRST_VALUE (CTE.avg22) OVER (PARTITION BY CTE.product_id ORDER BY CTE.discount DESC)<CTE2.lst
				THEN 'Negative'
				ELSE 'Neutral'
			END
	ELSE 'Neutral'
END AS Discount_Effect
FROM CTE, CTE2
WHERE CTE.product_id=CTE2.product_id
AND (CTE.discount=CTE2.discount
OR CTE.discount IS NULL)
ORDER BY CTE.product_id