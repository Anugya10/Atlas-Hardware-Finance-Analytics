/*Task-1 For making the financial report of FY2023 of Croma India and Croma Wants to generate a report of individual 
product sales (aggregated on a monthly basis at the product code level). So the company can track individual product sales
and run further product analysis on it in excel.
Which includes:- Month, Product Name, Variant(product's variants), Sold Quantity, Gross Price Per Item, Gross Price Total
First session - In this session, we extract the year from the date and add 4 month with the help of date_add function and create a new function 
called get_fiscal_year for the future reference and for using the date as per fiscal year context. We also add deterministic which means 
it will give us the value always which we want irrespect of time and not deterministic is used for when we want the data as per
the time changes. We also add one function */

-- To find the customer 'Croma' from the dataset
Select * from gdb0041.dim_customer
where customer like "%croma%" and market = "India";

 /*As we are finding the product sales on the aggregated basis, so we will use the fact sales monthly table from the dataset
and for the year 2021*/
Select * from gdb0041.fact_sales_monthly
Where customer_code = 90002002 and Year(date) = 2021;

-- By creating get_fiscal_year and get_fiscal_quarter function manually 
Select * from fact_sales_monthly
Where customer_code = 90002002 and
get_fiscal_year(date)=2021 and
get_fiscal_quarter(date) = "Q1"
order by date asc;

-- Gross Sales Report: Monthly Product Transactions for getting the product name, and variant
Select s.date, s.product_code, p.product, p.variant, s.sold_quantity
from fact_sales_monthly s
join dim_product p on s.product_code = p.product_code
Where customer_code = 90002002 and
get_fiscal_year(date)=2021 and
get_fiscal_quarter(date) = "Q1"
order by date asc
limit 1000000;

-- Gross Sales Report: Monthly Product Transactions for getting the Gross Price Per Item and Gross Price Total
Select s.date, s.product_code, p.product, p.variant, s.sold_quantity, Round(g.gross_price, 2) as gross_price,
Round(g.gross_price * s.sold_quantity, 2) as gross_price_total
from fact_sales_monthly s
join dim_product p 
on s.product_code = p.product_code
join fact_gross_price g 
on s.product_code = g.product_code and g.fiscal_year = get_fiscal_year(s.date)
Where customer_code = 90002002 and
get_fiscal_year(date)=2021 and
get_fiscal_quarter(date) = "Q1"
order by date asc
limit 1000000;

/* Task-2 As a product owner, I need an aggregate monthly gross sales report for Croma India Customer so that I can track how 
much sales this particular customer is generating for AtliQ and manage our relationships accordingly.
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

-- Exercise --
/* Generate a yeraly report for Croma India where there are two columns
1. Fiscal Year
2. Total Gross Sales Amount in that year from Croma*/

Select 
     get_fiscal_year(date) as fiscal_year, 
     round(sum(g.gross_price*sold_quantity), 2) as Total_gross_yearly_sales_amount
from fact_sales_monthly s
Join fact_gross_price g
on 
     s.product_code = g.product_code
     and get_fiscal_year(s.date) = g.fiscal_year
where
     customer_code = 90002002
group by get_fiscal_year(date)
order by fiscal_year;


/* Task - 3 
As a product owner, I want a report for top markets, products, customers by net sales for a given financial year so that I 
can have a holistic view of our financial performance and can take appropriate actions to address any potential issues.
We will probably write stored procedure for this as will need this report going forward as well.*/

-- for getting the pre-invoice discount price in the table
Select 
      s.date, s.product_code, p.product, p.variant, s.sold_quantity, Round(g.gross_price, 2) as gross_price,
	  Round(g.gross_price * s.sold_quantity, 2) as gross_price_total, pre.pre_invoice_discount_pct
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

/* For optimize the query where it took 14 seconds to fetching the data but by making one table called dim_date and join 
with the query the query took only 1.5 seconds for fetching the data.
For creating a new table we have to select the create table option from the table menu then enter the required columns
and we can import the excel or csv file from the computer also.
Duration and fetch are the two key metrics to understand performance of a query
Duration is the time taken for a query to get executed
Fetch is the time taken to retrieve the data from the database server
EXPLAIN ANALYZE clause will help one to understand the query performance time*/

/* Performance option-2 We can add fiscal_year column into the fact_sales_monthly so we dont have to join another table 
with the query*/

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

