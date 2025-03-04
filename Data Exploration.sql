--- General Table Information
--How many records are there in each table?

SELECT 'SALES' AS Table_Name, COUNT(*) AS TOTAL_ROWS FROM SALES
UNION ALL
SELECT 'CUSTOMERS', COUNT(*) FROM CUSTOMERS
UNION ALL
SELECT 'PRODUCTS', COUNT(*) FROM PRODUCTS
UNION ALL
SELECT 'STORES', COUNT(*) FROM STORES
UNION ALL
SELECT 'EXCHANGE_RATE', COUNT(*) FROM EXCHANGE_RATES;


--- Sales Table Exploration
--What is the date range of orders in the Sales table?

SELECT MIN(ORDER_DATE) AS FIRST_ORDER_DATE,
	   MAX(ORDER_DATE) AS LAST_ORDER_DATE
FROM SALES;

--What are the distinct currencies used in sales?

SELECT DISTINCT(CURRENCY_CODE)
FROM SALES

--How many unique customers, products, and stores exist in the sales data?

SELECT DISTINCT(CUSTOMER_KEY) FROM SALES;
SELECT DISTINCT(PRODUCT_KEY) FROM SALES;
SELECT DISTINCT(STORE_KEY) FROM SALES
ORDER BY 1;

--- Customer Table Exploration
--What are the unique countries where customers are located?

SELECT DISTINCT(COUNTRY)
FROM CUSTOMERS

--What is the age range of customers?

SELECT 
    MIN(EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM Birthday)) AS Youngest_Age,
    MAX(EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM Birthday)) AS Oldest_Age
FROM CUSTOMERS;

--- Products Table Exploration
--How many unique brands and categories exist?

SELECT DISTINCT(BRAND) AS UNIQUE_BRAND FROM PRODUCTS;
SELECT DISTINCT(CATEGORY) AS UNIQUE_CATEGORY FROM PRODUCTS;

--What is the price range of products?

SELECT MIN(UNIT_PRICE_USD) AS MIN_PRICE,
	   MAX(UNIT_PRICE_USD) AS MAX_PRICE,
	   AVG(UNIT_PRICE_USD) AS AVG_PRICE
FROM PRODUCTS

--- Stores Table Exploration
--What is the geographical distribution of stores?

SELECT COUNTRY, COUNT(*) AS STORE_COUNT
FROM STORES
GROUP BY 1
ORDER BY 2 DESC

--What is the range of store sizes?

SELECT MIN(SQUARE_METERS) AS SMALLEST_STORE,
	   MAX(SQUARE_METERS) AS LARGEST_STORE,
	   AVG(SQUARE_METERS) AS AVG_STORE_SIZE
FROM STORES
WHERE STORE_KEY <> 0;

--- Exchange Rate Table Exploration
--What are the different currencies present in the exchange rate table?

SELECT DISTINCT(CURRENCY)
FROM EXCHANGE_RATES

--What is the date range of exchange rates?

SELECT MIN(DATE) AS EARLIEST_DATE,
	   MAX(DATE) AS LATEST_DATE
FROM EXCHANGE_RATES
