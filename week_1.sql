/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

/* --------------------
   SOLUTIONS
   --------------------*/

-- QUERY 1 What is the total amount each customer spent at the restaurant?

SELECT * FROM members m ;

select * from sales s;

select * from menu m ;


select m.customer_id,  sum(m2.price) as total_spent from members m
left join sales s on m.customer_id = s.customer_id 
left join menu m2 on s.product_id = m2.product_id 
group by m.customer_id; 

-- QUERY 2. How many days has each customer visited the restaurant?

select s2.customer_id, count(order_date) as visit_days
from
	(select distinct s.customer_id , s.order_date from sales s) as s2
group by s2.customer_id;


-- QUERY 3 What was the first item from the menu purchased by each customer?

select s.customer_id, m.product_name from  sales s 
 join (select s.customer_id, min(s.order_date) as min_date from sales s
		group by s.customer_id) as s2
		 on s.order_date = s2.min_date and (s.customer_id = s2.customer_id)
 left join menu m on m.product_id = s.product_id 
group by s.customer_id, m.product_name
order by s.customer_id asc;

-- QUERY 4 What is the most purchased item on the menu and how many times was it purchased by all customers?   
WITH total_sales AS (
    SELECT 
        m.product_id, 
        m.product_name, 
        COUNT(m.product_name) AS total
    FROM 
        menu m
    JOIN 
        sales s ON s.product_id = m.product_id
    GROUP BY 
        m.product_id, 
        m.product_name
    ORDER BY 
        total DESC
    LIMIT 1
)
SELECT 
    s.customer_id, 
    ts.product_name, 
    COUNT(s.customer_id) AS total_purchases
FROM 
    sales s
JOIN 
    total_sales ts ON ts.product_id = s.product_id
GROUP BY 
    s.customer_id, 
    ts.product_name;

   
   
-- QUERY 5 Which item was the most popular for each customer?
WITH total_purchases AS (
    SELECT 
        s.customer_id, 
        s.product_id, 
        COUNT(s.product_id) AS total
    FROM 
        sales s
    GROUP BY 
        s.product_id, 
        s.customer_id
)
SELECT 
    ts.customer_id, 
    ts.total, 
    ts.product_id, 
    m.product_name
FROM 
    total_purchases ts
JOIN (
    SELECT 
        customer_id, 
        MAX(total) AS total
    FROM 
        total_purchases
    GROUP BY 
        customer_id
) AS max_purchases 
    ON max_purchases.total = ts.total 
    AND max_purchases.customer_id = ts.customer_id
LEFT JOIN 
    menu m 
    ON m.product_id = ts.product_id;

-- Query 6
-- First I ranked the sales by the order date, with a partition over the customer id, and after that
-- I took the ones with rank = 1.
WITH ranked_sales AS (
    SELECT
        m.customer_id,
        s.product_id,
        RANK() OVER (
            PARTITION BY m.customer_id
            ORDER BY s.order_date
        ) AS sales_rank
    FROM
        members m
    JOIN
        sales s
            ON m.customer_id = s.customer_id
    WHERE
        m.join_date <= s.order_date
)
SELECT
    rs.customer_id,
    m.product_name
FROM
    ranked_sales rs
JOIN
    menu m
        ON m.product_id = rs.product_id
WHERE
    rs.sales_rank = 1;


-- Query 7 Which item was purchased just before the customer became a member?
-- The solution is almost the same as the previous one, only changes the rank order.\
-- And the operator that compairs the join_date with the order_date
WITH ranked_sales AS (
    SELECT
        m.customer_id,
        s.product_id,
        s.order_date,
        RANK() OVER (
            PARTITION BY m.customer_id
            ORDER BY s.order_date desc 
        ) AS sales_rank
    FROM
        members m
    JOIN
        sales s
            ON m.customer_id = s.customer_id
    WHERE
        m.join_date > s.order_date
)
SELECT
    rs.customer_id,
    rs.order_date,
    m.product_name
FROM
    ranked_sales rs
JOIN
    menu m
        ON m.product_id = rs.product_id
WHERE
    rs.sales_rank = 1;


-- Query 8   What is the total items and amount spent for each member before they became a member?
-- Solution here is based in two joins and comparing the order date with join date
SELECT
    s.customer_id,
    COUNT(s.product_id),
    SUM(m.price) AS am_spent
FROM
    sales s
JOIN
    menu m
        ON m.product_id = s.product_id
JOIN
    members mem
        ON mem.customer_id = s.customer_id
WHERE
    s.order_date < mem.join_date
GROUP BY
    s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- I used a case, for filtering if it is sushi or not. And I sum up all those results.
SELECT
    s.customer_id,
    SUM(CASE 
        WHEN m.product_name = 'sushi' THEN 20*m.price
        ELSE 10*m.price
    END) AS total_points
FROM
    sales s
JOIN
    menu m
        ON s.product_id = m.product_id
group by s.customer_id;


-- 10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
-- Same logic as the last one, just added another condition on the CASE for the join date and finally a where clause 
-- to verify that the month is january

SELECT
    s.customer_id,
    SUM(
        CASE 
            WHEN s.order_date BETWEEN mem.join_date AND (mem.join_date + 7) THEN 20 * m.price
            WHEN m.product_name = 'sushi' THEN 20 * m.price
            ELSE 10 * m.price
        END
    ) AS total_points
FROM
    sales s
JOIN
    menu m
        ON s.product_id = m.product_id
JOIN
    members mem
        ON mem.customer_id = s.customer_id
WHERE
    EXTRACT(MONTH FROM s.order_date) = 1
GROUP BY
    s.customer_id;



