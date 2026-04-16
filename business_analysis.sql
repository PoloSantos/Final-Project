-- Santos, Ralph Dimitri, 244113
-- Date of submission

-- I/we certify that this submission complies with the
-- DISCS Academic Integrity Policy.
-- If I/we have discussed my/our SQL code with anyone other than
-- my/our instructor(s), my/our groupmate(s), the teaching
-- assistants), the extent of each discussion has been clearly
-- noted along with a proper citation in the comments of my/our
-- program.
-- If any SQL code or documentation used in my/our program was
-- obtained from another source, either modified or unmodified,
-- such as a textbook, website or another individual, the extent
-- of its use has been clearly noted along with a proper citation
-- in the comments of my/our program.

DROP database shazada;

CREATE Database shazada;

USE shazada;

SOURCE /Users/polo/Desktop/codes/Project2-Santos-Polo-Lam-Kenz/customer_purchase.sql;
SOURCE /Users/polo/Desktop/codes/Project2-Santos-Polo-Lam-Kenz/customer.sql;
SOURCE /Users/polo/Desktop/codes/Project2-Santos-Polo-Lam-Kenz/product.sql;

DESCRIBE customer_purchase;
DESCRIBE customer;
DESCRIBE product;


-- 1. What are the daily sales from April 1, 2025 to May 31, 2025? Show date and daily sales amount.
-- Order by date, oldest to most recent.

SELECT DISTINCT transaction_date, SUM(quantity) OVER (PARTITION BY transaction_date)
FROM customer_purchase
WHERE MONTH(transaction_date) = 5 OR MONTH(transaction_date) = 4 
ORDER BY transaction_date ASC;

-- 2. What are the monthly sales from April 1, 2025 to May 31, 2025? Show month and total amount for the month.
-- Order by month, oldest to most recent.

SELECT DISTINCT MONTH(transaction_date), SUM(quantity) OVER (PARTITION BY MONTH(transaction_date))
FROM customer_purchase
WHERE MONTH(transaction_date) = 5 OR MONTH(transaction_date) = 4 
ORDER BY MONTH(transaction_date) ASC;

-- 3. How much is the overall sales for each city for the month of May 2025? Show city name and overall sales for the month.
-- Order by overall sales, highest to lowest.

SELECT DISTINCT MONTH(cp.transaction_date), SUM(cp.quantity) OVER (PARTITION BY c.city)
FROM customer_purchase AS cp
WHERE MONTH(cp.transaction_date) = 5 OR MONTH(cp.transaction_date) = 4 
ORDER BY MONTH(cp.transaction_date) ASC
JOIN customer AS c 
    ON c.customer_id = cp.customer_id;

-- 4. What are the top 10 products in terms of total sales (i.e. the products that generated the most revenue)?



-- 5. Who are our top 10 customers that have bought the most number of products overall?



-- 6. Who are our top 10 customers in terms of their overall spending? What is the product that they have respectively spent the most on, and how much have they spent on this product?



-- 7. For every city, what are our top 10 products in terms of overall sales?



-- 8. In terms of the total quantity of products purchased per month, what is our month-over-month growth from April 2025 to May 2025?


