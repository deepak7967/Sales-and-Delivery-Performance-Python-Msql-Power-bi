# Sales & Delivery Performance Analysis | Python · MySQL · Power BI

An end-to-end data analytics project analyzing 180,519 supply chain records across global markets to uncover sales trends, delivery inefficiencies, and profitability drivers — helping businesses optimize logistics and maximize revenue.

##  Business Problem

In a competitive global supply chain, companies struggle with two critical challenges: maximizing sales revenue while minimizing delivery delays. Without clear visibility into which product categories drive profit, which shipping modes cause delays, and how discounts impact margins, operations remain inefficient and customer satisfaction suffers.

### This project answers:
- Which cities and product categories generate the highest revenue and profit?
- Which shipping modes carry the highest late delivery risk?
- How does discounting strategy affect overall profitability?
- What are the monthly sales and profit trends across markets?
- Which products rank highest within their category by revenue?

### Selected Columns for Analysis

Column Description
- type : Type of transaction 
- days_for_shipping_real : Actual days taken to ship 
- days_for_shipment_scheduled : Scheduled shipping days 
- late_delivery_risk : 1 if late delivery risk, 0 if not 
- category_name : Product category 
- order_city : City where order was placed 
- order_date_dateorders : Order date 
- order_id : Unique order identifier 
- order_item_discount : Discount applied to order item 
- order_item_quantity :  Quantity ordered 
- sales : Total sales amount 
- order_profit_per_order: Profit per order 
- product_name : Name of product 
- shipping_mode : Shipping method used 
- shipping_date_dateorders : Actual shipping date 

##  Tool Used 
- Python (Pandas, NumPy) : Data loading, cleaning & transformation 
- SQLAlchemy + PyMySQL : Connecting Python to MySQL database 
- MySQL : Structured querying and business logic 
- Power BI Desktop : Interactive dashboard & visualization


##  Data Cleaning Steps (Python)

```python
import pandas as pd
import numpy as np

# Load dataset
df = pd.read_csv('DataCoSupplyChainDataset.csv', encoding='latin1')

# Inspect data
print(df.shape)
print(df.duplicated().sum())
print(df.isnull().sum().sort_values(ascending=False))

# Select relevant columns
data_supply = df[['Type', 'Days for shipping (real)', 'Days for shipment (scheduled)',
                   'Late_delivery_risk', 'Category Name', 'Order City',
                   'order date (DateOrders)', 'Order Id', 'Order Item Discount',
                   'Order Item Product Price', 'Order Item Quantity', 'Sales',
                   'Order Item Total', 'Order Profit Per Order', 'Product Name',
                   'Product Price', 'shipping date (DateOrders)', 'Shipping Mode']]

# Standardize column names
data_supply.columns = (data_supply.columns
    .str.lower()
    .str.replace(r"[^\w\s]", "", regex=True)
    .str.replace(" ", "_"))

# Convert date columns
data_supply['order_date_dateorders'] = pd.to_datetime(data_supply['order_date_dateorders'])
data_supply['shipping_date_dateorders'] = pd.to_datetime(data_supply['shipping_date_dateorders'])
```

---

##  MySQL — Upload via SQLAlchemy

```python
from sqlalchemy import create_engine

engine = create_engine("mysql+pymysql://username:password@localhost:3306/supply_chain_db")
data_supply.to_sql("data_supply", con=engine, if_exists="replace", index=False)
print("Data uploaded successfully")
```

---

##  SQL Queries

### Monthly Revenue & Profit Trend
```sql
SELECT DATE_FORMAT(order_date_dateorders, '%y-%m') AS month,
       ROUND(SUM(sales), 2) AS total_sales,
       ROUND(SUM(order_profit_per_order), 2) AS total_profit
FROM data_supply
GROUP BY month ORDER BY month;
```

### Top 10 Cities by Revenue
```sql
SELECT order_city,
       COUNT(DISTINCT order_id) AS total_orders,
       ROUND(SUM(sales), 2) AS total_revenue
FROM data_supply
GROUP BY order_city
ORDER BY total_revenue DESC LIMIT 10;
```

### Shipping Mode with Highest Late Delivery Rate
```sql
SELECT shipping_mode,
       COUNT(*) AS total_orders,
       SUM(late_delivery_risk) AS late_orders,
       ROUND(SUM(late_delivery_risk) / COUNT(*) * 100, 2) AS late_delivery_rate_pct
FROM data_supply
GROUP BY shipping_mode
ORDER BY late_delivery_rate_pct DESC;
```

### Average Actual vs Scheduled Shipping Days
```sql
SELECT shipping_mode,
       AVG(days_for_shipment_scheduled) AS scheduled_avg_ship_days,
       AVG(days_for_shipping_real) AS avg_ship_days
FROM data_supply
GROUP BY shipping_mode;
```

### Impact of Discount on Profit
```sql
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
FROM data_supply
GROUP BY discount_bucket
ORDER BY avg_profit DESC;
```

### Top Product per Category 
```sql
WITH category_table AS (
    SELECT category_name, product_name,
           ROUND(SUM(sales), 2) AS revenue,
           DENSE_RANK() OVER (PARTITION BY category_name ORDER BY SUM(sales) DESC) AS category_rank
    FROM data_supply
    GROUP BY category_name, product_name
)
SELECT * FROM category_table WHERE category_rank = 1;
```

### Average Profit per Category with Ranking
```sql
SELECT category_name,
       ROUND(SUM(order_profit_per_order)) AS total_profit,
       ROUND(AVG(order_profit_per_order), 2) AS avg_profit,
       RANK() OVER (ORDER BY AVG(order_profit_per_order)) AS avg_profit_rank
FROM data_supply
GROUP BY category_name;
```

---

## 📊 Dashboard

### Sales & Delivery Performance Dashboard

![Sales and Delivery Performance Dashboard](Screenshot_2026-05-15_153528.png)

**KPI Cards:**
| Metric | Value |
|---|---|
| Total Sales | $12.30M |
| Avg Delay Days | 1.62 |
| Total Orders | 63K |
| Total Profit | $1.31M |
| Late Delivery Risk | 55.1% |

**Key Visuals:**
- **Sales Over Time** — Monthly sales trend filtered by year (2015–2018) showing seasonal fluctuations
- **Total Orders by Shipping Mode & Late Delivery Risk** — Stacked bar showing YES/NO late delivery split per shipping mode
- **Average Sales by Category** — Horizontal bar comparing avg sales across product categories
- **City-wise Revenue & Profit Table** — Top cities ranked by sum of sales, total profit, and profit margin %
- **Categories with Highest Late Delivery Risk** — Bar chart highlighting which product categories face the most delivery challenges

##  Key Business Insights

1. **First Class shipping has the highest late delivery risk** — Despite being a premium option, First Class shipping carries the highest late delivery rate among all shipping modes, indicating a critical gap between customer expectations and actual fulfillment performance.

2. **New York City leads in revenue and profit** — It consistently ranks as the top city by total sales, making it the most strategically important market for inventory planning and resource allocation.

3. **Fishing and Camping categories dominate average sales** — These outdoor and sporting categories generate the highest average sales per order, making them the most valuable product segments for revenue optimization.

4. **High discounts erode profitability** — Orders with higher discount levels show significantly lower average profit per order, indicating that aggressive discounting strategy is hurting overall margins and needs to be reassessed.

5. **Over half of all orders carry late delivery risk** — With a 55.1% late delivery risk rate across all orders, supply chain operations require urgent process improvements in logistics planning and carrier performance monitoring.

6. **Standard Class is the most reliable shipping mode** — It shows the most balanced ratio of on-time vs late deliveries, making it the preferred mode for cost-effective and dependable fulfillment.

7. **Profit margins remain thin across top cities** — Despite high revenue figures, profit margins hover around 10–13% across top cities, suggesting room for cost optimization in operations and fulfillment.

## Author
Deepak kumar

