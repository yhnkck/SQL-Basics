-- CREATE DATABASE ecommerce

USE ecommerce
GO

SELECT *
FROM e_commerce
ORDER BY Ord_ID
GO

--Find the top 3 customers who have the maximum count of orders.

SELECT TOP 3 Cust_ID, Customer_Name, COUNT(DISTINCT Ord_ID) AS CNT
FROM DBO.e_commerce
GROUP BY Cust_ID,Customer_Name
ORDER BY CNT DESC
GO

--Find the customer whose order took the maximum time to get shipping.

SELECT TOP 1 *
FROM dbo.e_commerce
ORDER BY DaysTakenForShipping DESC
GO

--Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011

SELECT COUNT (DISTINCT Cust_ID)
FROM dbo.e_commerce
WHERE YEAR(Order_Date)=2011
AND MONTH(Order_Date)='1'


SELECT MONTH(Order_Date), COUNT(DISTINCT Cust_ID)
FROM dbo.e_commerce A
WHERE EXISTS (
				SELECT 1
				FROM DBO.e_commerce B
				WHERE YEAR(Order_Date)=2011
				AND MONTH(Order_Date)='1'
				AND A.Cust_ID=B.Cust_ID)
AND YEAR(Order_Date)=2011
GROUP BY MONTH(Order_Date)
ORDER BY 1
GO

--Write a query to return for each user the time elapsed between the first purchasing and the third purchasing, in ascending order by Customer ID
WITH CTE AS
(
SELECT Ord_ID,Order_Date, Cust_ID,
FIRST_VALUE (Order_Date) OVER (PARTITION BY Cust_ID ORDER BY Order_Date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS first_order_date,
DENSE_RANK() OVER (PARTITION BY Cust_ID ORDER BY Order_Date) AS RN
FROM DBO.e_commerce
)
SELECT DISTINCT Cust_ID, first_order_date, Order_Date AS third_order_date, DATEDIFF(DAY,first_order_date, Order_Date) AS days_elapsed
FROM CTE
WHERE RN=3
GO

--Write a query that returns customers who purchased both product 11 and product 14, as well as the ratio of these products to the total number of products purchased by the customer.

 
WITH CTE AS
(
SELECT Cust_ID
FROM dbo.e_commerce
WHERE Prod_ID='Prod_11'
INTERSECT
SELECT Cust_ID
FROM dbo.e_commerce
WHERE Prod_ID='Prod_14'
),
CTE2 AS
(
SELECT DISTINCT A.Cust_ID, A.Prod_ID,
SUM(Order_Quantity) OVER (PARTITION BY A.Cust_ID, A.Prod_ID) AS CNT,
CASE WHEN A.Prod_ID='Prod_11' OR A.Prod_ID='Prod_14' THEN 'selected'
ELSE 'not selected'
END AS selection
FROM dbo.e_commerce A, CTE
WHERE A.Cust_ID=CTE.Cust_ID
)

SELECT DISTINCT Cust_ID,selection,
SUM(CNT) OVER (PARTITION BY Cust_ID, selection)/
SUM(CNT) OVER (PARTITION BY Cust_ID)
FROM CTE2
GO

--Create a “view” that keeps visit logs of customers on a monthly basis. (For each log, three field is kept: Cust_id, Year, Month)

CREATE OR ALTER VIEW monthly_log AS
SELECT Cust_ID, YEAR(Order_Date) AS year_,MONTH(Order_Date) AS month_
FROM dbo.e_commerce
GO

SELECT * FROM dbo.monthly_log
ORDER BY 1,2,3
GO

--Create a “view” that keeps the number of monthly visits by users. (Show separately all months from the beginning business)

CREATE OR ALTER VIEW monthly_visits AS
SELECT YEAR(Order_Date) AS year_, MONTH(Order_Date) AS month_, COUNT(Cust_ID) AS number_of_monthly_visits
FROM dbo.e_commerce
GROUP BY YEAR(Order_Date),MONTH(Order_Date)
GO

SELECT * FROM dbo.e_commerce
ORDER BY 1,2
GO

--For each visit of customers, create the next month of the visit as a separate column.

SELECT Cust_ID, Customer_Name, Order_Date,
LEAD (MONTH(Order_Date)) OVER (PARTITION BY Cust_ID ORDER BY Order_Date) next_visit_month
FROM dbo.e_commerce
GO

--Calculate the monthly time gap between two consecutive visits by each customer.

WITH CTE AS(
SELECT Cust_ID, Customer_Name, Order_Date,
LEAD (Order_Date) OVER (PARTITION BY Cust_ID ORDER BY Order_Date) next_visit
FROM dbo.e_commerce
)
SELECT *, DATEDIFF(MONTH, Order_Date, next_visit) AS monthly_gap
FROM CTE
GO

--Categorise customers using average time gaps. Choose the most fitted labeling model for you.

CREATE VIEW cust_logs AS
SELECT	Cust_ID, YEAR(Order_Date) ord_year, MONTH(Order_Date) ord_month, 
		COUNT (*) logs
FROM	dbo.e_commerce
GROUP BY 
		Cust_ID, YEAR(Order_Date), MONTH(Order_Date)
GO

CREATE VIEW time_gaps as
WITH T1 AS 
(
select *, 
		DENSE_RANK() OVER (order by ord_year, ord_month) data_month
from cust_logs
)
SELECT *, LAG (data_month) OVER (PARTITION BY cust_ID ORDER BY data_month) prev_month,
		data_month - LAG (data_month) OVER (PARTITION BY cust_ID ORDER BY data_month) time_gap
FROM T1

GO


SELECT	Cust_ID, 
		CASE WHEN AVG (time_gap) IS NULL THEN 'CHURN'
				WHEN AVG (time_gap) BETWEEN 1 AND 2 THEN 'REGULAR'
					WHEN AVG (time_gap) > 2  THEN 'IRREGULAR'
		END CUST_SEGMENT
FROM	time_gaps
GROUP BY 
		Cust_ID
GO

--Find month-by-month customer retention rate  since the start of the business.

WITH T1 AS
(
SELECT *, COUNT (Cust_ID) over (PARTITION BY data_month) CNT_RETAINED_CUST
FROM	time_gaps
WHERE	time_gap = 1
) , T2 AS
(
SELECT *, COUNT (Cust_ID) over (PARTITION BY data_month) TOTAL_CUST
FROM	time_gaps
) 
SELECT	DISTINCT T1.Ord_year, T1.ord_month, T1.data_month, CNT_RETAINED_CUST, TOTAL_CUST,
		CAST(1.0*CNT_RETAINED_CUST / TOTAL_CUST AS NUMERIC (3,2)) AS RETENTION_RATE
FROM	T1, T2
WHERE	T1.data_month = T2.data_month
GO