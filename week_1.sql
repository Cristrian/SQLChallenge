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

WITH purchase_counts AS (
  SELECT 
    s.customer_id,
    m.product_name,
    COUNT(*) AS order_count,
    RANK() OVER (
      PARTITION BY s.customer_id
      ORDER BY COUNT(*) DESC
    ) AS popularity_rank
  FROM sales s
  JOIN menu m ON s.product_id = m.product_id
  GROUP BY s.customer_id, m.product_name
)
SELECT 
  customer_id,
  product_name,
  order_count,
  popularity_rank
FROM purchase_counts;
