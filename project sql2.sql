-- Segment 1: Database - Tables, Columns, Relationships
-- -	What are the different tables in the database and how are they connected to each other in the database?
select table_name,table_rows from information_schema.tables where table_schema = 'PROJECT_NS;';
CREATE DATABASE PROJECT_NS;
USE PROJECT_NS;
SHOW tables;
SELECT * FROM movies;
SELECT * FROM genre;
SELECT * FROM director_mapping;
SELECT * FROM role_mapping;
SELECT * FROM names;
SELECT * FROM ratings;

-- Segment 1: Database - Tables, Columns, Relationships
-- -	What are the different tables in the database and how are they connected to each other in the database?
SHOW TABLES;
DESCRIBE movies ;
DESCRIBE director_mapping;
DESCRIBE genre;
DESCRIBE names;
DESCRIBE ratings;
DESCRIBE role_mapping;


-- -	Find the total number of rows in each table of the schema.

select count(*) as total_rows from movies ;
select count(*) as total_rows from director_mapping ;
select count(*) as total_rows from  genre ;
select count(*) as total_rows from  role_mapping ;
select count(*) as total_rows from  names ;
select count(*) as total_rows from  ratings ;

--- -- 	Identify which columns in the movie table have null values
select column_name from information_schema.columns
where table_name = 'movies'
and table_schema = 'PROJECT_NS'
and is_nullable = 'YES';

select count(*) from movies
where id is null;
    
  --   Segment 2: Movie Release Trends
  
  -- -	Determine the total number of movies released each year and analyse the month-wise trend.
  select year,count(id) as movies
from movies
group by year
order by year;

select year, 
month(str_to_date(date_published,'%M/%D/%Y')) as month_no, 
count(id) as movies
from movies
group by year,month_no
order by year,month_no;

-- Calculate the number of movies produced in the USA or India in the year 2019.
select count(id) as number_of_movies
from movies
where year = 2019
and (country like '%USA%'
or country like '%India%');

-- Segment 3: Production Statistics and Genre Analysis

-- -	Retrieve the unique list of genres present in the dataset.
select distinct genre from genre ;

-- -	Identify the genre with the highest number of movies produced overall.
select genre , count(*) as number_of_movies 
from genre 
group by genre 
order by 2 desc
limit 1;

-- -	Determine the count of movies that belong to only one genre.
select count(movie_id) from
(select movie_id,count(distinct genre) as genres
from genre
group by movie_id)t
where genres = 1;

-- -	Calculate the average duration of movies in each genre.
select g.genre , avg(m.duration) as avg_durarion 
from genre g left join movies m on g.movie_id = m.id 
group by 1; 

-- -	Find the rank of the 'thriller' genre among all genres in terms of the number of movies produced.
with cte as (select genre , count(*) as cnt ,
dense_rank() over(order by count(*)  desc) as rank_
from genre 
group by genre 
order by cnt desc)
select * from cte 
where genre = 'Thriller';



-- Segment 4: Ratings Analysis and Crew Members
-- -	Retrieve the minimum and maximum values in each column of the ratings table (except movie_id).
SELECT 
MIN(avg_rating) AS MIN_AVG_RATING,
MAX(avg_rating) AS MAX_AVG_RATING,
MIN(total_votes) AS MIN_TOTAL_VOTES, 
MAX(total_votes) AS MAX_TOTAL_VOTES,
min(median_rating) AS MIN_MEDIAN_RATING,
MAX(median_rating) AS MAX_MEDIAN_RATING
FROM ratings;

-- -	Identify the top 10 movies based on average rating.
SELECT title , avg_rating FROM movies a 
LEFT JOIN ratings b on a.id = b.movie_id
where movie_id is not null 
order by avg_rating desc 
limit 10 ;

-- -	Summarise the ratings table based on movie counts by median ratings.
SELECT MEDIAN_RATING,COUNT(MOVIE_ID) AS MOVIE_COUNT
FROM RATINGS
GROUP BY MEDIAN_RATING
ORDER BY MOVIE_COUNT DESC;

-- -	Identify the production house that has produced the most number of hit movies (average rating > 8).
select a.production_company , a.title , b.avg_rating 
from 
movies a 
inner  join ratings b on a.id = b.movie_id
where b.avg_rating > 8 and a.production_company is not null
order by 3 desc;
         
-- -Determine the number of movies released in each genre during March 2017 in the USA with more than 1,000 votes
select g.genre , m.date_published , COUNT(*) as count FROM genre g 
join movies m on g.movie_id = m.id
join ratings r on r.movie_id = m.id
where m.year = 2017 and  
month(str_to_date(m.date_published,'%m/%d/%Y')) = 3  and 
m.country = 'USA' AND r.total_votes > 1000 
GROUP BY g.genre , m.date_published 
order by m.date_published;

-- -	Retrieve movies of each genre starting with the word 'The' and having an average rating > 8.
select m.title , g.genre , r.avg_rating from movies m 
join genre g on m.id = g.movie_id 
join ratings r on g.movie_id = r.movie_id
where m.title like 'The%' and r.avg_rating > 8;


-- Segment 5: Crew Analysis-- 

-- --- - -	Identify the columns in the names table that have null values.
select count(*) id from names where id is null;
select count(*) name from names where name is null;
select count(*) height from names where height is null;
select count(*) date_of_birth from names where date_of_birth is null;
select count(*) known_for_movies from names where known_for_movies is null;

-- -	Determine the top three directors in the top three genres with movies having an average rating > 8.
with topgenres as (
       select g.genre , avg(r.avg_rating) as avg_rating from genre g 
       inner join ratings r on g.movie_id = r.movie_id
       group by g.genre
       having avg(r.avg_rating) > 8
       order by 2 desc 
       limit 3 ),
topdirector as ( 
       select dm.name_id , count(dm.movie_id) as moviecnt 
       from director_mapping dm 
       inner join movies m on dm.movie_id = m.id
       group by name_id
       order by count(dm.movie_id) desc 
       limit 3 )
       
       select n.name , td.moviecnt from names n
       join topdirector td on n.id = td.name_id
       order by td.moviecnt desc;
       
       
     --   -	Find the top two actors whose movies have a median rating >= 8.
with top_actors as
(select name_id,count(movie_id) as num_movies
from role_mapping 
where category = 'actor'
and movie_id in (select movie_id from ratings where median_Rating >= 8)
group by name_id
order by num_movies desc
limit 2)

select b.name as actors,num_movies 
from top_actors a
join names b
on a.name_id = b.id
order by num_movies desc;

-- -	Identify the top three production houses based on the number of votes received by their movies.
select m.title , m.production_company as production_houses , r.total_votes ,
dense_rank() over(order by r.total_votes desc) as rnk
from movies m 
inner join ratings r on m.id = r.movie_id 
order by 3 desc 
limit 3 ;

-- -	Rank actors based on their average ratings in Indian movies released in India.
SELECT
    m.id,
    n.name AS movie_name,
    r.avg_rating,
    DENSE_RANK() OVER (ORDER BY r.avg_rating DESC) AS _rank
FROM
    role_mapping rm
    INNER JOIN ratings r ON rm.movie_id = r.movie_id
    INNER JOIN movies m ON r.movie_id = m.id
    INNER JOIN names n on rm.name_id = n.id
WHERE
    m.country like '%India%' AND rm.category = 'actor';
    
-- -	Identify the top five actresses in Hindi movies released in India based on their average ratings.
select n.name as actress_name , r.avg_rating from ratings r 
inner join movies m on r.movie_id = m.id 
inner join role_mapping rm on m.id = rm.movie_id 
inner join names n on rm.name_id = n.id 
where country = 'India' and category = 'actress' and languages like '%Hindi%' 
order by 2 desc 
limit 5 ;

-- Segment 6: Broader Understanding of Data

-- Classify thriller movies based on average ratings into different categories.
select title as movie_title , avg_rating ,
            case when avg_rating >= 8.0 THEN 'EXCELLENT'
                 WHEN avg_rating >= 5.0 AND avg_rating < 8.0 THEN 'GOOD'
                 WHEN avg_rating >= 3.0 AND avg_rating < 5.0 THEN 'AVERAGE' 
                 ELSE 'BELOW_AVERAGE'
            END AS DIFF_CATEGORIES 
            FROM movies m
            join genre g on m.id = g.movie_id
            join ratings r on g.movie_id = r.movie_id
            where genre = 'Thriller' 
            order by avg_rating desc ;
            
-- --analyse the genre-wise running total and moving average of the average movie duration.
with cte as (
       select 
            g.genre , avg(duration) as avg_duration 
            from genre g 
            join movies m on g.movie_id = m.id 
            group by 1 
            )
select genre ,round(avg_duration,2) avg_duration,
round(sum(avg_duration) over (order by genre),2) as running_total,
round(avg(avg_duration) over (order by genre),2) as moving_avg
from cte order by genre;

-- -	Identify the five highest-grossing movies of each year that belong to the top three genres.

 with top_3_genres as (
                       select genre , count(*) as total_cnt 
                       from genre 
                       group by genre
                       order by total_cnt 
                       limit 3 ),
 main_table as ( 
				select m.* , g.genre , replace(worlwide_gross_income,'$',' ') as gross_new_income 
                from movies m 
                join genre g on m.id = g.movie_id 
                where genre in ( select genre from top_3_genres )
                )
                
   select * from              
  (select genre , title , year , worlwide_gross_income ,
  dense_rank() over(partition by genre , year order by gross_new_income desc) as rnk 
  from main_table)t 
  where rnk<=5
  order by genre , year ; 
  
  -- -	Determine the top two production houses that have produced the highest number of hits among multilingual movies.

select production_company, count(id) as hit_movie_count
from movies
where languages LIKE '%,%' 
and id in (Select movie_id from ratings where avg_rating > 8)
and production_company is not null
group by production_company
order by hit_movie_count desc
limit 2 ;

-- -	Identify the top three actresses based on the number of Super Hit movies (average rating > 8) in the drama genre.
with cte as (
           select n.name as actress_name,
                   count(*) as movie_count 
                   from role_mapping rr 
                   join ratings r on rr.movie_id = r.movie_id 
                   join genre g on r.movie_id =g.movie_id
                   join names n on rr.name_id = n.id
                   where 
                   r.avg_rating >= 8 and 
                   g.genre = 'Drama' and 
                   category = 'actress'
                   group by name 
                   order by movie_count desc)
   select  actress_name , movie_count from cte 
   order by movie_count desc 
   limit 3 ;
   
--    -	Retrieve details for the top nine directors based on the number of movies, including average inter-movie duration, ratings, and more.
-- Director id
-- Name
-- Number of movies
-- Average inter movie duration in days
-- Average movie ratings
-- Total votes
-- Min rating
-- Max rating

with top_directors as
(Select name_id as director_id,count(movie_id) as movie_count
from director_mapping group by name_id
order by movie_count desc
limit 9),

movies_summary as
(select b.name_id as director_id,a.*,avg_rating,total_votes
from movies a join director_mapping b
on a.id = b.movie_id
left join ratings c
on a.id = c.movie_id
where b.name_id in (select director_id from top_directors)),

final as
(select *, lead(date_published) over (partition by director_id order by date_published) as nxt_movie_date,
datediff(lead(date_published) over (partition by director_id order by date_published),date_published) as days_gap
from movies_summary)

select director_id,b.name as director_name,
count(a.id) as movie_count,
round(avg(days_gap),0) as avg_inter_movie_duration,
round(sum(avg_rating*total_votes)/sum(total_votes),2) as avg_movie_ratings,
sum(Total_votes) as total_votes,
min(avg_rating) as min_rating,
max(avg_rating) as max_rating,
sum(duration) as total_duration
from final a
join names b
on a.director_id = b.id
group by director_id,name
order by avg_movie_ratings desc;



-- Segment 7: Recommendations

-- -Based on the analysis, provide recommendations for the types of content Bolly movies should focus on producing.
-- Emphasize production in proven genres such as drama, romance, comedy, and action that have consistently resonated with the audience
-- Continue partnerships with directors who consistently deliver successful movies based on the analysis
--  genre, actors, actress, directors, month during the which they want to make the release 



             




            
    


 

       


















