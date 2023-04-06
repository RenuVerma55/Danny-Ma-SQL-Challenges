CREATE DATABASE dannys_diner;
SET search_path = dannys_diner;
USE dannys_diner;
CREATE TABLE sales (
  `customer_id` VARCHAR(1),
  `order_date` DATE,
  `product_id` INTEGER
);
INSERT INTO sales
VALUES ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
CREATE TABLE menu (
  `product_id` INTEGER,
  `product_name` VARCHAR(5),
  `price` INTEGER
);

INSERT INTO menu
  (`product_id`, `product_name`, `price`)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
  CREATE TABLE members (
  `customer_id` VARCHAR(1),
  `join_date` DATE
);

INSERT INTO members
  (`customer_id`, `join_date`)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT sales.customer_id, SUM(menu.price) AS Total_Amount
FROM sales
JOIN menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;
-- Customer A and B are the potential customer as the amount spent by then are higher as compared to customer C

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS Number_of_days
FROM sales
GROUP BY customer_id;
-- Customer B has visited the restaurant more frequently and customer C has the lowest frequency to visit the restaurant.

-- 3. What was the first item from the menu purchased by each customer?
WITH CTE  AS
	(SELECT sales.customer_id,menu.product_name, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) AS rn
	FROM sales
	JOIN MENU
	ON sales.product_id = menu.product_id )
select * FROM CTE
WHERE rn =1;
-- Customer A tries Sushi as the first item while curry was tried by customer B. Customer C tries ramen for the first time.

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT sales.product_id,count(sales.product_id) as most_purchased
FROM sales
GROUP BY sales.product_id;
--  Ramen is the top dish preferred by the customers and it has sold 8 times. The restaurant should focus on the quality and taste of the other two dishes in order to increase its sales.

-- 5. Which item was the most popular for each customer?

WITH purchases AS
(SELECT sales.customer_id, menu.product_name, COUNT(sales.product_id) AS number_of_purchases, DENSE_RANK() OVER(PARTITION BY sales.customer_id ORDER BY COUNT(sales.product_id) DESC) AS rnk
FROM menu
INNER JOIN sales
ON menu.product_id = sales.product_id
GROUP BY sales.customer_id, menu.product_name)

SELECT customer_id, product_name, MAX(number_of_purchases) AS maximum_purchases
FROM purchases
WHERE rnk=1
GROUP BY customer_id, product_name;
-- Ramen is the most famous dish among all the customers. The customer B likes all the dishes equally.

-- 6.Which item was purchased first by the customer after they became a member?
WITH first_order AS
(
SELECT sales.customer_id,sales.order_date, members.join_date, menu.product_name,
	DENSE_RANK() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date ASC ) AS rnk
FROM sales
JOIN members ON sales.customer_id =members.customer_id
JOIN menu ON sales.product_id = menu.product_id
WHERE order_date >= join_date)
SELECT * FROM first_order WHERE rnk=1;
-- Only customers A and B join as members at the restaurant and they took Curry and Sushi respectively after joining.

-- 7. Which item was purchased just before the customer became a member?
With CTE AS (
SELECT sales.customer_id, sales.order_date, menu.product_name, members.join_date,
dense_rank() over(partition by sales.customer_id order by sales.order_date DESC) as rnk
FROM sales
JOIN members ON sales.customer_id= members.customer_id
JOIN menu ON sales.product_id = menu.product_id
WHERE sales.order_date < members.join_date)
select customer_id, order_date, product_name, join_date
from CTE
where rnk = 1;
-- Just before joining the restaurant, the customer A ordered Sushi and Curry while the customer B ordered Sushi.

 -- 8. What is the total items and amount spent for each member before they became a member?
with cte as 
(
SELECT sales.customer_id,sales.order_date, members.join_date, menu.product_name,menu.price
FROM sales
JOIN members ON sales.customer_id =members.customer_id
JOIN menu ON sales.product_id = menu.product_id
WHERE order_date < join_date)
select customer_id,count(*)AS total_item,sum(price) AS amount_spend
from cte
group by customer_id;
-- Before joining, the customers A and B ordered Curry and Sushi and the total amount spent by them is 25 and 40 respectively.

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier. how many points would each customer have?
 
WITH CTE AS( 
 SELECT sales.customer_id,sales.product_id,menu.product_name,menu.price,
 CASE WHEN menu.product_name = 'sushi' THEN  20*menu.price 
 ELSE 10*menu.price END AS points
  FROM sales
 JOIN menu on sales.product_id = menu.product_id)
 SELECT customer_id, sum(points) AS Points
 from cte
 group by customer_id;
  -- The customer B has earned maximum points, followed by customer A. The customer C has earned the least points.
 
 -- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
  with cte as (SELECT sales.customer_id,sales.product_id,menu.product_name,menu.price,
 CASE WHEN sales.order_date <= DATE_add(members.join_date, interval 6 day) and join_date <= order_date THEN  20*menu.price 
 ELSE 10*menu.price END AS points
 FROM sales
 JOIN menu on sales.product_id = menu.product_id
 JOIN members on sales.customer_id = members.customer_id
 where month(order_date)=1)
 select customer_id, sum(points)
 from cte
 group by customer_id;
  -- Based on the above condition, the total points earned by customer A is the highest, followed by the customer B.
 
 -- BONUS QUESTIONS
-- JOIN ALL THE THINGS
SELECT sales.customer_id,sales.order_date,menu.product_name,menu.price,
 (CASE WHEN sales.order_date < members.join_date OR members.join_date IS NULL THEN 'N' ELSE 'Y' END) AS member
FROM sales
JOIN menu ON sales.product_id = menu.product_id
JOIN members ON sales.customer_id= members.customer_id;

-- RANK ALL THE THINGS

WITH cte AS (SELECT sales.customer_id,sales.order_date,menu.product_name,menu.price,
 (CASE WHEN sales.order_date < members.join_date OR members.join_date IS NULL THEN 'N' ELSE 'Y' END) AS member
FROM sales
JOIN menu ON sales.product_id = menu.product_id
JOIN members ON sales.customer_id= members.customer_id)
SELECT *, 
CASE WHEN member = 'Y' then dense_rank() OVER(partition by customer_id, member order by order_date ASC) ELSE null end as ranking
FROM CTE
 