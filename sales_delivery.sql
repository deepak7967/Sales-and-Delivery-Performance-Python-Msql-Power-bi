CREATE database supply_chain_db ;

use supply_chain_db ;
select * from data_supply ;

desc data_supply;

-- Monthly Revenue & Profit Trend
select date_format(order_date_dateorders,'%y-%m') as month,
round(sum(sales),2)as total_sales, 
round(SUM(order_profit_per_order),2) AS total_profit
from data_supply
group by month order by month ;

-- Which are the Top 10 cities that generated the highest revenue?
select * from data_supply ;
select order_city , 
COUNT(DISTINCT order_id)   AS total_orders,
round(sum(sales),2) as total_revenue from data_supply 
group by order_city order by total_revenue desc limit 10 ;


-- Which product category has the highest sales and profit?
select category_name , sum(sales) as total_sales 
from data_supply 
group by category_name 
order by total_sales desc limit 1 ;

-- Which shipping mode has the highest late delivery rate? (late_delivery_risk)
SELECT 
    shipping_mode,
    COUNT(*) AS total_orders,
    SUM(late_delivery_risk) AS late_orders,
    ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS late_delivery_rate_pct
FROM data_supply
GROUP BY shipping_mode
ORDER BY late_delivery_rate_pct DESC;

-- Average Actual vs Scheduled Shipping Days per Shipping Mode (Most Delayed?)
select * from data_supply ; 
select shipping_mode , avg(days_for_shipment_scheduled) as scheuled_avg_ship_days, avg(days_for_shipping_real) as avg_ship_days
from data_supply group by shipping_mode ;

--  How does discount level affect profit? (Group discounts into buckets — No discount / Low / Medium / High)
SELECT 
    CASE
        WHEN order_item_discount = 0 THEN 'No Discount'
        WHEN order_item_discount <= 100 THEN 'Low'
        WHEN order_item_discount <= 300 THEN 'Medium'
        ELSE 'High'
    END AS discount_bucket,
    COUNT(*) AS total_orders,
    ROUND(AVG(order_profit_per_order), 2) AS avg_profit,
    ROUND(SUM(sales), 2) AS total_revenue
FROM
    data_supply
GROUP BY discount_bucket
ORDER BY avg_profit DESC;

-- Rank products by revenue within each category — who is the #1 product per category? (Use RANK + PARTITION BY)
select * from data_supply ;
with category_table as (select category_name , product_name , 
round(sum(sales),2) as revenue , dense_rank() 
over(partition by category_name order by sum(sales) desc) as category_rank
from data_supply 
group by category_name , product_name )
select * from category_table where category_rank = 1 ;

-- What is the average profit per order for each product category — and which category is least profitable?
select * from data_supply ;
select category_name , 
round(sum(order_profit_per_order)) as total_profit,
round(avg(order_profit_per_order),2) as avg_profit,
rank() over(order by avg(order_profit_per_order)) as avg_profit_rank 
from data_supply 
group by category_name ;
