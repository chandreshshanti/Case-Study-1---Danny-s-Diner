/* 

CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
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
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
*/

-- Case Study Questions

-- What is the total amount each customer spent at the restaurant?


select customer_id,
sum(price)as total_amount
from sales s
join menu m
using(product_id)
group by customer_id;

-- How many days has each customer visited the restaurant?


select 
customer_id,
count(distinct order_date)
from sales
group by customer_id;

-- What was the first item from the menu purchased by each customer?

with cte as
(
select distinct product_name,
customer_id,
order_date,
dense_rank() over(partition by customer_id order by order_date) as first_item
from sales s
join menu m
using(product_id)
)
select customer_id,
product_name,
first_item
from cte 
where first_item =1 ;

-- What is the most purchased item on the menu and how many times was it purchased by all customers?


select 
product_name,
count(product_name) as top_item
from sales s
join menu m
using(product_id)
group by product_name
order by top_item desc
limit 1 ;

-- Which item was the most popular for each customer?


with cte as
(
select
customer_id, 
product_name,
count(product_name) as most_item,
dense_rank() over(partition by customer_id order by count(product_name) desc  ) as top_item
from sales s
join menu m
using(product_id)
group by product_name,customer_id
)
select customer_id,product_name,most_item
from cte
where top_item = 1;

-- Which item was purchased first by the customer after they became a member?


with cte as 
(
select *,
dense_rank() over(partition by customer_id order by order_date) as first_order
from sales s
join menu m
using(product_id)
join members mm
using(customer_id)
where order_date >join_date
)
select customer_id,
product_name
from cte
where first_order = 1 ;

-- Which item was purchased just before the customer became a member?


with cte as
(
select product_name,
customer_id,
order_date,
join_date,
row_number() over(partition by customer_id order by order_date desc) as first_order
from sales s
join menu m
using(product_id)
join members mm
using(customer_id)
where order_date < join_date
)
select customer_id,
product_name
from cte
where first_order =1;

-- What is the total items and amount spent for each member before they became a member?

select 
customer_id,
count(product_name) as total_items,
sum(price) as sales
from sales s
join menu m
using(product_id)
join members mm
using(customer_id)
where order_date < join_date
group by customer_id;

-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?


with cte as 
(
select customer_id,
product_name,
price,
case when 
product_name = 'sushi' then price*20
else price*10
end as points
from sales s
join menu m
using(product_id)
)

select customer_id,
sum(points)
from cte
group by customer_id;

-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?
with cte as 
(
select *,
join_date + 6 as p
from sales s
join menu m
using(product_id) 
join members mm
using(customer_id)
),
ct as
 (
select customer_id,
product_name,
price,
join_date,
order_date,
p,
case when
order_date <= p and order_date >= join_date then price*20
when product_name='sushi' then price*20
else price*10 
end as g 
from cte
where order_date < ' 2021-02-01' and order_date >=join_date
)
select customer_id,
 sum(g)
from ct
group by customer_id;