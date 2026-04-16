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


SOURCE customer.sql;
SOURCE product.sql;
SOURCE customer_purchase.sql;


DESCRIBE customer;
DESCRIBE product;
DESCRIBE customer_purchase;

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

SELECT DISTINCT c.city ,SUM(cp.quantity) OVER (PARTITION BY c.city) AS 'Overall Sales'
FROM customer_purchase AS cp
JOIN customer AS c
    ON c.customer_id = cp.customer_id
WHERE MONTHNAME(cp.transaction_date) LIKE 'May';

-- 4. What are the top 10 products in terms of total sales (i.e. the products that generated the most revenue)?

WITH 
    Revenue (Name, TotalRevenue) AS 
    (
    SELECT DISTINCT p.product_name, SUM(p.unit_price*cp.quantity) OVER (PARTITION BY cp.product_id)
    FROM product AS p
    JOIN customer_purchase AS cp
        ON p.product_id = cp.product_id
    )
SELECT Name'Product Name', TotalRevenue 
FROM Revenue
ORDER BY TotalRevenue DESC
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
SELECT CONCAT(c.first_name,' ',c.last_name) AS 'Customer Name', cs.Sales
FROM Customersales AS cs
JOIN customer AS c
    ON c.customer_id = cs.Name
ORDER BY cs.Sales DESC
LIMIT 10;

-- 6. Who are our top 10 customers in terms of their overall spending? What is the product that they have respectively spent the most on, and how much have they spent on this product?

WITH 
    CustomerREV (customer, custname, Totalcustomerrev) AS 
        (
        SELECT DISTINCT c.customer_id, CONCAT(c.first_name,' ',c.last_name) AS 'Customer Name', SUM(cp.quantity*p.unit_price) OVER (PARTITION BY c.customer_id) 
        FROM customer_purchase AS cp
        JOIN product AS p
            ON p.product_id = cp.product_id
        JOIN customer AS c
            ON c.customer_id = cp.customer_id
        ),
    Topspend (cust, Totalrev) AS
        (
        SELECT customer, Totalcustomerrev
        FROM CustomerREV
        ORDER BY Totalcustomerrev DESC
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
            SELECT ts.cust,pr.product , ts.Totalrev, MAX(pr.Revperproduct) OVER (PARTITION BY ts.cust) FROM Topspend AS ts
        JOIN CustomerREV AS crv
            ON crv.customer = ts.cust
        INNER JOIN Productrev AS pr
            ON ts.cust = pr.customer
        ORDER BY ts.Totalrev, pr.Revperproduct DESC
        )
SELECT DISTINCT crv.custname AS 'Customer Name', ts.Totalrev AS 'Total Revenue', pr.prodname AS 'Product Name', tp.Topprodrev AS 'Total Revenue of Product for customer x'
FROM Topspend AS ts
JOIN TopProduct AS tp
    ON tp.customer = ts.cust
JOIN CustomerREV AS crv
    ON crv.customer = ts.cust
JOIN Productrev AS pr
    ON pr.customer = ts.cust
WHERE pr.Revperproduct = tp.Topprodrev
ORDER BY ts.Totalrev DESC;

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


