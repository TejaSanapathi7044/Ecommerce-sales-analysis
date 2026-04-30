select * from orders;


-- Top 15 customers by total revenue.
select customer_id,sum(total_order_value) as total_revenue
from orders
group by customer_id
order by total_revenue desc
limit 15;


-- Customers whose total spending is above average customer spending.
with customer_spending as (select
                               customer_id,sum(total_order_value) as total_spending
                           from orders
                           group by customer_id)
select * from customer_spending
where total_spending > (select avg(total_spending)
                        from customer_spending )
order by total_spending desc;


-- Monthly revenue trend .
WITH monthly_data AS (
    SELECT
        monthname(order_purchase_timestamp) AS month,
        SUM(total_order_value) AS monthly_revenue
    FROM orders
    GROUP BY month
)
SELECT
    month,
    monthly_revenue,
    dense_rank() over (order by monthly_revenue desc ) as denserank
FROM monthly_data;


-- Identify repeat vs one-time customers and compare their average order value
with customer_orders as (
    select customer_id,
           count(distinct order_id) as total_orders,
           avg(total_order_value) as  average_order_value
    from orders
    group by customer_id
),

    customer_type as (
        select customer_id,
               average_order_value,
               case
                  when total_orders = 1 then 'one-time'
                  else 'respect'
        end as customer_category
        from customer_orders
    )
    select
           customer_category,
           avg(average_order_value) as average_order_value
    from customer_type
group by customer_category;

SELECT
    customer_id,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
GROUP BY customer_id
HAVING COUNT(DISTINCT order_id) > 1;


--  What is the average delivery time per state.
select
    customer_state ,
    avg(delivery_time) as avg_delivery_time
from orders
group by customer_state
order by avg_delivery_time desc ;


-- Top 3 states most orders delay .
select customer_state,
       sum(is_delayed) as delayed_count
from orders
group by customer_state
order by delayed_count desc
limit 3;


-- Rank states based on average delay time.
with state_delay as (
    select customer_state,
           avg(delivery_delay) as avg_delay
    from orders
    where delivery_delay < 0
    group by customer_state
)
select customer_state,
       avg_delay ,
       dense_rank() over (order by avg_delay) as delay_rank
from state_delay;


-- Calculate total revenue generated from delayed orders vs non-delayed orders.
with revenue_data as (
    select
        case
            when is_delayed = 1 then 'delayed'
    else 'on-time'
    end as delivered_status,
        sum(total_order_value) as total_value
    from orders
       GROUP BY
        CASE
            WHEN is_delayed = 1 THEN 'delayed'
            ELSE 'on-time'
        END
)
select delivered_status,
       total_value ,
        (total_value * 100.0 / SUM(total_value) OVER()) AS percentage
from revenue_data;


-- Do delayed orders have lower review scores.
select
    case
        when is_delayed = 1 then 'Delayed'
        else 'on-time'
end as delivery_status,
    avg(review_score) as avg_review
from orders
where review_score is not null
group by delivery_status;


-- How does review score change when delivery_time exceeds a threshold.
select
    case
        when delivery_time <= 7 then 'fast(<=7)'
        else 'slow(>=7)'
end as delivery_speed,
    avg(review_score) as avg_review
from orders
group by delivery_speed;


-- Top 10 product categories by revenue.
select
    product_category_name,
    sum(total_order_value) as total_revenue
from orders
group by product_category_name
order by total_revenue desc
limit 10;


-- Which product categories have the highest average delay.
select
    product_category_name,
    avg(delivery_delay) as avg_delay
from orders
group by product_category_name
order by avg_delay
limit 3;


-- Top 3 customers in each state by revenue.
with customer_revenue as (select customer_id,
                                 customer_state,
                                 sum(total_order_value) as total_revenue
                          from orders
                          group by customer_id,customer_state
)
select *
    from( select
    customer_id,
    customer_state,
    total_revenue,
    dense_rank() over (partition by customer_state
        order by  total_revenue desc) as denserank
from customer_revenue
  ) t
where denserank  <= 3;


-- Find customers whose order value is higher than their own average order value.
select *
from (
    select
        customer_id,
        order_id,
        total_order_value,
        avg(total_order_value) over (partition by customer_id) as customer_avg
    from orders
) t
where total_order_value > customer_avg;


--  For each month, find percentage of delayed orders.
with monthly_data as (select
                          monthname(order_purchase_timestamp)as month,
                             count(*) as total_orders,
                             sum(case when is_delayed = 1 then 1 else 0 end) as delayed_orders
                      from orders
                      group by month
)
select
    month,
    total_orders,
    delayed_orders,
    (delayed_orders *100.0 / total_orders) as delayed_orders,
    dense_rank() over (order by delayed_orders desc) as dense_rankk
from monthly_data
group by month ;


-- High risk orders.
select
    customer_id,
    order_id,
    total_order_value,
    (case when is_delayed = 1 then 'delayed' else 0 end ) as delayed_orders,
    review_score
from orders
where total_order_value > (
    select
        avg(total_order_value)
    from orders
    )
and is_delayed = 1
and review_score <= 2;



























































































