--- Sales Performance Analysis
--Q1: What are the total sales and total quantity sold?

SELECT SUM(QUANTITY) AS TOTAL_QUANTITY_SOLD, SUM(S.QUANTITY*P.UNIT_PRICE_USD) AS TOTAL_SALES
FROM SALES AS S
JOIN PRODUCTS AS P ON S.PRODUCT_KEY = P.PRODUCT_KEY

--Q2: What are the top-selling products by revenue?

SELECT PRODUCT_NAME, SUM(S.QUANTITY*P.UNIT_PRICE_USD) AS REVENUE
FROM SALES AS S
JOIN PRODUCTS AS P ON S.PRODUCT_KEY = P.PRODUCT_KEY
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10

--Q3: What are the top-selling brands by revenue?

SELECT BRAND, SUM(S.QUANTITY*P.UNIT_PRICE_USD) AS REVENUE
FROM SALES AS S
JOIN PRODUCTS AS P ON S.PRODUCT_KEY = P.PRODUCT_KEY
GROUP BY 1
ORDER BY 2 DESC

--- Customer Insights
--Q4: What are the top countries by total sales?

SELECT COUNTRY, SUM(S.QUANTITY*P.UNIT_PRICE_USD) AS REVENUE
FROM SALES AS S
JOIN STORES AS ST ON S.STORE_KEY = ST.STORE_KEY
JOIN PRODUCTS AS P ON S.PRODUCT_KEY = P.PRODUCT_KEY
GROUP BY 1
ORDER BY 2 DESC

--Q5: What is the distribution of customers by gender?

SELECT GENDER, COUNT(*) AS TOTAL_CUSTOMER
FROM CUSTOMERS
GROUP BY 1

--Q6: What is the average customer age?

SELECT AVG(EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM BIRTHDAY)) AS AVG_CUSTOMER_AGE
FROM CUSTOMERS

--- Store Performance
--Q7: Which stores generate the highest sales?

SELECT ST.STORE_KEY, ST.COUNTRY, SUM(S.QUANTITY*P.UNIT_PRICE_USD) AS TOTAL_SALES
FROM STORES AS ST
JOIN SALES AS S ON ST.STORE_KEY = S.STORE_KEY
JOIN PRODUCTS AS P ON S.PRODUCT_KEY = P.PRODUCT_KEY
GROUP BY 1, 2
ORDER BY 3 DESC

--Q8: What is the average store size (square meters) in each country?

SELECT COUNTRY, AVG(SQUARE_METERS) AS AVG_STORE_SIZE
FROM STORES
GROUP BY 1

--- Sales Trends Over Time
--Q9: What are the monthly sales trends?

SELECT EXTRACT(YEAR FROM ORDER_DATE) AS YEAR,
	   EXTRACT(MONTH FROM ORDER_DATE) AS MONTH,
	   SUM(S.QUANTITY*P.UNIT_PRICE_USD) AS TOTAL_SALES
FROM SALES AS S
JOIN PRODUCTS AS P ON S.PRODUCT_KEY = P.PRODUCT_KEY
GROUP BY 1, 2
ORDER BY 1, 2

--Q10: What is the average delivery time?

SELECT AVG(DELIVERY_DATE - ORDER_DATE) AS AVG_DELIVERY_DATE
FROM SALES
WHERE DELIVERY_DATE IS NOT NULL;

---Currency & Exchange Rate Impact
--Q11: What is the trend of exchange rates for different currencies?

SELECT 
    Currency,
    Date,
    Exchange
FROM EXCHANGE_RATES
ORDER BY Currency, Date;

--Q12: How much revenue was generated per currency?

SELECT 
    S.CURRENCY_CODE,
    SUM(S.QUANTITY * P.UNIT_PRICE_USD * ER.EXCHANGE) AS TOTAL_REVENUE_LOCAL
FROM SALES S
JOIN PRODUCTS P ON S.PRODUCT_KEY = P.PRODUCT_KEY
JOIN EXCHANGE_RATES ER ON S.CURRENCY_CODE = ER.CURRENCY
GROUP BY S.CURRENCY_CODE;

---Advance Queries
--Q13: Find the Most Profitable Products by Country

SELECT C.COUNTRY, P.PRODUCT_NAME, SUM((P.UNIT_PRICE_USD - P.UNIT_COST_USD) * S.QUANTITY) AS PROFIT
FROM SALES AS S
JOIN PRODUCTS AS P ON S.PRODUCT_KEY = P.PRODUCT_KEY
JOIN CUSTOMERS AS C ON S.CUSTOMER_KEY = C.CUSTOMER_KEY
GROUP BY 1, 2
ORDER BY 3 DESC

--Q14: Do a Customer Lifetime Value (CLV) Analysis

SELECT C.CUSTOMER_KEY, C.NAME, C.COUNTRY, SUM(S.QUANTITY * P.UNIT_PRICE_USD) AS TOTAL_REVENUE
FROM CUSTOMERS C
JOIN SALES S ON C.CUSTOMER_KEY = S.CUSTOMER_KEY
JOIN PRODUCTS P ON S.PRODUCT_KEY = P.PRODUCT_KEY
GROUP BY 1, 2, 3
ORDER BY 4 DESC

--Q15: Do a Delivery Performance Analysis (Late Deliveries & Avg Delay per Country)

SELECT 
    C.COUNTRY,
    COUNT(*) AS LATE_DELIVERIES,
    ROUND(AVG(S.DELIVERY_DATE - S.ORDER_DATE), 2) AS AVG_DELAY_DAYS
FROM SALES S
JOIN CUSTOMERS C ON S.CUSTOMER_KEY = C.CUSTOMER_KEY
WHERE S.DELIVERY_DATE IS NOT NULL 
    AND S.DELIVERY_DATE > S.ORDER_DATE
GROUP BY C.COUNTRY
ORDER BY LATE_DELIVERIES DESC;

--Q16: Use a Stored Procedure to get Top N Products by Profit.

CREATE OR REPLACE FUNCTION GET_TOP_PROFITABLE_PRODUCTS(COUNTRY_NAME TEXT, LIMIT_N INT)
RETURNS TABLE (PRODUCT_NAME TEXT, TOTAL_PROFIT NUMERIC)
LANGUAGE PLPGSQL
AS $$
BEGIN
    RETURN QUERY 
    SELECT 
        P.PRODUCT_NAME::TEXT,  -- Explicitly cast to TEXT
        SUM((P.UNIT_PRICE_USD - P.UNIT_COST_USD) * S.QUANTITY)::NUMERIC AS TOTAL_PROFIT  -- Cast SUM to NUMERIC
    FROM SALES S
    JOIN PRODUCTS P ON S.PRODUCT_KEY = P.PRODUCT_KEY
    JOIN CUSTOMERS C ON S.CUSTOMER_KEY = C.CUSTOMER_KEY
    WHERE C.COUNTRY = COUNTRY_NAME
    GROUP BY P.PRODUCT_NAME
    ORDER BY TOTAL_PROFIT DESC
    LIMIT LIMIT_N;
END;
$$;

-- CALL PROCEDURE
SELECT * FROM Get_Top_Profitable_Products('United States', 5);
SELECT * FROM Get_Top_Profitable_Products('Australia', 5);

--Q17:Rank Stores by Revenue using Window Function

SELECT ST.STORE_KEY, ST.COUNTRY, SUM(S.QUANTITY * P.UNIT_PRICE_USD) AS TOTAL_REVENUE,
	   RANK() OVER (PARTITION BY COUNTRY ORDER BY SUM(S.QUANTITY * P.UNIT_PRICE_USD)DESC) AS RANK
FROM STORES ST
JOIN SALES S ON ST.STORE_KEY = S.STORE_KEY
JOIN PRODUCTS P ON S.PRODUCT_KEY = P.PRODUCT_KEY
GROUP BY 1, 2

--Q18: Show a monthly revenue growth.

WITH MONTHLY_REVENUE AS (
	SELECT 
		TO_CHAR(ORDER_DATE, 'YYYY-MM') AS YEAR_MONTH,
		SUM(S.QUANTITY * P.UNIT_PRICE_USD)::NUMERIC AS TOTAL_REVENUE,   -- Convert SUM to NUMERIC
		LAG(SUM(S.QUANTITY * P.UNIT_PRICE_USD)::NUMERIC) OVER (ORDER BY TO_CHAR(ORDER_DATE, 'YYYY-MM')) AS PREV_MONTH_REVENUE
	FROM SALES S
	JOIN PRODUCTS P ON S.PRODUCT_KEY = P.PRODUCT_KEY
	GROUP BY YEAR_MONTH
)
	SELECT 
		YEAR_MONTH,
		TOTAL_REVENUE,
		PREV_MONTH_REVENUE,
		ROUND(((TOTAL_REVENUE - PREV_MONTH_REVENUE)
			   /NULLIF(PREV_MONTH_REVENUE, 0) * 100)::NUMERIC,2)   -- Prevent division by zero
			   AS REVENUE_GROWTH_PERCENTAGE
	FROM MONTHLY_REVENUE

--Q19: Create an Order Status column and use store procedure to automatically update Order Status

ALTER TABLE SALES ADD COLUMN ORDER_STATUS TEXT;

UPDATE SALES
SET ORDER_STATUS = 
    CASE 
        WHEN DELIVERY_DATE IS NOT NULL THEN 'Delivered'
        ELSE 'Pending'
    END;

CREATE OR REPLACE FUNCTION UPDATE_ORDER_STATUS()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
    IF NEW.DELIVERY_DATE IS NOT NULL THEN
        NEW.ORDER_STATUS := 'Delivered';
    ELSE
        NEW.ORDER_STATUS := 'Pending';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER SET_ORDER_STATUS
BEFORE INSERT OR UPDATE ON SALES
FOR EACH ROW 
EXECUTE FUNCTION UPDATE_ORDER_STATUS();

-- testing function

INSERT INTO CUSTOMERS (CUSTOMER_KEY, NAME, CITY, STATE, COUNTRY, CONTINENT, BIRTHDAY)
VALUES (1001, 'John Doe', 'New York', 'NY', 'USA', 'North America', '1985-05-20');

INSERT INTO EXCHANGE_RATES (DATE, CURRENCY, EXCHANGE) 
VALUES ('2025-01-10', 'USD', 1.0);

INSERT INTO SALES (ORDER_NUMBER, LINE_ITEM, ORDER_DATE, DELIVERY_DATE, CUSTOMER_KEY, STORE_KEY, PRODUCT_KEY, QUANTITY, CURRENCY_CODE) 
VALUES (123456, 1, '2025-01-10', NULL, 1001, 50, 2001, 10, 'USD');

SELECT ORDER_NUMBER, ORDER_STATUS
FROM SALES
WHERE ORDER_NUMBER = 123456;

--- OR

UPDATE SALES 
SET Delivery_Date = '2025-01-15'
WHERE Order_Number = 123456;

SELECT ORDER_NUMBER, ORDER_STATUS
FROM SALES 
WHERE ORDER_NUMBER = 123456;


--Q20: Create a summary table

CREATE VIEW Sales_Summary AS
SELECT 
    c.Country, 
    st.Store_Key,
    SUM(s.Quantity * p.Unit_Price_USD) AS Total_Revenue,
    COUNT(DISTINCT s.Order_Number) AS Total_Orders,
    ROUND(AVG(s.Quantity * p.Unit_Price_USD)::NUMERIC, 2) AS Avg_Order_Value
FROM SALES s
JOIN CUSTOMERS c ON s.Customer_Key = c.Customer_Key
JOIN PRODUCTS p ON s.Product_Key = p.Product_Key
JOIN STORES st ON s.Store_Key = st.Store_Key
GROUP BY c.Country, st.Store_Key;

--- checking view summary
SELECT * FROM Sales_Summary LIMIT 10;



SELECT * FROM SALES
SELECT * FROM CUSTOMERS
SELECT * FROM STORES
SELECT * FROM PRODUCTS
SELECT * FROM EXCHANGE_RATES