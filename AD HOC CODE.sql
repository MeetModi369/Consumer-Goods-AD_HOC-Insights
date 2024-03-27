-- REQUEST 1 
-- Provide the list of markets in which customer "Atliq Exclusive" operates  its business in the APAC region

select market
from dim_customer
where customer = "Atliq Exclusive" and region = "APAC"
group by market
order by market;

-- REQUEST 2
-- What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields

With cte20 as
         ( Select Count(product_code) as Unique_Products_2020
		   From fact_manufacturing_cost as f 
		   Where cost_year=2020),
cte21 as
         (Select Count(product_code) as Unique_Products_2021
          From fact_manufacturing_cost as f 
          Where cost_year=2021)
Select *,
		Round((Unique_Products_2021-Unique_Products_2020)*100/Unique_Products_2020,2) as Percentage_Chg		
From cte20
Cross Join
cte21 ;

-- Request 3 
-- Provide a report with all the unique product counts for each segment and sort 
-- them in descending order of product counts. The final output contains 2 fields

select 
       segment,
       count(distinct(product)) as product_count
from dim_product
group by segment
order by product_count desc ;

-- Request 4  
-- Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 

with cte1 as(
select 	dp.segment as A,
		count(distinct fs.product_code) as B
from fact_sales_monthly fs
join dim_product dp
on fs.product_code=dp. product_code
group by dp.segment , fs.fiscal_year
having fs.fiscal_year=2020
),

 cte2 as(
select 	dp.segment as C,
		count(distinct fs.product_code) as D
from fact_sales_monthly fs
join dim_product dp
on fs.product_code=dp. product_code
group by dp.segment, fs.fiscal_year
having fs.fiscal_year= 2021
)

select cte1.A as segment,
		cte1.B as product_code_2020,
        cte2. D as product_code_2021,
        (cte2.D-cte1.B) as difference
from cte1,cte2
where cte1.A=cte2.C;

-- Request 5
-- Get the products that have the highest and lowest manufacturing costs. 

Select 
	p.product_code,
	p.product,
	m.manufacturing_cost
From dim_product as p
Join fact_manufacturing_cost as m
Using(product_code)
Where 
	manufacturing_cost=(Select Max(manufacturing_cost) from fact_manufacturing_cost) or 
	manufacturing_cost=(Select Min(manufacturing_cost) from fact_manufacturing_cost)
Order By manufacturing_cost DESC ;

-- Report 6
-- Generate a report which contains the top 5 customers who received an average 
-- high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
-- The final output contains these fields , customer_code , customer , average_discount_percentage 

SELECT a.customer_code ,
       b.customer,
       CONCAT(ROUND(AVG(pre_invoice_discount_pct)*100,2),'%') AS Average_discount_percentage
FROM fact_pre_invoice_deductions AS a
INNER JOIN 
dim_customer AS b
ON a.customer_code = b.customer_code
WHERE market = 'India'
AND fiscal_year = 2021
GROUP BY customer, customer_code
ORDER BY AVG(pre_invoice_discount_pct) DESC
LIMIT 5;

-- Report 7 
-- Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . 
-- This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
-- The final report contains these columns: Month Year , Gross sales Amount

with cte1 as (
select 
	monthname(s.date) as A,
    year(s.date) as B ,
    s.fiscal_year,
    (g.gross_price*s.sold_quantity) as C
from fact_sales_monthly s
join fact_gross_price g on s.product_code=g.product_code
join dim_customer c on s.customer_code=c.customer_code
where c.customer="Atliq Exclusive")

select A as month,B as Year, round(sum(C),2) as Gross_sales_amount from cte1
group by month,Year
order by year;

-- Report 8
-- In which quarter of 2020, got the maximum total_quantity_sold? 
-- The final output contains these fields sorted by the total_quantity_sold: Quarter, total_quantity_sold

SELECT CASE
		WHEN MONTH(date) IN (9,10,11) THEN 'Q1'                          /* Atliq hardware has september as it's first financial month*/
		WHEN MONTH(date) IN (12,1,2) THEN 'Q2'
		WHEN MONTH(date) IN (3,4,5) THEN 'Q3'
		ELSE 'Q4'
		END AS quarters,
	   round(SUM(sold_quantity)/1000000,2 ) AS total_quantity_sold_mln
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY quarters
ORDER BY total_quantity_sold DESC;

-- Request 9
-- Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
-- The final output contains these fields: channel, gross_sales_mln, percentage

with cte as
(
select
    c.channel,
    round(sum(s.sold_quantity*g.gross_price)/1000000,2) as gross_sales_mln
from dim_customer as c
join fact_sales_monthly as s
on c.customer_code=s.customer_code
join fact_gross_price as g
on g.product_code=s.product_code and
    g.fiscal_year=s.fiscal_year
where s.fiscal_year=2021
group by channel
order by gross_sales_mln desc )
select *,
    CONCAT(round(gross_sales_mln*100/sum(gross_sales_mln) over(),2),"%")as percentage
from cte;

-- Request 10
-- Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
-- The final output contains these fields : division, product_code, product , total_sold_quantity, rank_order

with cte1 as(select
		p.division,
        s.product_code,
        p.product,
        sum(s.sold_quantity) as total_sold_quantity,
        rank() over(partition by division order by sum(s.sold_quantity) desc) as rank_order 
from fact_sales_monthly s
join dim_product p on s.product_code=p.product_code
where s.fiscal_year=2021
group by p.product,division,s.product_code)

select * from cte1
where rank_order in (1,2,3)

