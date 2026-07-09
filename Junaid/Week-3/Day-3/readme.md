## Explanation of when to use a subquery vs a CTE vs a window function


- Subqueries, CTEs and window functions are normally all used when the result of a query needs to be an input into another query. Although window functions are for doing calculations on rows while keeping row detail.

- **Subquery:** simply, a query inside a query is a subquery. normally, you write a full query inside the WHERE clause, that is the most obvious pattern. Although, we can also put a subquery in a FROM clause or even in the SELECT clause.
  - Most common situation where you end up using subqueries is when you have to compare something to an average or min or max etc in a WHERE clause
  - Another common situation where you would use subqueries is when you want to find records that do or do not exist somewhere else, again, this would be in the WHERE clause
  - the third case would be if you want to do an aggregation, and then filter that agggregation (although, now that I think about it, you can easily do that with HAVING)
  - **Scalar subquery** returns one value (one single row or column)
  - **Non-Correlated subquery** is one that can run independently, as in it does not depend on the outer query and can be run on its own. You can run it by itself
  - **Correlated subquery** depends on outer query, it cannot be executed on its own. This is the case when you use some variables from the outer query in the inner query and hence the inner query cannot run without that outer variable coming from the outer query.
- **CTE:** CTE stands for Common Table Expression and it makes a named temp result. It is basically used to store intermediate results in a variable. You build a CTE with the WITH clause
  - Normally, a subquery is enough in most cases, but if you want clearer and better looking code then its better to store the intermediate stage results in a variable with CTEs instead of using a direct subquery. Its mostly a code quality and readability thing
- **Window Function:** Window functions calculates an aggregation across rows of a table, just like GROUP BY, but it does not collapse the result into a single row, you still get the raw result and each row and the aggregation is appended to that record as well.
  - PARTITION BY: Divides the rows into groups (partitions) that share the same value, resetting the calculation for each group.
  - There are 3 main types of window functions, ROW_NUMBER: used to give every row a unique number
  - RANK assigns same value to ties, like if the value of the column is the same, the rank is also the same, but if you get the same value, it will end up then skipping a value and that value won't exist in the rank column
  - DENSE_RANK simply does the same as RANK but does not skip any values even afte a tie.
  - LAG is another window function, it is used to get the previous row's value. 

## Explanation of how each business question was solved

### Part 1 — Aggregation Basics

#### 1. Total revenue generated per store

To calculate revenue per store, I joined `payment` to `staff` so each payment could be connected to the staff member who processed it, and then connected the staff member to their store. After that, I grouped by `store_id` and used `SUM(amount)` to calculate total revenue for each store.

#### 2. Average rental duration per film category

To find average rental duration per category, I started from the `rental` table because it contains both `rental_date` and `return_date`. The rental duration was calculated by subtracting `rental_date` from `return_date`. Then I joined `rental` to `inventory`, then to `film_category`, and finally to `category`. I grouped by category and used `AVG(return_date - rental_date)` to get the average rental duration.

#### 3. Number of rentals made each month

This query only needed the `rental` table because each row in `rental` represents one rental. I used `DATE_TRUNC('month', rental_date)` to group rental dates by month, then used `COUNT(*)` to count how many rentals happened in each month.

#### 4. Categories with more than 50 films

To count films per category, I joined `film_category` with `category`. Then I grouped by category name and used `COUNT(film_id)` to count the number of films in each category. Since the filtering condition depends on an aggregate result, I used `HAVING COUNT(film_id) > 50`.

### Part 2 — Subquery Challenges

#### 1. Customers who spent more than the average customer spend

First, I calculated each customer’s total spending by joining `customer` with `payment`, grouping by customer, and using `SUM(amount)`. Then I used a subquery to calculate the average total customer spend. The outer query used `HAVING` to keep only customers whose total spending was greater than that average.

#### 2. Films with the highest rental rate in each category

For this query, I joined `film`, `film_category`, and `category` to connect each film to its category. Then I used a correlated subquery to find the maximum rental rate for the current category. The outer query returned films where the film’s `rental_rate` matched the maximum rental rate for that same category.

#### 3. Customers who have never rented a film

To find customers who never rented, I selected customers from the `customer` table and used a subquery against the `rental` table. The logic was to return customers whose `customer_id` does not appear in the list of customer IDs from `rental`. In this dataset, the result was empty, meaning every customer has rented at least once.

#### 4. Store with the highest total revenue

To find the store with the highest revenue, I calculated total revenue per store by joining `payment`, `staff`, and `store`, then grouping by store. A subquery was used to calculate the maximum store revenue, and the outer query returned the store whose total revenue matched that maximum value.

### Part 3 — CTE & Window Function Challenges

#### 1. Rank customers by total spend within each city

I used a CTE to first calculate each customer’s total spending along with their city. This required joining `customer`, `address`, `city`, and `payment`, then grouping by customer and city. In the outer query, I used `RANK()` with `PARTITION BY city` so that the ranking restarted for each city, and `ORDER BY total_spent DESC` so the highest spender in each city received rank 1.

In this dataset, most cities only have one customer, so many ranks appear as 1. The query is still correct because each customer is being ranked within their own city.

#### 2. Most recently rented film for each customer

I used a CTE to join `customer`, `rental`, `inventory`, and `film`, so each rental could be connected to the customer and film title. Then I used `ROW_NUMBER()` with `PARTITION BY customer_id` and `ORDER BY rental_date DESC`. This numbered each customer’s rentals from newest to oldest. The outer query filtered for `row_number = 1`, which returned only the most recent rental for each customer.

#### 3. Month-over-month rental revenue growth

I used one CTE to calculate total revenue per month from the `payment` table using `DATE_TRUNC('month', payment_date)` and `SUM(amount)`. Then I used `LAG()` to get the previous month’s revenue beside each month’s current revenue. Finally, I calculated the percentage growth using the formula:

`((current_month_revenue - previous_month_revenue) / previous_month_revenue) * 100`

The first month has no previous month, so its growth value is `NULL`.

#### 4. Top 3 highest-grossing films per category

First, I used a CTE to calculate total revenue for each film in each category. This required joining `category`, `film_category`, `film`, `inventory`, `rental`, and `payment`. Then I used `RANK()` with `PARTITION BY category` and `ORDER BY total_revenue DESC` to rank films inside each category. The outer query filtered for ranks less than or equal to 3.

Because `RANK()` gives the same rank to ties, some categories may return more than exactly three films if there are ties.

## Business Insights

1. Store 2 generated slightly more total revenue than Store 1, so Store 2 performed better overall in rental sales.

2. Some film categories have more than 50 films, which means the catalog is not evenly distributed across categories. Categories with more films may have more variety and potentially more rental opportunities.

3. Every customer in the dataset appears to have rented at least one film, because the query for customers who never rented returned no rows. This suggests the customer table only contains active or historically active customers.