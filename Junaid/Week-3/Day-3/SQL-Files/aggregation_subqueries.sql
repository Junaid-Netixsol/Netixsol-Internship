-- PART 1: Aggregation

-- Find total revenue generated per store

-- SELECT SUM(amount), store.store_id
-- FROM payment
-- JOIN staff ON payment.staff_id = staff.staff_id
-- JOIN store ON staff.staff_id = store.manager_staff_id
-- GROUP BY store.store_id

-- using a subquery to do the same thing

-- SELECT 
--     (SELECT s.store_id 
--      FROM staff st 
--      JOIN store s ON st.staff_id = s.manager_staff_id 
--      WHERE st.staff_id = p.staff_id) AS store_id,
--     SUM(p.amount)
-- FROM payment p
-- GROUP BY 1;

-- The CTE approach

-- WITH store_payments AS (
-- 	SELECT store.store_id, amount
-- 	FROM store
-- 	JOIN staff ON store.manager_staff_id = staff.staff_id
-- 	JOIN payment ON staff.staff_id = payment.staff_id
-- )

-- SELECT store_id, SUM(amount)
-- FROM store_payments
-- GROUP BY store_id

-----------------------------------------------------------------------------

-- Find the average rental duration per film category

-- SELECT film_category.category_id, AVG(return_date - rental_date) AS rental_duration
-- FROM rental
-- JOIN inventory ON rental.inventory_id = inventory.inventory_id
-- JOIN film_category ON inventory.film_id = film_category.film_id
-- GROUP BY film_category.category_id
-- ORDER BY rental_duration DESC

-----------------------------------------------------------------------------

-- Find the number of rentals made each month

-- SELECT DATE_TRUNC('month', rental_date) AS rental_month, COUNT(*) AS rental_count
-- FROM rental
-- GROUP BY DATE_TRUNC('month', rental_date)

-----------------------------------------------------------------------------

-- Find categories with more than 50 films

-- SELECT COUNT(fc.film_id) AS film_count, c.name
-- FROM film_category fc
-- JOIN category c on fc.category_id = c.category_id
-- GROUP BY c.name
-- HAVING COUNT(fc.film_id) > 50

-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------


-- Part 2: Sub Queries

-- Find customers who spent more than the average customer spend

-- SELECT first_name, last_name, SUM(amount) as customer_spend
-- FROM customer
-- JOIN payment ON customer.customer_id = payment.customer_id
-- GROUP BY first_name, last_name
-- HAVING SUM(amount) > (SELECT AVG(total_customer_spend) as avg_customer_spend
-- FROM ( SELECT SUM(amount) AS total_customer_spend FROM payment GROUP BY customer_id))
-- ORDER BY customer_spend ASC

-----------------------------------------------------------------------------

-- Find the film(s) with the highest rental rate in each category (use a correlated subquery).

-- SELECT c.name AS category, f.title, f.rental_rate
-- FROM film f
-- JOIN film_category fc ON f.film_id = fc.film_id
-- JOIN category c ON fc.category_id = c.category_id
-- WHERE f.rental_rate = 
-- (SELECT MAX(f.rental_rate) FROM film f JOIN film_category fc2 ON f.film_id = fc2.film_id
--  WHERE fc2.category_id = fc.category_id)
--  ORDER BY c.name, f.title, f.rental_rate

-----------------------------------------------------------------------------

-- Find customers who have never rented a film (use NOT IN / NOT EXISTS).

-- SELECT c.first_name, c.last_name
-- FROM customer c
-- WHERE c.customer_id NOT IN (SELECT r.customer_id FROM rental r)

-----------------------------------------------------------------------------

-- Find the store with the highest total revenue using a subquery in the WHERE clause.

-- SELECT s.store_id
-- FROM store s
-- WHERE s.store_id = 
-- (SELECT s2.store_id
-- FROM payment p
-- JOIN staff sf ON p.staff_id = sf.staff_id
-- JOIN store s2 ON sf.staff_id = s2.manager_staff_id
-- GROUP BY s2.store_id
-- HAVING SUM(p.amount) = 
-- (SELECT SUM(p2.amount) as store_rev
-- FROM payment p2
-- JOIN staff sf2 ON p2.staff_id = sf2.staff_id
-- JOIN store s3 ON sf2.staff_id = s3.manager_staff_id
-- GROUP BY s3.store_id
-- ORDER BY store_rev DESC
-- LIMIT 1)
-- )


-- an optimized ai version

-- SELECT
--     s.store_id
-- FROM store s
-- JOIN staff sf ON s.store_id = sf.store_id
-- JOIN payment p ON sf.staff_id = p.staff_id
-- GROUP BY s.store_id
-- HAVING SUM(p.amount) = (
--     SELECT MAX(store_revenue)
--     FROM (
--         SELECT
--             s2.store_id,
--             SUM(p2.amount) AS store_revenue
--         FROM store s2
--         JOIN staff sf2 ON s2.store_id = sf2.store_id
--         JOIN payment p2 ON sf2.staff_id = p2.staff_id
--         GROUP BY s2.store_id
--     ) AS store_totals
-- )

-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

-- Part 3: CTEs

-- Using a CTE, rank customers by total spend within each city.

-- first we need customer totals with the cities also present

-- WITH customer_totals AS (
-- SELECT c.customer_id, c.first_name, c.last_name, ci.city, SUM(p.amount) as total_spent
-- FROM customer c
-- JOIN address a ON c.address_id = a.address_id
-- JOIN city ci ON a.city_id = ci.city_id
-- JOIN payment p ON c.customer_id = p.customer_id
-- GROUP BY c.first_name, c.last_name, ci.city, c.customer_id
-- )

-- SELECT customer_id, first_name, last_name, city, 
-- RANK() OVER (PARTITION BY city ORDER BY total_spent DESC) AS city_rank
-- FROM customer_totals
-- ORDER BY city, city_rank


-----------------------------------------------------------------------------

-- Using ROW_NUMBER(), find the most recently rented film for each customer.

-- WITH recent_rentals AS (
--     SELECT
--         c.customer_id,
--         c.first_name,
--         c.last_name,
--         f.title,
--         r.rental_date,
--         ROW_NUMBER() OVER (
--             PARTITION BY c.customer_id
--             ORDER BY r.rental_date DESC
--         ) AS rental_rank
--     FROM customer c
--     JOIN rental r ON c.customer_id = r.customer_id
--     JOIN inventory i ON r.inventory_id = i.inventory_id
--     JOIN film f ON i.film_id = f.film_id
-- )
-- SELECT
--     customer_id,
--     first_name,
--     last_name,
--     title,
--     rental_date
-- FROM recent_rentals
-- WHERE rental_rank = 1
-- ORDER BY customer_id;

-----------------------------------------------------------------------------

-- Using a CTE, calculate month-over-month rental revenue growth.

-- WITH monthly_revenue AS (
--     SELECT
--         DATE_TRUNC('month', payment_date) AS revenue_month,
--         SUM(amount) AS monthly_revenue
--     FROM payment
--     GROUP BY DATE_TRUNC('month', payment_date)
-- ),
-- monthly_with_previous AS (
--     SELECT
--         revenue_month,
--         monthly_revenue,
--         LAG(monthly_revenue) OVER (
--             ORDER BY revenue_month
--         ) AS previous_month_revenue
--     FROM monthly_revenue
-- )
-- SELECT
--     revenue_month,
--     monthly_revenue,
--     previous_month_revenue,
--     ROUND(
--         ((monthly_revenue - previous_month_revenue) / previous_month_revenue) * 100,
--         2
--     ) AS revenue_growth_percentage
-- FROM monthly_with_previous
-- ORDER BY revenue_month;

-----------------------------------------------------------------------------

-- Find the top 3 highest-grossing films per category using RANK() inside a CTE.

-- WITH film_revenue AS (
--     SELECT
--         c.name AS category,
--         f.film_id,
--         f.title,
--         SUM(p.amount) AS total_revenue
--     FROM category c
--     JOIN film_category fc ON c.category_id = fc.category_id
--     JOIN film f ON fc.film_id = f.film_id
--     JOIN inventory i ON f.film_id = i.film_id
--     JOIN rental r ON i.inventory_id = r.inventory_id
--     JOIN payment p ON r.rental_id = p.rental_id
--     GROUP BY c.name, f.film_id, f.title
-- ),
-- ranked_films AS (
--     SELECT
--         category,
--         film_id,
--         title,
--         total_revenue,
--         RANK() OVER (
--             PARTITION BY category
--             ORDER BY total_revenue DESC
--         ) AS category_revenue_rank
--     FROM film_revenue
-- )
-- SELECT
--     category,
--     title,
--     total_revenue,
--     category_revenue_rank
-- FROM ranked_films
-- WHERE category_revenue_rank <= 3
-- ORDER BY category, category_revenue_rank, title;