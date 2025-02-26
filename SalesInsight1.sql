SELECT * FROM sales.customers limit 100;
SELECT * FROM sales.date limit 100;
SELECT * FROM sales.markets limit 100;
SELECT * FROM sales.products limit 100;
SELECT * FROM sales.transactions limit 100;

SELECT COUNT(*) FROM sales.customers;
SELECT COUNT(*) FROM sales.date;
SELECT COUNT(*) FROM sales.markets;
SELECT COUNT(*) FROM sales.products;
SELECT COUNT(*) FROM sales.transactions;

SELECT sales.transactions.* , sales.date.* 
FROM sales.transactions  INNER JOIN sales.date 
ON sales.transactions.order_date=sales.date.date;

SELECT SUM(sales.transactions.sales_amount)
FROM sales.transactions  INNER JOIN sales.date 
ON sales.transactions.order_date=sales.date.date
WHERE sales.date.year='2020';

SELECT SUM(sales.transactions.sales_amount) as Total_SalesInChennai_2020
FROM sales.transactions  INNER JOIN sales.date 
ON sales.transactions.order_date=sales.date.date
WHERE sales.date.year='2020'
AND sales.transactions.market_code=
(SELECT market_code FROM sales.markets WHERE sales.markets.markets_name='Chennai');

SELECT DISTINCT Currency FROM transactions;
SET SQL_SAFE_UPDATES = 0;
#the data contains duplicate rows in transaction as currency 'USD' and 'USD\r' contains same data
#the data contains duplicate rows in transaction as currency 'INR' and 'INR\r' contains same data
DELETE FROM sales.transactions  
WHERE currency IN ('USD', 'INR');

SET SQL_SAFE_UPDATES = 1;

SELECT COUNT(*) FROM sales.transactions;

#TOP 5 Cutomers with High revenue
SELECT sales.customers.custmer_name, SUM(sales.transactions.sales_amount) as total_revenue FROM 
sales.transactions INNER JOIN sales.customers 
ON sales.transactions.customer_code=sales.customers.customer_code
GROUP BY sales.customers.custmer_name
ORDER BY total_revenue DESC
LIMIT 5;

#TOP Market places
SELECT sales.markets.markets_name, SUM(sales.transactions.sales_amount) AS REVENUE FROM
sales.markets JOIN sales.transactions
ON sales.markets.markets_code=sales.transactions.market_code
GROUP BY sales.markets.markets_name
ORDER BY REVENUE DESC
LIMIT 10;

#Revenue at different zones of top market places
WITH TopMarkets AS (
    SELECT sales.markets.markets_code, sales.markets.markets_name
    FROM sales.markets
    JOIN sales.transactions 
    ON sales.markets.markets_code = sales.transactions.market_code
    GROUP BY sales.markets.markets_code, sales.markets.markets_name
    ORDER BY SUM(sales.transactions.sales_amount) DESC
    LIMIT 3
)
SELECT 
    sales.markets.zone,  
    TopMarkets.markets_name,  
    SUM(sales.transactions.sales_amount) AS REVENUE
FROM TopMarkets  
JOIN sales.transactions  
ON TopMarkets.markets_code = sales.transactions.market_code  
JOIN sales.markets  
ON TopMarkets.markets_code = sales.markets.markets_code  
GROUP BY sales.markets.zone, TopMarkets.markets_name
ORDER BY REVENUE DESC;

# Month to month growth percentage
SELECT curr.year,curr.month, (CURR.revenue-PREVIOUS.revenue)/PREVIOUS.revenue*100 as growth_percentage
FROM
(SELECT sales.date.year,MONTH(STR_TO_DATE(sales.date.date, '%Y-%m-%d')) AS month,SUM(sales.transactions.sales_amount) as revenue
FROM sales.date JOIN sales.transactions
ON sales.date.date= sales.transactions.order_date
GROUP BY sales.date.year,month) CURR
JOIN
(SELECT sales.date.year,MONTH(STR_TO_DATE(sales.date.date, '%Y-%m-%d')) AS month,SUM(sales.transactions.sales_amount) as revenue
FROM sales.date JOIN sales.transactions
ON sales.date.date= sales.transactions.order_date
GROUP BY sales.date.year,month) PREVIOUS
ON CURR.month=PREVIOUS.month+1
ORDER BY CURR.year,PREVIOUS.month;

WITH RevenueByMonth AS (
    SELECT 
        CAST(sales.date.year AS UNSIGNED) AS year,  
        MONTH(STR_TO_DATE(sales.date.date, '%Y-%m-%d')) AS month,  -- Extract numeric month from full date
        TRIM(REPLACE(sales.date.month_name, '\r', '')) AS month_name,  -- Clean up month_name
        SUM(sales.transactions.sales_amount) AS revenue
    FROM sales.date  
    JOIN sales.transactions  
    ON sales.date.date = sales.transactions.order_date  
    GROUP BY sales.date.year, month, sales.date.month_name
)
SELECT 
    curr.year,  
    curr.month_name,  
    ((curr.revenue - prev.revenue) / NULLIF(prev.revenue, 0)) * 100 AS growth_percentage 
FROM RevenueByMonth curr
LEFT JOIN RevenueByMonth prev  
ON (curr.year = prev.year AND curr.month = prev.month + 1)  
   OR (curr.year = prev.year + 1 AND curr.month = 1 AND prev.month = 12)  
ORDER BY curr.year, curr.month;

