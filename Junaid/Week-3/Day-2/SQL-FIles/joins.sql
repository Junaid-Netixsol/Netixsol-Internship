-- display customer name, email, city, and country

-- SELECT first_name, last_name, email, city, country
-- FROM customer
-- JOIN address ON customer.address_id = address.address_id
-- JOIN city ON address.city_id = city.city_id
-- JOIN country ON city.country_id = country.country_id

-----------------------------------------------------------

-- display payments with customer name, film title, and amount paid

-- SELECT first_name, last_name, amount, payment_date,  title
-- from payment
-- JOIN customer ON payment.customer_id = customer.customer_id
-- JOIN rental ON payment.rental_id = rental.rental_id
-- JOIN inventory ON rental.inventory_id = inventory.inventory_id
-- JOIN film ON inventory.film_id = film.film_id

-----------------------------------------------------------

-- Find the Top 10 customers based on total amount spent.

-- SELECT first_name, last_name, SUM(amount) as Amount_Spent
-- FROM payment
-- JOIN customer ON payment.customer_id = customer.customer_id
-- GROUP BY first_name, last_name
-- ORDER BY Amount_Spent DESC
-- LIMIT 10

-----------------------------------------------------------

-- Display each film with its Category and Rental Rate.

-- SELECT title, rental_rate, name
-- FROM film	
-- JOIN film_category ON film.film_id = film_category.film_id
-- JOIN category ON film_category.category_id = category.category_id

-----------------------------------------------------------

-- Find all actors who appeared in each film.

-- SELECT title, first_name, last_name
-- FROM film
-- JOIN film_actor ON film.film_id = film_actor.film_id
-- JOIN actor ON film_actor.actor_id = actor.actor_id

-----------------------------------------------------------

-- Count how many films belong to each category.

-- SELECT name, COUNT(film_id) as film_count
-- FROM category
-- JOIN film_category ON category.category_id = film_category.category_id
-- GROUP BY name
-- ORDER BY film_count DESC

-----------------------------------------------------------

-- Which categories generated the highest revenue? 
-- (Hint: This requires joining multiple tables.)

-- SELECT name, SUM(amount) as total_revenue
-- FROM category
-- JOIN film_category ON category.category_id = film_category.category_id
-- JOIN film ON film_category.film_id = film.film_id
-- JOIN inventory ON film.film_id = inventory.film_id
-- JOIN rental ON inventory.inventory_id = rental.inventory_id
-- JOIN payment ON rental.rental_id = payment.rental_id
-- GROUP BY name
-- ORDER BY total_revenue DESC

-----------------------------------------------------------

-- Find customers who have rented more than 20 films.

-- SELECT first_name, last_name, COUNT(film_id) as films_rented
-- FROM customer
-- JOIN rental ON customer.customer_id = rental.customer_id
-- JOIN inventory ON rental.inventory_id = inventory.inventory_id
-- GROUP BY first_name, last_name
-- HAVING COUNT(film_id) > 20
-- ORDER BY films_rented DESC

-----------------------------------------------------------

-- Which cities generated the highest rental revenue?

SELECT store.store_id, city, SUM(amount) as Revenue
FROM store
JOIN address ON store.address_id = address.address_id
JOIN city ON address.city_id = city.city_id
JOIN inventory ON store.store_id = inventory.store_id
JOIN rental ON inventory.inventory_id = rental.inventory_id
JOIN payment ON rental.rental_id = payment.rental_id
GROUP BY store.store_id, city
ORDER BY Revenue DESC