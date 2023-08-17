use airbnb_amsterdam;

# load the csv files
LOAD DATA INFILE 'listings2.csv' 
INTO TABLE listings2 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

create table Reviews1 (listing_id bigint(20),id bigint(20), date varchar(255),reviewer_id bigint(20),
reviewer_name varchar(255),comments text);

LOAD DATA INFILE 'reviews.csv' 
INTO TABLE reviews1 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
IGNORE 1 LINES;

select * from  listings;



SET SQL_SAFE_UPDATES=0;

select price from listings order by price desc;
# drop the $ from price:
update listings set price=replace(price,'$',0);
update listings set price=trim(leading '0' from price);
update listings set price=replace(price,',','');
 
 
# id correction
#1- check if if all the records in "id" are correct!
with temp1 (id,listing_id,cor_id)
as
(
select id , listing_url, trim('https://www.airbnb.com/rooms/' from listing_url ) as correct_id from listings
)
select * from temp1 where id != cor_id;
#2-create new column 'correct_id':
alter table listings add correct_id bigint(20);
#3-extract the values from the ' listing_url':
update listings set correct_id = trim('https://www.airbnb.com/rooms/' from listing_url );
alter table listings modify correct_id bigint(20) after id;

# claculating the revenue acording to the booking days in 30 days starting from 06/06/2023:
#1- revenues for each rental:
with temp_table(Listing_id,host_id,host_name ,correct_price ,booked_days , revenue )
as
(
select correct_id,host_id,host_name, price ,(30-availability_30),price*(30-availability_30) from listings
)
select * from temp_table order by revenue desc ;
#2- revenues for each host:
with temp_table(Listing_id,host_id,host_name ,correct_price ,booked_days , revenue )
as
(
select correct_id,host_id,host_name, price ,(30-availability_30),price*(30-availability_30) from listings
)
select host_id,host_name,sum(revenue) as total from temp_table group by host_id order by total desc ;


# searching for bad reviews regarding cleaning: 
select reviews1.listing_id , listings.host_name,
listings.review_scores_value, count(listings.correct_id) as number_of_negative_reviews_regarding_cleaning
 from listings
inner join reviews1 on reviews1.listing_id = listings.correct_id
 where reviews1.comments like '%dirty%'
 or  reviews1.comments like '%not clean%'
 group by listings.correct_id order by number_of_negative_reviews_regarding_cleaning desc ;

 
# rentals location for map view:
select correct_id as listing_id,host_name,host_id,listing_url,property_type,latitude,longitude
 from listings;