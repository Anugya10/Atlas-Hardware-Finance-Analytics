
#Task-1 
/*For making the financial report of FY2021 Croma India and Atlas Hardware Wants to generate a report of individual 
product sales (aggregated every month at the product code level). So Atlas Hardware can track individual product sales
and run further product analysis on it in Excel.
Which includes:- 
Month, 
Product Name, 
Variant(product's variants), 
Sold Quantity, 
Gross Price Per Item, 
Gross Price Total

Step-1 In this step, we extract the year from the date and add 4 months with the help of the date_add function and create a new function 
called get_fiscal_year for future reference and for using the date as per fiscal year context.*/

# To find the customer 'Croma' from the dataset
Select * 
from gdb0041.dim_customer
where customer like "%croma%" and 
market = "India";

 # To find the customer = croma by customer_code from the dataset for FY = 2021
Select * 
from gdb0041.fact_sales_monthly
Where customer_code = 90002002 and 
Year(date) = 2021;

# For reusing the get_fiscal_year and get_fiscal_quarter columns I have created the functions of them

CREATE DEFINER=`root`@`localhost` FUNCTION `get_fiscal_year`(
	calendar_date Date
) RETURNS int
    DETERMINISTIC
BEGIN
    declare fiscal_year int;
    set fiscal_year = Year(date_add(calendar_date, interval 4 month));
    return fiscal_year;
END;

CREATE DEFINER=`root`@`localhost` FUNCTION `get_fiscal_quarter`(
	calendar_date date
    ) RETURNS char(2) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
	declare m tinyint;
    declare qtr char(2);
    set m = month(calendar_date);
    
    case 
        when m in (9, 10, 11) then
        set qtr = "Q1";
        when m in (12, 1, 2) then
        set qtr = "Q2";
        when m in (3, 4, 5) then
        set qtr = "Q3";
        else 
        set qtr = "Q4";
	end case;
RETURN qtr;
END;

# By creating get_fiscal_year and get_fiscal_quarter function manually 
Select * 
from fact_sales_monthly
Where customer_code = 90002002 and
      get_fiscal_year(date)=2021 and
      get_fiscal_quarter(date) = "Q1"
order by date asc;

# Product Sales Aggregated Transactions for getting the product name, and variant for FY = 2021
Select 
      s.date, s.product_code, 
      p.product, p.variant, 
      s.sold_quantity
from fact_sales_monthly s
join dim_product p 
on 
	 s.product_code = p.product_code
Where 
     customer_code = 90002002 and
     get_fiscal_year(date)=2021 and
     get_fiscal_quarter(date) = "Q1"
order by date asc
limit 1000000;

# Gross Monthly Total Sales Report: Transactions for getting the Gross Price Per Item and Gross Price Total
Select 
      s.date, s.product_code, 
      p.product, p.variant, 
      s.sold_quantity, 
      Round(g.gross_price, 2) as gross_price,
      Round(g.gross_price * s.sold_quantity, 2) as gross_price_total
from fact_sales_monthly s
join dim_product p 
on 
	 s.product_code = p.product_code
join fact_gross_price g 
on 
     g.product_code = s.product_code and
     g.fiscal_year = get_fiscal_year(s.date)
Where customer_code = 90002002 and
      get_fiscal_year(date)=2021 and
      get_fiscal_quarter(date) = "Q1"
order by date Asc
limit 1000000;

# Task-2 
/*As a product owner, I need an aggregate monthly gross sales report of Croma India Customers so that the product owner can track how 
much sales this particular customer is generating for Atlas and manage our relationships accordingly.
The report should have the following fields,
1. Month,
2. Total Gross sales amount to Croma India in this month */

Select 
       s.date, 
       Round(Sum(g.gross_price*s.sold_quantity),2) as Total_gross_sales
from fact_sales_monthly s
join fact_gross_price g 
on 
   g.product_code = s.product_code and
   g.fiscal_year = get_fiscal_year(s.date) 
where customer_code = 90002002
group by s.date
order by s.date asc;

/* Generate a yearly report for Croma India where there are two columns
1. Fiscal Year
2. Total Gross Sales Amount in that year from Croma*/

Select 
     get_fiscal_year(date) as fiscal_year, 
     round(sum(g.gross_price*sold_quantity), 2) as yearly_sales
from fact_sales_monthly s
Join fact_gross_price g
on 
     s.product_code = g.product_code
     and get_fiscal_year(s.date) = g.fiscal_year
where
     customer_code = 90002002
group by get_fiscal_year(date)
order by fiscal_year;

# Created Stored Procedure for finding monthly gross sales reports for any customer
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_monthly_gross_sales_for_customer`(
           in_customer_codes TEXT 
)
BEGIN
      Select 
       s.date, 
       Round(Sum(g.gross_price*s.sold_quantity),2) as Total_gross_sales
from fact_sales_monthly s
join fact_gross_price g 
on 
   g.product_code = s.product_code and
   g.fiscal_year = get_fiscal_year(s.date) 
where 
     find_in_set(s.customer_code, in_customer_codes) > 0
group by s.date
order by s.date asc;
END;

# Created Stored Procedure to find the market badge if product sales above 5 million will be considered as GOLD
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_market_badge`(
	 IN in_market varchar(45),
	 IN in_fiscal_year year,
	 OUT out_badge varchar(45)
)
BEGIN
     declare qty int default 0;
     
     # set default market to be India 
     if in_market = "" then
          set in_market = "India";
	 end if;
     
     # retrieve total qty for a given market + Fiscal_year
     Select 
          Sum(s.sold_quantity) as Total_qty
     From fact_sales_monthly s
     Join dim_customer c
     on s.customer_code = c.customer_code 
     Where 
          get_fiscal_year(s.date) = in_fiscal_year
          and c.market = in_market
     Group by market;
     
     # dtermine market badge
     if qty > 5000000 then 
         set out_badge = "Gold";
	 else
         set out_badge = "silver";
	 end if;
END;

# Task - 3 
/*As a product owner, I want a report for top markets, products, and customers by net sales for a given financial year so that I 
can have a holistic view of our financial performance and can take appropriate actions to address any potential issues.
We will probably write a stored procedure for this as will need this report going forward as well.*/

# After EXPLAIN ANALYZE of the query found get_fiscal_year() takes lots of time.
# One solution is to make a dim_date table so the fiscal year can be easily mapped and for getting the pre-invoice discount percentage in the table
Select 
      s.date, s.product_code, 
      p.product, p.variant, s.sold_quantity, 
      Round(g.gross_price, 2) as gross_price,
	  Round(g.gross_price * s.sold_quantity, 2) as gross_price_total, 
      pre.pre_invoice_discount_pct
from fact_sales_monthly s
join 
     dim_product p 
     on s.product_code = p.product_code
join 
     dim_date d
     on d.calendar_date = s.date
join 
	 fact_gross_price g 
     on s.product_code = g.product_code and 
     g.fiscal_year = d.fiscal_year
join 
     fact_pre_invoice_deductions pre
     on pre.customer_code = s.customer_code
     and pre.fiscal_year = d.fiscal_year
Where 
     d.fiscal_year = 2021 
limit 100000;

/* After adding the created table the query where took 14 seconds to fetch the data but by making one table called dim_date and join 
with another table, the query took only 5.6 seconds to fetch the data.
To create a new table we have to select the create table option from the table menu then enter the required columns
and we can import the Excel or CSV file from the computer also.*/

# Query Performance solution-2  
# We can add the fiscal_year column into the fact_sales_monthly so we dont have to join another table with the query

Select 
      s.date, 
      s.product_code, 
      p.product, p.variant, 
      s.sold_quantity, 
      Round(g.gross_price, 2) as gross_price,
	  Round(g.gross_price * s.sold_quantity, 2) as gross_price_total, 
      pre.pre_invoice_discount_pct
from fact_sales_monthly s
join dim_product p 
     on s.product_code = p.product_code
join fact_gross_price g 
     on s.product_code = g.product_code and 
     g.fiscal_year = s.fiscal_yrs
join fact_pre_invoice_deductions pre
     on pre.customer_code = s.customer_code and 
     pre.fiscal_year = s.fiscal_yrs
Where 
     s.fiscal_yrs = 2021 
limit 100000;

# Incorporating pre_invoice_discount_pct
with cte1 as (SELECT  
	s.date, s.customer_code, s.product_code, 
    c.market,
    p.product, p.variant, s.sold_quantity,
    g.gross_price,
    round(g.gross_price*s.sold_quantity,2) as gross_price_total,
    pre.pre_invoice_discount_pct
from
fact_sales_monthly s
join dim_customer c
on
	s.customer_code = c.customer_code
join dim_product p 
on 	
	s.product_code = p.product_code
join fact_gross_price g
on 
	g.product_code = s.product_code and
	g.fiscal_year = s.fiscal_yrs
join fact_pre_invoice_deductions pre
on 
	s.customer_code = pre.customer_code and
    pre.fiscal_year = s.fiscal_yrs
where 
	s.fiscal_yrs =2021
order by date 
limit 1000000)
select *,
(1 - pre_invoice_discount_pct) * gross_price_total as net_invoice_sales
from cte1;

# We have many calculations coming up so to simplify things 
# We are converting this cte as a view
	
select *,
(gross_price_total - gross_price_total*pre_invoice_discount_pct) as net_invoice_sales
from sales_preinv_discount; #view

# For calculating the Post_invoice_discount_pct and Net sales with the view called sales_preinv_discount

select *,
       sales_preinv_discount
       (1 - pre_invoice_discount_pct)* gross_price_total as Net_invoice_Sales, 
       (po.discounts_pct + po.other_deductions_pct) as post_invoice_discount_pct
from sales_preinv_discount s
join fact_post_invoice_deductions po
on
        s.date = po.date and
        s.product_code = po.product_code and
        s.customer_code = po.customer_code;
        
Select *,
       (1 - post_invoice_discount_pct) * net_invoice_sales as net_sales
from sales_postinv_discount;

#created views for sales_preinv_discounts, sales_postinv_discounts, gross_sales and net sales

# Find out Top 5 Markets, Customers, and Products by Net Sales in Millions
	
Select 
      Market,
      Round(Sum(Net_sales) / 1000000,2) as Net_sales_mln
      From Net_sales
Where fiscal_yrs = 2021
group by market
order by Net_sales_mln desc
Limit 5;
      
Select 
      c.customer,
      Round(Sum(Net_sales) / 1000000,2) as Net_sales_mln
      From Net_sales s
      join dim_customer c 
      on s.customer_code = c.customer_code
Where fiscal_yrs = 2021
group by c.customer
order by Net_sales_mln desc
Limit 5;

Select 
      p.Product,
      Round(Sum(Net_sales) / 1000000,2) as Net_sales_mln
      From Net_sales s
      join dim_product p
      on s.product_code = p.product_code
Where fiscal_yrs = 2021
group by p.product
order by Net_sales_mln desc
Limit 5;

# Market share

with cte1 as (select
	c.customer,
	round(sum(net_sales)/1000000,2) as Net_sales_Millions
from net_sales n
join dim_customer c
on 
    n.customer_code = c.customer_code
where fiscal_yrs = 2021 
group by c.customer
)
select 
	*,
	Net_sales_Millions*100/sum(Net_sales_Millions) 
    over() as Market_share
from cte1
order by Net_sales_Millions desc;

# Market share of customers per region
with cte1 as (select
	c.customer, c.region,
	round(sum(net_sales)/1000000,2) as Net_sales_Millions
from
	net_sales n
	join dim_customer c
		on n.customer_code = c.customer_code
	where fiscal_yrs = 2021 
	group by c.customer,c.region
)
select 
	*,
	Net_sales_Millions*100/sum(Net_sales_Millions) 
    over(partition by region) as Market_share_per_region
from cte1
order by region, Net_sales_Millions desc;

# Top 3 products in each division - using dense_rank
	
with cte1 as (select
	p.division,
    p.product,
    sum(sold_quantity)as total_quantity
from fact_sales_monthly s
join dim_product p
on s.product_code=p.product_code
where fiscal_year = 2021
group by product
),
cte2 as(select 
*,
dense_rank() over(partition by division order by total_quantity desc)
as drank
from cte1)
select *
from cte2
where drank<4;

# Top 2 markets in each region on gross_sales 
	
with cte1 as(select
		c.market, c.region,
		round(sum(gross_price_total)/1000000,2) as gross_sales_millions
	from gross_sales g
    join dim_customer c
    on
		c.customer_code = g.customer_code
	where fiscal_yrs =2021
	group by market),
    
    cte2 as(
    select *,
    dense_rank() over(partition by region order by gross_sales_millions desc) as drank
    from 
    cte1)
select * from cte2
where drank <3;
