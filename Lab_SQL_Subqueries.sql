/*
Lab | SQL Subqueries

In this lab, you will be using the Sakila database of movie rentals.

Instructions

1. How many copies of the film Hunchback Impossible exist in the inventory system?
2. List all films longer than the average.
3. Use subqueries to display all actors who appear in the film Alone Trip.
4. Sales have been lagging among young families, and you wish to target all family movies for a promotion. Identify all movies categorized as family films.
5. Get name and email from customers from Canada using subqueries. Do the same with joins.
6. Which are films starred by the most prolific actor? ** (appeared in most movies)
7. Films rented by most profitable customer. ** most amount paid
8. Customers who spent more than the average.
*/

use sakila; 
#1. How many copies of the film Hunchback Impossible exist in the inventory system?
select f.title, count(i.inventory_id) from inventory i
join film as f on f.film_id = i.film_id
where f.title in ('Hunchback Impossible');

#2. List all films longer than the average.
select title, length from film
where length > (select avg(length) from film);

#3. Use subqueries to display all actors who appear in the film Alone Trip.

select concat(first_name, ' ',last_name) from actor 
where actor_id in 
(
	select actor_id from film_actor 
	where film_id in
		(
		select film_id from film where title = ('Alone Trip')
		)
)
;

#4. Sales have been lagging among young families, and you wish to target all family movies for a promotion. Identify all movies categorized as family films.

select title from film where film_id in
(
	select film_id from film_category
	where category_id in
		(
		select category_id from category where name = 'Family'
		)
)
;

#5. Get name and email from customers from Canada using subqueries. Do the same with joins.

#SQ
select first_name, last_name, email from customer where address_id in
(
select address_id from address where city_id in
(
select city_id from city where country_id in 
( select country_id from country where country = "Canada")
)
);

#JOIN
select c.first_name, c.last_name, c.email, ctr.country from customer c
join address a on a.address_id = c.address_id
join city on city.city_id = a.city_id
join country as ctr on ctr.country_id = city.country_id
where country = "Canada";

#6. Which are films starred by the most prolific actor? ** (appeared in most movies)

select film_id from film_actor 

where actor_id in 
(
	select actor_id, count(film_id) as film_count from film_actor
		group by actor_id
		order by count(film_id) desc
		where row_number() = 1

)
;
-- returns actor_id appeared in most movies 
select actor_id from 
(
	select actor_id, count(film_id) as film_count, row_number() over (order by count(film_id) desc) as magic 
	from film_actor
	group by actor_id
	order by count(film_id) desc
) as alias_1

where magic = 1 
;

-- the whole query 
select title from film where film_id in
(
select film_id from film_actor where actor_id in
(
	select actor_id from 
(
	select actor_id, count(film_id) as film_count, row_number() over (order by count(film_id) desc) as magic 
	from film_actor
	group by actor_id
	order by count(film_id) desc
) as alias_1

where magic = 1 
)
);


#7. Films rented by most profitable customer. ** most amount paid

-- returns customer_id that spent most
select customer_id from (
select customer_id, sum(amount), row_number() over (order by sum(amount) desc) as ranking from payment
group by customer_id) as al_1
where ranking = 1
;
 
-- whole query
select f.title from film f
join inventory i on f.film_id = i.film_id
join rental r on r.inventory_id = i.inventory_id

where customer_id in 
(
select customer_id from (
select customer_id, sum(amount), row_number() over (order by sum(amount) desc) as ranking from payment
group by customer_id) as al_1
where ranking = 1
)
;

#8. Customers who spent more than the average.
-- returns how much customers spent
select customer_id, sum(amount) as spent from payment
group by customer_id;

-- returns average of the amount spent bu customer 
select avg(spent) from 
	(select customer_id, sum(amount) as spent from payment
	group by customer_id
	) as al_1
;
use sakila;
-- whole query
select * from
(select customer_id, sum(amount) as spent from payment
	group by customer_id
	) as al_1
where spent > 
(
	select avg(spent) from 
	(select customer_id, sum(amount) as spent from payment
	group by customer_id
	) as al_2
) 
;

-- whole query+customer name 

select al_1.customer_id, al_1.spent, concat(c.first_name, ' ',c.last_name) from
(select customer_id, sum(amount) as spent from payment
	group by customer_id
	) as al_1
join customer as c on c.customer_id = al_1.customer_id	
-- join first and then have a where clause 

where spent > 
(
	select avg(spent) from 
	(select customer_id, sum(amount) as spent from payment
	group by customer_id
	) as al_2
) 
;



/*
Lab | SQL Advanced queries

In this lab, you will be using the Sakila database of movie rentals.

Instructions

1.List each pair of actors that have worked together.
2. For each film, list actor that has acted in more films.
*/

use sakila;

#1.List each pair of actors that have worked together.

#Option 1
select a1.actor_id, concat(an1.first_name,' ', an1.last_name) as actor_1, 
	a2.actor_id, concat(an2.first_name,' ',an2.last_name) as actor_2 
	from sakila.film_actor as a1
join sakila.film_actor as a2 on a2.film_id = a1.film_id 
-- adding < to avoid pairs in the list 
and a1.actor_id < a2.actor_id
join sakila.actor as an1 on an1.actor_id = a1.actor_id
join sakila.actor as an2 on an2.actor_id = a2.actor_id
group by a1.actor_id, a2.actor_id
order by a1.actor_id, a2.actor_id;



#Option 2 - with repetitions 
use sakila;
select distinct * from 
(
select a1.actor_id as actor_id_1, concat(a1.first_name, ' ', a1.last_name) as actor1, 
a2.actor_id as actor_id_2, concat(a2.first_name, ' ', a2.last_name) as actor2 from actor a1
join film_actor fa1
on fa1.actor_id = a1.actor_id
join film_actor fa2 
on fa1.film_id = fa2.film_id and fa1.actor_id <> fa2.actor_id
join actor as a2 
on a2.actor_id = fa2.actor_id
order by actor_id_1, actor_id_2
) as s;






#2. For each film, list actor that has acted in more films.

-- returns film_id - title -actor id - actor name
select fa.film_id, f.title, fa.actor_id, concat(a.first_name, ' ',a.last_name) as actor_name 
from film_actor fa
right join film f on f.film_id = fa.film_id
right join actor a on a.actor_id  = fa.actor_id
order by fa.film_id, f.title; 

-- films where actors played
select actor_id, count(film_id) as actor_film from film_actor
group by actor_id
order by actor_id;

-- creating a view with the infor needed 
drop view film_actor_film;
create view film_actor_film as

with cte_af as
	(select actor_id, count(film_id) as actor_film from film_actor
	group by actor_id
	order by actor_id)
 
select fa.film_id, f.title, fa.actor_id, concat(a.first_name, ' ',a.last_name) as actor_name,
cte.actor_film 
from film_actor fa
right join film f on f.film_id = fa.film_id
right join actor a on a.actor_id  = fa.actor_id
right join cte_af as cte on cte.actor_id = a.actor_id
order by fa.film_id, f.title, actor_film desc
; 

select * from film_actor_film;


#Final Query
select title, actor_name from 
(
-- subq returning +ranking by film 
select film_id, title, actor_name, 
dense_rank() over (partition by film_id order by actor_film desc) as ranking
from film_actor_film
) as magic

where ranking = 1
order by title;

