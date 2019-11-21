/*Let's start with creating a table that provides the following details: actor's first and last name combined as full_name, film title, film description and length of the movie.
How many rows are there in the table? Please inout correctly*/
SELECT a.first_name, a.last_name,
CONCAT(first_name, ' ', last_name) AS full_name,
f.title, f.description, f.length
FROM film_actor fa
JOIN actor a
ON fa.actor_id = a.actor_id
JOIN film f
ON fa.film_id = f.film_id

/*Write a query that creates a list of actors and movies where the movie length was more than 60 minutes. How many rows are there in this query result?*/
SELECT a.first_name, a.last_name,
CONCAT(first_name, ' ', last_name) AS full_name,
f.title, f.description, f.length
FROM film_actor fa
JOIN actor a
ON fa.actor_id = a.actor_id
JOIN film f
ON fa.film_id = f.film_id
WHERE f.length > 60

/*Write a query that captures the actor id, full name of the actor, and counts the number of movies each actor has made. (HINT: Think about whether you should group by actor id or the full name of the actor.) Identify the actor who has made the maximum number movies.*/

SELECT actor_id, full_name, COUNT(film_title)
FROM
(SELECT a.actor_id actor_id,
a.first_name, a.last_name,
CONCAT(first_name, ' ', last_name) AS full_name,
f.title film_title
FROM film_actor fa
JOIN actor a
ON fa.actor_id = a.actor_id
JOIN film f
ON fa.film_id = f.film_id)t1
GROUP BY 1,2
ORDER BY 3 DESC

/*Write a query that displays a table with 4 columns: actor's full name, film title, length of movie, and a column name "filmlen_groups" that classifies movies based on their length. Filmlen_groups should include 4 categories: 1 hour or less, Between 1-2 hours, Between 2-3 hours, More than 3 hours.*/

SELECT full_name,
film_title,
filmlen,
CASE WHEN filmlen <= 60 THEN '1 hour or less'
WHEN filmlen > 60 AND filmlen <= 120 THEN 'Between 1-2 hours'
WHEN filmlen > 120 AND filmlen <= 180 THEN 'Between 2-3 hours'
ELSE 'More than 3 hours' END AS filmlen_groups
FROM
(SELECT a.first_name, a.last_name,
CONCAT(first_name, ' ', last_name) AS full_name,
f.title film_title,
f.length filmlen
FROM film_actor fa
JOIN actor a
ON fa.actor_id = a.actor_id
JOIN film f
ON f.film_id = fa.film_id)t1

/*Write a query you to create a count of movies in each of the 4 filmlen_groups: 1 hour or less, Between 1-2 hours, Between 2-3 hours, More than 3 hours.*/
SELECT DISTINCT(filmlen_groups),
COUNT(title) OVER(PARTITION BY filmlen_groups) AS filmcount_bylencat
FROM
(SELECT title, length,
CASE WHEN length <= 60 THEN '1 hour or less'
WHEN length > 60 AND length <= 120 THEN 'Between 1-2 hours'
WHEN length > 120 AND length <= 180 THEN 'Between 2-3 hours'
ELSE 'More than 3 hours' END AS filmlen_groups
FROM film)t1
ORDER BY filmlen_groups

/*THE REAL QUESTOINS*/
/*Q1-We want to understand more about the movies that families are watching. The following categories are considered family movies: Animation, Children, Classics, Comedy, Family and Music.

Create a query that lists each movie, the film category it is classified in, and the number of times it has been rented out.*/
SELECT film_title, category_name, COUNT(date_of_rental) rental_count
FROM
(SELECT f.title film_title, c.name category_name, r.rental_date date_of_rental
FROM film_category fc
JOIN category c
ON fc.category_id = c.category_id
JOIN film f
ON f.film_id = fc.film_id
JOIN inventory i
ON f.film_id = i.film_id
JOIN rental r
ON r.inventory_id = i.inventory_id
WHERE c.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
)t1
GROUP BY 1,2
ORDER BY category_name, film_title

/*Q2-Now we need to know how the length of rental duration of these family-friendly movies compares to the duration that all movies are rented for. Can you provide a table with the movie titles and divide them into 4 levels (first_quarter, second_quarter, third_quarter, and final_quarter) based on the quartiles (25%, 50%, 75%) of the rental duration for movies across all categories? Make sure to also indicate the category that these family-friendly movies fall into.*/
SELECT film_title, category_name, rental_duration,
NTILE(4) OVER (ORDER BY rental_duration) as standard_quartile
FROM
(SELECT f.title film_title, c.name category_name, f.rental_duration rental_duration
FROM  film_category fc
JOIN category c
ON c.category_id = fc.category_id
JOIN film f
ON f.film_id = fc.film_id
WHERE c.name IN('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music'))t1

/*Q3-The following table header provides a preview of what your table should look like. The Count column should be sorted first by Category and then by Rental Duration category.*/
SELECT category_name, standard_quartile, COUNT(rental_duration)
FROM
(SELECT film_title, category_name, rental_duration ,
NTILE(4) OVER (ORDER BY rental_duration) AS standard_quartile
FROM
(SELECT f.title film_title, c.name category_name, f.rental_duration rental_duration
FROM  film_category fc
JOIN category c
ON c.category_id = fc.category_id
JOIN film f
ON f.film_id = fc.film_id
WHERE c.name IN('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music'))t1)
GROUP BY 1,2
ORDER BY 1,2
/*Question set 2*/
/* Q1-We want to find out how the two stores compare in their count of rental orders during every month for all the years we have data for. Write a query that returns the store ID for the store, the year and month and the number of rental orders each store has fulfilled for that month. Your table should include a column for each of the following: year, month, store ID and count of rental orders fulfilled during that month.*/
SELECT DATE_PART('month',r.rental_date) AS rental_month, DATE_PART('year', r.rental_date) AS rental_year,(s.store_id) store_id, COUNT(*)
FROM staff st
JOIN store s
ON st.store_id = s.store_id
JOIN rental r
ON r.staff_id = st.staff_id
GROUP BY 1,2,3
ORDER BY 4 DESC

/*Q2- We would like to know who were our top 10 paying customers, how many payments they made on a monthly basis during 2007, and what was the amount of the monthly payments. Can you write a query to capture the customer name, month and year of payment, and total payment amount for each month by these top 10 paying customers?*/
WITH TOP10 AS (
SELECT c.customer_id,
CONCAT(c.first_name, ' ', c.last_name) full_name,
SUM(amount) pay_amount
FROM payment p
JOIN customer c
ON p.customer_id = c.customer_id
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 10)

SELECT DATE_TRUNC('month', p.payment_date) pay_month,
top10.full_name,
COUNT(p.payment_date) pay_count_per_month,
SUM(p.amount) pay_amount
FROM payment p
JOIN top10
ON top10.customer_id = p.customer_id
GROUP BY 1,2
ORDER BY 2

/*Q3 - Finally, for each of these top 10 paying customers, I would like to find out the difference across their monthly payments during 2007. Please go ahead and write a query to compare the payment amounts in each successive month. Repeat this for each of these 10 paying customers. Also, it will be tremendously helpful if you can identify the customer name who paid the most difference in terms of payments.*/
WITH TOP10 AS (
SELECT c.customer_id,
CONCAT(c.first_name, ' ', c.last_name) full_name,
SUM(amount) pay_amount
FROM payment p
JOIN customer c
ON p.customer_id = c.customer_id
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 10)

SELECT top10.customer_id,
DATE_TRUNC('month', p.payment_date) pay_month,
top10.full_name,
SUM(p.amount) pay_amount,
LEAD(SUM(p.amount)) OVER (PARTITION BY top10.customer_id ORDER BY DATE_TRUNC('month', p.payment_date)) AS lead,
LEAD(SUM(p.amount)) OVER (PARTITION BY top10.customer_id ORDER BY DATE_TRUNC('month', p.payment_date)) - SUM(p.amount) AS lead_difference
FROM payment p
JOIN top10
ON top10.customer_id = p.customer_id
GROUP BY 1,2,3
ORDER BY 3,2
