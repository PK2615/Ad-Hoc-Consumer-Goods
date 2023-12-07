SELECT * FROM gdb023.dim_customer;

-- ------Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region---
select market from dim_customer
where customer = "Atliq Exclusive" and region = "APAC";

-- ------What is the percentage of unique product increase in 2021 vs. 2020?--------------------------------------
with cte1 as (
select count(distinct product_code) as unique_product_2020
from fact_gross_price
where fiscal_year = 2020),
cte2 as (
select count(distinct product_code) as unique_product_2021
from fact_gross_price
where fiscal_year=2021)
select *,
round((unique_product_2021-unique_product_2020)*100/unique_product_2020,2) as pct_change
from cte2
cross join cte1;




-- --Provide a report with all the unique product counts for each segment and sort them in ---------------------
-- ------------------------descending order of product counts--------------------------------------------------
select segment,
 count(distinct product_code) as product_count
 from dim_product
 group by segment
 order by product_count desc;
 
 -- ------Which segment had the most increase in unique products in 2021 vs 2020?-------------------------------
 with cte1 as (
select p.segment, count(distinct s.product_code) as unique_product_2020
from fact_sales_monthly s
join dim_product p
on p.product_code=s.product_code
where fiscal_year = 2020
group by p.segment),
cte2 as (
select p.segment, count(distinct s.product_code) as unique_product_2021
from fact_sales_monthly s
join dim_product p
on p.product_code=s.product_code
where fiscal_year=2021
group by p.segment),
cte3 as(
select p20.segment, p20.unique_product_2020 as product_count_2020, p21.unique_product_2021 as product_count_2021,
(p21.unique_product_2021-p20.unique_product_2020) as difference
from cte1 p20
join cte2 p21
on p20.segment= p21.segment)
select segment, product_count_2020, product_count_2021, difference
from cte3
order by difference Desc;
 
 -- ---------Get the products that have the highest and lowest manufacturing costs------------------------------
 
 select m.product_code, p.product, m.manufacturing_cost
 from fact_manufacturing_cost m
 join dim_product p
 on m.product_code=p.product_code
 where manufacturing_cost in ((select max(m.manufacturing_cost) from fact_manufacturing_cost),
 (select min(m.manufacturing_cost) from fact_manufacturing_cost))
 order by m.manufacturing_cost desc;
 
 -- ----------Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct
 -- --------------for the fiscal year 2021 and in the Indian market.-------------------------
 
 select c.customer_code,c.customer, 
 round(avg(f.pre_invoice_discount_pct)*100,2) as avg_discount_pct
 from dim_customer c
 join fact_pre_invoice_deductions f
 on c.customer_code=f.customer_code
 where fiscal_year = 2021 and market= "India"
 group by customer, customer_code
 order by avg_discount_pct desc
 limit 5;
 
 --  --Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month------
 select monthname(s.date) as Month, year(s.date) as Year,
 concat((round(SUM(g.gross_price*s.sold_quantity)/1000000,2)),"M") as Gross_Sales_Amount
 from fact_gross_price g
 join fact_sales_monthly s
 on g.product_code=s.product_code and 
 g.fiscal_year=s.fiscal_year
 join dim_customer c
 on c.customer_code=s.customer_code
 where customer= "Atliq Exclusive"
 group by Month, Year
 order by Year;
 
 -- --In which quarter of 2020, got the maximum total_sold_quantity?-------------------------------------------
 SELECT 
    QUARTER(DATE_ADD(date, INTERVAL 4 MONTH)) AS quarter,
    SUM(sold_quantity) AS total_sold_quantity
FROM
    fact_sales_monthly
WHERE
    fiscal_year = '2020'
GROUP BY quarter
order by total_sold_quantity desc;
 
 -- ---Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
 with cte_1 as (
SELECT 
    dc.channel as channel,
    (s.sold_quantity * gp.gross_price) AS gross_sales  
FROM
    fact_sales_monthly s
        JOIN
    fact_gross_price gp ON s.product_code = gp.product_code
        AND s.fiscal_year = gp.fiscal_year
        JOIN
    dim_customer dc ON s.customer_code = dc.customer_code
WHERE
    s.fiscal_year = '2021'
),
cte_2 as (	
	select sum(gross_sales ) as total_gross_sales_mln
	from cte_1
)
	select channel,sum(gross_sales) as gross_sales_mln,sum((gross_sales /total_gross_sales_mln)*100) as percentage
    from cte_1,cte_2
    group by channel
    order by gross_sales_mln desc;
 
 -- Get the Top3 products ineach division that have a high total_sold_quantity inthe fiscal_year 2021?----------
 
 with cte1 as(
 select p.division, p.product_code, p.product, sum(s.sold_quantity) as total_sold_quantity
 from dim_product p
 join fact_sales_monthly s
 on s.product_code=p.product_code
 where fiscal_year = 2021
 group by p.division, p.product_code, p.product),
 
 cte2 as(
 select *, dense_rank() over( partition by division order by  total_sold_quantity desc) as rank_order
 from cte1)
 
 select * from cte2 
 where rank_order<=3

 
