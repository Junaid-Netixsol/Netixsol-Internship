-- Task 1


-- View 1, gonna get product names, category names, territory names, revenue, cost, and profit in one view

CREATE SCHEMA IF NOT EXISTS analytics;

CREATE OR REPLACE VIEW analytics.sales_order_lines AS
SELECT soh.salesorderid, sod.salesorderdetailid, soh.orderdate, DATE_TRUNC('month', soh.orderdate)::date AS order_month, DATE_TRUNC('quarter', soh.orderdate)::date AS order_quarter, EXTRACT(YEAR FROM soh.orderdate)::int AS order_year, soh.customerid, soh.salespersonid, soh.territoryid, st.name AS territory_name, st."group" AS territory_group, sod.productid, p.name AS product_name, ps.name AS subcategory_name, pc.name AS category_name, sod.orderqty, sod.unitprice, sod.unitpricediscount, p.standardcost, sod.orderqty * sod.unitprice * (1 - sod.unitpricediscount) AS line_revenue, sod.orderqty * p.standardcost AS line_cost, (sod.orderqty * sod.unitprice * (1 - sod.unitpricediscount)) - (sod.orderqty * p.standardcost) AS line_profit
FROM sales.salesorderheader AS soh
JOIN sales.salesorderdetail AS sod ON soh.salesorderid = sod.salesorderid
JOIN production.product AS p ON sod.productid = p.productid
LEFT JOIN production.productsubcategory AS ps ON p.productsubcategoryid = ps.productsubcategoryid
LEFT JOIN production.productcategory AS pc ON ps.productcategoryid = pc.productcategoryid
LEFT JOIN sales.salesterritory AS st ON soh.territoryid = st.territoryid;

-- ganna use View 1 and print to see if it works

SELECT *
FROM analytics.sales_order_lines
LIMIT 20;

-- Explanation of View 1
-- grab soh and join with sod and join sod with p. that gives us the order date, month, quarter, year, product name, quantity, standard cost, and unit price. After that, to get the subcategory and category names we join with productsubcategory and productcategory. Lastly, to get the territory name we join the original soh with salesterritory as well. So this view is basically the reusable base view for sales analysis.
-- also, the "line" terminology is kinda annoying but its simple, a line is simply one product row inside an order. One order can have 20 different products in it, each with different quantities. So line_revenue is the revenue for that one product row in that one order.


---------------------------------------------------------------------------------

-- View 2

CREATE OR REPLACE VIEW analytics.monthly_sales AS
SELECT order_month, COUNT(DISTINCT salesorderid) AS total_orders, SUM(orderqty) AS total_items_sold, SUM(line_revenue) AS revenue, SUM(line_cost) AS cost, SUM(line_profit) AS profit
FROM analytics.sales_order_lines
GROUP BY order_month;

-- using it in a select now

SELECT *
FROM analytics.monthly_sales
ORDER BY order_month
LIMIT 20;

-- Explanation of View 2
-- using the previous sales_order_lines view, we grab the month, total orders, total items sold, the revenue and the cost and the profit. no joins required in this one since all this stuff is in View 1 we just gotta aggregate and group by month

---------------------------------------------------------------------------------

-- View 3

CREATE OR REPLACE VIEW analytics.product_performance AS
SELECT productid, product_name, subcategory_name, category_name, COUNT(DISTINCT salesorderid) AS orders_count, SUM(orderqty) AS quantity_sold, SUM(line_revenue) AS revenue, SUM(line_cost) AS cost, SUM(line_profit) AS profit
FROM analytics.sales_order_lines
GROUP BY productid, product_name, subcategory_name, category_name;

-- to print it out

SELECT *
FROM analytics.product_performance
ORDER BY revenue DESC
LIMIT 20;

-- Explanation of View 3
-- again we can use the same sales_order_lines and grab product and category details and find which product was ordered how many times and the revenue that product generated, the cost it had and the profit it made

---------------------------------------------------------------------------------

-- View 4

CREATE OR REPLACE VIEW analytics.category_performance AS
SELECT category_name, COUNT(DISTINCT salesorderid) AS orders_count, SUM(orderqty) AS quantity_sold, SUM(line_revenue) AS revenue, SUM(line_cost) AS cost, SUM(line_profit) AS profit
FROM analytics.sales_order_lines
GROUP BY category_name;

-- to print
SELECT *
FROM analytics.category_performance
ORDER BY revenue DESC;

-- Explanation of View 4
-- there are just 4 categories in the database, we can get revenue, cost, and profit per category from the same sales order line view


---------------------------------------------------------------------------------

-- View 5

CREATE OR REPLACE VIEW analytics.quarterly_sales AS
SELECT order_quarter, COUNT(DISTINCT salesorderid) AS total_orders, SUM(orderqty) AS total_items_sold, SUM(line_revenue) AS revenue, SUM(line_cost) AS cost, SUM(line_profit) AS profit
FROM analytics.sales_order_lines
GROUP BY order_quarter;

-- to print

SELECT *
FROM analytics.quarterly_sales
ORDER BY order_quarter;

-- Explanation of View 5
-- the quarterly sales, we can get order_quarter from the sales order lines and then have the total orders and total revenue etc for each quarter, that counts as analytics i guess

---------------------------------------------------------------------------------

-- View 6

CREATE OR REPLACE VIEW analytics.territory_performance AS
SELECT territoryid, territory_name, territory_group, COUNT(DISTINCT salesorderid) AS total_orders, SUM(orderqty) AS total_items_sold, SUM(line_revenue) AS revenue, SUM(line_cost) AS cost, SUM(line_profit) AS profit
FROM analytics.sales_order_lines
GROUP BY territoryid, territory_name, territory_group;

-- print

SELECT *
FROM analytics.territory_performance
ORDER BY revenue DESC;

-- we can get territory performance out of the sales order line as well since we had joined the territory table with soh. That is one more view


---------------------------------------------------------------------------------

-- View 7

CREATE OR REPLACE VIEW analytics.customer_performance AS
SELECT sol.customerid, 
CASE WHEN c.personid IS NOT NULL THEN 'Individual' 
WHEN c.storeid IS NOT NULL THEN 'Store' 
ELSE 'Unknown' END AS customer_type, 
COUNT(DISTINCT sol.salesorderid) AS total_orders, 
SUM(sol.orderqty) AS total_items_sold, SUM(sol.line_revenue) AS revenue, 
SUM(sol.line_profit) AS profit, 
CASE WHEN SUM(sol.line_revenue) >= 100000 
THEN 'High Value' WHEN SUM(sol.line_revenue) >= 10000 
THEN 'Medium Value' ELSE 'Low Value' END AS customer_segment
FROM analytics.sales_order_lines AS sol
JOIN sales.customer AS c ON sol.customerid = c.customerid
GROUP BY sol.customerid, customer_type;

-- print

SELECT *
FROM analytics.customer_performance
ORDER BY revenue DESC
LIMIT 20;

-- Explanation of View 7
-- we can join the customer table with the first view of sales order lines using customerid and that way we can build customer performance. This view shows total orders, total items, revenue, and profit per customer.
-- the high/medium/low categories are customer segmentation. It means we are grouping customers by their total spending so the business can quickly see which customers are more valuable.
-- also, the customer can be a normal person buying a bike, or a store buying bikes from AdventureWorks. That categorization is done with CASE WHEN.
-- One point about this view, the whole high/medium/low categorization is customer segmentation, so that completes that part of task 2 as well I think

---------------------------------------------------------------------------------

-- View 8

CREATE OR REPLACE VIEW analytics.salesperson_performance AS
SELECT sp.businessentityid AS salespersonid, e.jobtitle, sp.territoryid, st.name AS territory_name, COUNT(DISTINCT sol.salesorderid) AS total_orders, COALESCE(SUM(sol.line_revenue), 0) AS revenue, COALESCE(SUM(sol.line_profit), 0) AS profit, sp.salesquota, sp.salesytd, sp.saleslastyear
FROM sales.salesperson AS sp
JOIN humanresources.employee AS e ON sp.businessentityid = e.businessentityid
LEFT JOIN sales.salesterritory AS st ON sp.territoryid = st.territoryid
LEFT JOIN analytics.sales_order_lines AS sol ON sp.businessentityid = sol.salespersonid
GROUP BY sp.businessentityid, e.jobtitle, sp.territoryid, st.name, sp.salesquota, sp.salesytd, sp.saleslastyear;

-- print

SELECT *
FROM analytics.salesperson_performance
ORDER BY revenue DESC;

-- from the salesperson column, we can join to employee and territory, and we can find out things like which sales person did the most sales etc. or simply the performance of all the salespersons. Another cool thing is the coalesce function, it basically means that if the first arg is null, the second arg is used instead of it

---------------------------------------------------------------------------------

-- View 9

CREATE OR REPLACE VIEW analytics.inventory_health AS
SELECT p.productid, p.name AS product_name, ps.name AS subcategory_name, pc.name AS category_name, p.safetystocklevel, p.reorderpoint, COALESCE(SUM(pi.quantity), 0) AS quantity_on_hand, CASE WHEN COALESCE(SUM(pi.quantity), 0) <= p.reorderpoint THEN 'Low Stock' WHEN COALESCE(SUM(pi.quantity), 0) <= p.safetystocklevel THEN 'Watch' ELSE 'Healthy' END AS inventory_status
FROM production.product AS p
LEFT JOIN production.productinventory AS pi ON p.productid = pi.productid
LEFT JOIN production.productsubcategory AS ps ON p.productsubcategoryid = ps.productsubcategoryid
LEFT JOIN production.productcategory AS pc ON ps.productcategoryid = pc.productcategoryid
GROUP BY p.productid, p.name, ps.name, pc.name, p.safetystocklevel, p.reorderpoint;

-- print

SELECT *
FROM analytics.inventory_health
ORDER BY quantity_on_hand ASC
LIMIT 20;

-- Explanation of View 9
-- we can categorize the stocks into low, watch, and healthy categories and basically have an inventory health system. Writing the query is manageable once the metric is clear: compare quantity_on_hand with reorderpoint and safetystocklevel. This gives a useful view for low stock and inventory dashboard work.

---------------------------------------------------------------------------------

-- View 10

CREATE OR REPLACE VIEW analytics.vendor_purchasing_performance AS
SELECT v.businessentityid AS vendorid, v.name AS vendor_name, COUNT(DISTINCT poh.purchaseorderid) AS purchase_orders, SUM(pod.orderqty) AS units_ordered, SUM(pod.orderqty * pod.unitprice) AS purchase_amount, SUM(pod.receivedqty) AS units_received, SUM(pod.rejectedqty) AS units_rejected, CASE WHEN SUM(pod.receivedqty) = 0 THEN 0 ELSE SUM(pod.rejectedqty) / SUM(pod.receivedqty) END AS rejection_rate
FROM purchasing.purchaseorderheader AS poh
JOIN purchasing.purchaseorderdetail AS pod ON poh.purchaseorderid = pod.purchaseorderid
JOIN purchasing.vendor AS v ON poh.vendorid = v.businessentityid
GROUP BY v.businessentityid, v.name;

-- print

SELECT *
FROM analytics.vendor_purchasing_performance
ORDER BY purchase_amount DESC
LIMIT 20;

-- Explanation of View 10
-- vendor table basically tells who we (AdventureWorks) buys from. so if we join purchaseorderheader, purchaseorderdetail, and vendor then we know what we bought, from which vendor, how many units we ordered, how many units were received, and how many were rejected. This is useful for supplier performance analysis. Rejection rate is total rejected items divided by total received items.


---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------


-- Task 2

-- This task is asking for a chained SQL pipeline. The first 10 views already do a lot of that work, but here I am making the chain more explicit and adding dashboard/executive views on top of the earlier analytics views (just for the sake of completion, I think the views from task 1 are enough otherwise).
-- The flow is basically:
-- - Raw Tables
-- - ↓
-- - analytics.sales_order_lines
-- - ↓
-- - monthly_sales, quarterly_sales, product_performance, category_performance, territory_performance, customer_performance, salesperson_performance, inventory_health, vendor_purchasing_performance
-- - ↓
-- - customer segmentation and regional analysis views
-- - ↓
-- - executive/dashboard-ready KPI views
-- - ↓
-- - Python visualizations in Task 5

-- The next views also cover Task 3 because they are dashboard-ready datasets, and they cover Task 4 because they use CTEs, window functions, ranking functions, CASE WHEN, and conditional aggregation.

CREATE OR REPLACE VIEW analytics.monthly_sales_growth AS
WITH monthly AS (
SELECT order_month, total_orders, total_items_sold, revenue, cost, profit
FROM analytics.monthly_sales
),
growth AS (
SELECT order_month, total_orders, total_items_sold, revenue, cost, profit, LAG(revenue) OVER (ORDER BY order_month) AS previous_month_revenue
FROM monthly

-- this second CTE uses the lag window function, we basically get the revenue of the previous month using that, for comparison later
)
SELECT order_month, total_orders, total_items_sold, revenue, cost, profit, previous_month_revenue, revenue - previous_month_revenue AS revenue_change, CASE WHEN previous_month_revenue IS NULL OR previous_month_revenue = 0 THEN NULL ELSE ROUND(((revenue - previous_month_revenue) / previous_month_revenue) * 100, 2) END AS revenue_growth_percent
FROM growth;


-- Product ranking could be a dashboard of its own, or an executive KPI view:
CREATE OR REPLACE VIEW analytics.product_rankings AS
SELECT productid, product_name, subcategory_name, category_name, quantity_sold, revenue, cost, profit, RANK() OVER (ORDER BY revenue DESC) AS revenue_rank, RANK() OVER (ORDER BY profit DESC) AS profit_rank, RANK() OVER (ORDER BY profit ASC) AS loss_risk_rank
FROM analytics.product_performance;

-- using the territory performance view above, we can build a simple territory ranking dashboard view:
CREATE OR REPLACE VIEW analytics.territory_rankings AS
SELECT territoryid, territory_name, territory_group, total_orders, total_items_sold, revenue, cost, profit, RANK() OVER (ORDER BY revenue DESC) AS revenue_rank, RANK() OVER (ORDER BY profit DESC) AS profit_rank
FROM analytics.territory_performance;


-- Ok, here is the executive_kpi_summary view
CREATE OR REPLACE VIEW analytics.executive_kpi_summary AS
WITH sales_summary AS (
SELECT SUM(revenue) AS total_revenue, SUM(cost) AS total_cost, SUM(profit) AS total_profit, SUM(total_orders) AS total_orders, SUM(total_items_sold) AS total_items_sold
FROM analytics.monthly_sales
),
customer_summary AS (
SELECT COUNT(*) AS total_customers, SUM(CASE WHEN customer_segment = 'High Value' THEN 1 ELSE 0 END) AS high_value_customers, SUM(CASE WHEN customer_type = 'Store' THEN 1 ELSE 0 END) AS store_customers, SUM(CASE WHEN customer_type = 'Individual' THEN 1 ELSE 0 END) AS individual_customers
FROM analytics.customer_performance
),
inventory_summary AS (
SELECT SUM(CASE WHEN inventory_status = 'Low Stock' THEN 1 ELSE 0 END) AS low_stock_products, SUM(CASE WHEN inventory_status = 'Watch' THEN 1 ELSE 0 END) AS watch_products, SUM(CASE WHEN inventory_status = 'Healthy' THEN 1 ELSE 0 END) AS healthy_products
FROM analytics.inventory_health
)
SELECT ss.total_revenue, ss.total_cost, ss.total_profit, ss.total_orders, ss.total_items_sold, cs.total_customers, cs.high_value_customers, cs.store_customers, cs.individual_customers, inv.low_stock_products, inv.watch_products, inv.healthy_products
FROM sales_summary AS ss
CROSS JOIN customer_summary AS cs
CROSS JOIN inventory_summary AS inv;


---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------


-- Task 3

-- Task 3 asks for executive KPI datasets, this is already done as I said above
-- The dashboard-ready views are:
-- - analytics.monthly_sales and analytics.monthly_sales_growth for monthly revenue and sales growth
-- - analytics.quarterly_sales for quarterly revenue
-- - analytics.product_performance and analytics.product_rankings for best/worst products and product profitability
-- - analytics.customer_performance for customer segments and customer lifetime value style metrics
-- - analytics.salesperson_performance for employee/salesperson performance
-- - analytics.territory_performance and analytics.territory_rankings for regional analysis
-- - analytics.inventory_health for low stock / inventory health
-- - analytics.vendor_purchasing_performance for supplier performance
-- - analytics.executive_kpi_summary for the final executive KPI row

-- quick checks for Task 3 dashboard datasets

SELECT *
FROM analytics.monthly_sales_growth
ORDER BY order_month
LIMIT 20;

SELECT *
FROM analytics.product_rankings
ORDER BY revenue_rank
LIMIT 20;

SELECT *
FROM analytics.territory_rankings
ORDER BY revenue_rank;

SELECT *
FROM analytics.executive_kpi_summary;


---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------


-- Task 4

-- Task 4 is not really another business query, it is a checklist of advanced SQL techniques used in the project.
-- Multiple chained CTEs:
-- - analytics.monthly_sales_growth uses monthly and growth CTEs.
-- - analytics.executive_kpi_summary uses sales_summary, customer_summary, and inventory_summary CTEs.
-- Window functions:
-- - analytics.monthly_sales_growth uses LAG(revenue) OVER (ORDER BY order_month).
-- Ranking functions:
-- - analytics.product_rankings and analytics.territory_rankings use RANK() OVER (...).
-- CASE WHEN:
-- - analytics.customer_performance uses CASE WHEN for customer_type and customer_segment.
-- - analytics.inventory_health uses CASE WHEN for inventory_status.
-- Conditional aggregation:
-- - analytics.executive_kpi_summary uses SUM(CASE WHEN ... THEN 1 ELSE 0 END).
-- Complex JOINs:
-- - analytics.sales_order_lines joins sales, production, and territory tables.
-- - analytics.vendor_purchasing_performance joins purchasing and vendor tables.
-- Reusable intermediate views:
-- - analytics.sales_order_lines is reused by most of the sales/customer/product/territory views.
-- - monthly_sales, product_performance, territory_performance, customer_performance, and inventory_health are reused by the dashboard/executive views.

-- So Task 4 is covered across the whole SQL pipeline, not by one separate random query.

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

-- Task 5

-- please view executive_analysis.ipynb file