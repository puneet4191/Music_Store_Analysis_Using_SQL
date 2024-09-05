/*Question set 1- Easy*/

-- Q1. Who is the senior most employee based on job title?
select * from employee
order by levels desc limit 1;

-- Q2. Which countries have the most invoices?
select billing_country bc, count(*) c from invoice
group by bc
order by c desc;

-- Q3. What are top 3 values of total invoice
select total from invoice
order by total desc limit 3;

/* Q4. Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
       Write a query that returns one city that has the highest sum of invoice totals.
	   Return both the city name & sum of all invoice totals */
select billing_city, sum(total) Invoice_total from invoice
group by billing_city
order by Invoice_total desc limit 1;

/* Q5: Who is the best customer? The customer who has spent the most money will bse declared the best customer. 
	   Write a query that returns the person who has spent the most money.*/
select c.customer_id,concat(first_name, ' ',last_name) Full_name, sum(total)  total_spending  from customer c
join invoice i on c.customer_id = i.customer_id
group by c.customer_id,Full_name
order by total_spending DESC limit 1;

/*Question set 2- Moderate*/

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
	   Return your list ordered alphabetically by email starting with A. */
select distinct email,first_name, last_name from customer c
join invoice i on c.customer_id = i.customer_id 
join invoice_line il on i.invoice_id = il.invoice_id
where il.track_id in(select track_id from track join genre on track.genre_id = genre.genre_id where genre.name like 'Rock')
order by email;
																 -- OR --
select distinct email,first_name, last_name from customer c
join invoice i on c.customer_id = i.customer_id 
join invoice_line il on i.invoice_id = il.invoice_id
join track on il.track_id = track.track_id
join genre on track.genre_id = genre.genre_id
where genre.name like 'Rock'
order by email;

/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
	   Write a query that returns the Artist name and total track count of the top 10 rock bands. */
select a.name, count(a.name) from artist a
join album1 on a.artist_id = album1.artist_id
join track t on album1.album_id = t.album_id
join genre g on t.genre_id = g.genre_id
where g.name like 'Rock'
group by a.name
order by count(a.name) desc
limit 10; 

/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */
select name, milliseconds from (select name, milliseconds, avg(milliseconds) over() ttt from track t) tt
where milliseconds > ttt
order by milliseconds desc;
											-- OR --
select name, milliseconds from track
where milliseconds > (select avg(milliseconds) from track)
order by milliseconds desc;

/*Question set 3- Advance*/

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */
WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album1 ON album1.album_id = track.album_id
	JOIN artist ON artist.artist_id = album1.artist_id
	GROUP BY 1,2
	ORDER BY 3 DESC
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album1 alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

WITH popular_genre AS 
(
    SELECT customer.country, genre.name, COUNT(invoice_line.quantity) AS Purchases, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 1,2
	ORDER BY 1 ASC, 3 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1;

/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

WITH cte as 
(
	select country, first_name, last_name, SUM(total) AS amount_spent,
	ROW_NUMBER() OVER(PARTITION BY country ORDER BY SUM(total) DESC) AS RowNo
	from customer
	join invoice on invoice.customer_id = customer.customer_id
	group by 1,2,3
	order by 1 asc, 4 desc
    )
select * from cte where rowno <=1
