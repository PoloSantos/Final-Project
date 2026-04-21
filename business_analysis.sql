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

-- DROP database shazada;

-- CREATE Database shazada;

-- USE shazada;

-- SOURCE customer.sql;
-- SOURCE product.sql;
-- SOURCE customer_purchase.sql;

-- DESCRIBE customer;
-- DESCRIBE product;
-- DESCRIBE customer_purchase;

-- 1. What are the daily sales from April 1, 2025 to May 31, 2025? Show date and daily sales amount.
-- Order by date, oldest to most recent.

SELECT DISTINCT cp.transaction_date, SUM(cp.quantity*p.unit_price) OVER (PARTITION BY cp.transaction_date) AS 'Sum per date'
FROM customer_purchase AS cp
JOIN product AS p
    ON p.product_id = cp.product_id
WHERE MONTH(cp.transaction_date) = 5 OR MONTH(cp.transaction_date) = 4 
ORDER BY cp.transaction_date ASC;

-- 2. What are the monthly sales from April 1, 2025 to May 31, 2025? Show month and total amount for the month.
-- Order by month, oldest to most recent.

SELECT DISTINCT MONTHNAME(cp.transaction_date) 'Month', SUM(cp.quantity*p.unit_price) OVER (PARTITION BY MONTH(cp.transaction_date)) AS 'Sum per month'
FROM customer_purchase AS cp
JOIN product AS p
    ON p.product_id = cp.product_id
WHERE MONTHNAME(cp.transaction_date) LIKE 'May' OR MONTHNAME(cp.transaction_date) LIKE 'April'
ORDER BY MONTHNAME(cp.transaction_date) ASC;

-- 3. How much is the overall sales for each city for the month of May 2025? Show city name and overall sales for the month.
-- Order by overall sales, highest to lowest.

SELECT DISTINCT c.city ,SUM(cp.quantity*p.unit_price) OVER (PARTITION BY c.city) AS 'Overall_Sales'
FROM customer_purchase AS cp
JOIN customer AS c
    ON c.customer_id = cp.customer_id
JOIN product AS p
    ON p.product_id = cp.product_id
WHERE MONTHNAME(cp.transaction_date) LIKE 'May'
ORDER BY Overall_Sales DESC;

-- 4. What are the top 10 products in terms of total sales (i.e. the products that generated the most revenue)?

SELECT DISTINCT p.product_name, SUM(p.unit_price*cp.quantity) OVER (PARTITION BY cp.product_id) AS 'Total_Revenue'
FROM product AS p
JOIN customer_purchase AS cp
    ON p.product_id = cp.product_id
ORDER BY Total_Revenue DESC
LIMIT 10;

-- 5. Who are our top 10 customers that have bought the most number of products overall?

WITH 
    Customersales (Name, Sales) AS 
    (
    SELECT DISTINCT c.customer_id, SUM(cp.quantity) OVER (PARTITION BY c.customer_id)
    FROM customer_purchase AS cp
    JOIN customer AS c
        ON c.customer_id = cp.customer_id
    )
SELECT CONCAT(c.first_name,' ',c.last_name) AS 'Customer Name', cs.Sales AS 'Total Sales per Customer'
FROM Customersales AS cs
JOIN customer AS c
    ON c.customer_id = cs.Name
ORDER BY cs.Sales DESC
LIMIT 10;

-- 6. Who are our top 10 customers in terms of their overall spending? What is the product that they have respectively spent the most on, and how much have they spent on this product?

WITH 
    CustomerREV (customer, custname, Totalrev) AS 
        (
        SELECT DISTINCT c.customer_id, CONCAT(c.first_name,' ',c.last_name) AS 'Customer Name', SUM(cp.quantity*p.unit_price) OVER (PARTITION BY c.customer_id) AS 'Total_Revenue'
        FROM customer_purchase AS cp
        JOIN product AS p
            ON p.product_id = cp.product_id
        JOIN customer AS c
            ON c.customer_id = cp.customer_id
        ORDER BY Total_Revenue DESC
        LIMIT 10
        ),
    Productrev (customer, product, prodname ,Revperproduct) AS 
        (
        SELECT c.customer_id, p.product_id, p.product_name,SUM(cp.quantity*p.unit_price) OVER (PARTITION BY c.customer_id, p.product_id)
        FROM customer_purchase AS cp
        JOIN product AS p
            ON p.product_id = cp.product_id
        JOIN customer AS c
            ON c.customer_id = cp.customer_id
        ),
    TopProduct (customer, product ,Totalrev, Topprodrev) AS
        (
        SELECT crv.customer,pr.product , crv.Totalrev, MAX(pr.Revperproduct) OVER (PARTITION BY crv.customer) 
        FROM CustomerREV AS crv
        INNER JOIN Productrev AS pr
            ON crv.customer = pr.customer
        ORDER BY crv.Totalrev, pr.Revperproduct DESC
        )
SELECT DISTINCT crv.custname AS 'Customer Name', crv.Totalrev AS 'Total Revenue', pr.prodname AS 'Top Product Name', tp.Topprodrev AS 'Total Revenue of Product for customer x'
FROM CustomerREV AS crv
JOIN TopProduct AS tp
    ON tp.customer = crv.customer
JOIN Productrev AS pr
    ON pr.customer = crv.customer
WHERE pr.Revperproduct = tp.Topprodrev
ORDER BY crv.Totalrev DESC;

-- 7. For every city, what are our top 10 products in terms of overall sales?


WITH
    Initial (product, city, prodname, prodpercity) AS
    (
    SELECT DISTINCT p.product_id, c.city, p.product_name, SUM(p.unit_price*cp.quantity) OVER (PARTITION BY c.city, cp.product_id)
    FROM customer_purchase AS cp 
    JOIN product AS p
        ON p.product_id = cp.product_id
    JOIN customer AS c
        ON c.customer_id = cp.customer_id
    ),
    Toprank (product, city, prodname, prodpercity, ranking) AS
    (
    SELECT product, city, prodname, prodpercity, ROW_NUMBER() OVER (PARTITION BY city ORDER BY prodpercity DESC)
    FROM Initial
    )
SELECT city, prodname AS 'Product Name', prodpercity AS 'SUM for city x'
FROM Toprank
WHERE ranking < 11
ORDER BY city, ranking;


-- 8. In terms of the total quantity of products purchased per month, what is our month-over-month growth from April 2025 to May 2025?

WITH
    May (year, month, sum) AS 
    (
    SELECT DISTINCT YEAR(transaction_date) ,MONTHNAME(transaction_date), SUM(quantity) OVER (PARTITION BY MONTH(transaction_date))
    FROM customer_purchase
    WHERE MONTHNAME(transaction_date) LIKE 'May' 
    ),
    April (year, month, sum) AS 
    (
    SELECT DISTINCT YEAR(transaction_date), MONTHNAME(transaction_date), SUM(quantity) OVER (PARTITION BY MONTH(transaction_date))
    FROM customer_purchase
    WHERE MONTHNAME(transaction_date) LIKE 'April'
    )
SELECT (((m.sum - a.sum)/a.sum)*100) AS "month-over-month growth" FROM May AS m
JOIN April AS a
    ON a.year = m.year;


