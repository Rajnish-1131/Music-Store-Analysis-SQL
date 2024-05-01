--Q1. Who is teh senior most employee based on job title?

SELECT * FROM EMPLOYEE
ORDER BY levels desc
Limit 1

--Q2. Which countries have the most Invoices?

Select count(*) as c, billing_country from invoice
Group by billing_country
Order by c desc

--Q3. What are the top 3 vales of total invoice

Select total from invoice
Order by total desc
Limit 3

--Q4.Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals

Select billing_city, sum(total) as invoice_total from invoice
Group by billing_city
Order by invoice_total desc
Limit 1

--Q5.Who is the best customer? The customer who has spent the most money will be declared the best customer. Write a query that returns the person who has spent the most money

Select customer.customer_id, customer.first_name, customer.last_name, sum(invoice.total) as total
From customer
JOIN invoice on customer.customer_id = invoice.customer_id
Group by customer.customer_id
Order by total DESC
Limit 1

--Q6.Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
--Return your list ordered alphabetically by email starting with A

Select distinct email, first_name, last_name 
From customer
JOIN invoice on customer.customer_id = invoice.customer_id
JOIN invoice_line on invoice.invoice_id = invoice_line.invoice_id
Where track_id in(
	select track_id from track
	Join genre on track.genre_id = genre.genre_id
	Where genre.name LIKE 'Rock'
)
Order by email;

--Q7.Let's invite the artists who have written the most rock music in our dataset. 
--Write a query that returns the Artist name and total track count of the top 10 rock bands

Select artist.artist_id, artist.name, count(artist.artist_id) as number_of_songs
From track
Join album on album.album_id = track.album_id
Join artist on artist.artist_id = album.artist_id
Join genre on genre.genre_id = track.genre_id
Where genre.name LIKE 'Rock'
Group by artist.artist_id
Order by number_of_songs DESC
LIMIT 10;

--Q8.Return all the track names that have a song length longer than the average song length. Return the Name and Milliseconds for each track. 
--Order by the song length with the longest songs listed first

Select name, milliseconds
From track
Where milliseconds > (
	Select avg(milliseconds) as avg_track_length
	from track)
Order by milliseconds desc

--Q9.Find how much amount spent by each customer on best selling artist? 
--Write a query to return customer name, artist name and total spent

With best_selling_artist AS (
	Select artist.artist_id as artist_id, artist.name as artist_name,
	Sum(invoice_line.unit_price * invoice_line.quantity) as total_sales
	From invoice_line
	Join track on Track.track_id = invoice_line.track_id
	Join album on album.album_id = track.album_id
	Join artist on artist.artist_id = album.artist_id
	Group by 1
	Order by 3 desc
	Limit 1
)

Select c.customer_id, c.first_name, c.last_name, bsa.artist_name,
Sum(il.unit_price * il.quantity) as amount_spent
From invoice i
Join customer c on c.customer_id = i.customer_id
Join invoice_line il on il.invoice_id = i.invoice_id
Join track t on t.track_id = il.track_id
Join album alb on alb.album_id = t.album_id
Join best_selling_artist bsa on bsa.artist_id = alb.artist_id
Group by 1,2,3,4
Order by 5 desc;

--Q10.We want to find out the most popular music Genre for each country. 
--We determine the most popular genre as the genre with the highest amount of purchases. 
--Write a query that returns each country along with the top Genre. 
--For countries where the maximum number of purchases is shared return all Genres

/* Method 1: Using CTE */

WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1


/* Method 2: : Using Recursive */

WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;


--Q11.Write a query that determines the customer that has spent the most on music for each country. 
--Write a query that returns the country along with the top customer and how much they spent. 
--For countries where the top amount spent is shared, provide all customers who spent this amount

/* Method 1: using CTE */

WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1


/* Method 2: Using Recursive */

WITH RECURSIVE 
	customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;
