# Atlas Hardware – Finance Analytics

## 📌 Project Overview

SQL-based finance analytics project using the **AtliQ Hardware dataset** to analyze sales, customers, products, markets, pricing, and discounts.

The project focuses on **FY2021 financial analysis** and demonstrates practical SQL techniques for generating business insights from a large dataset.

---

## 📊 Dataset

* Total records: ~5.38M
* fact_sales_monthly: ~1.3M rows
* fact_forecast_monthly: ~1.8M rows
* fact_post_invoice_deductions: ~1.4M rows
* Other fact and dimension tables

---

## 🛠️ Tools & Technologies

* MySQL
* SQL
* CTEs
* Joins
* Window Functions
* Views
* Stored Procedures
* User-Defined Functions
* Query Optimization

---

## 🎯 Business Objectives

* Generate monthly product-level sales reports.
* Analyze customer gross and net sales.
* Identify top markets, customers, and products.
* Calculate market share by customer and region.
* Rank top products within divisions.
* Identify top markets within regions.
* Optimize queries for large datasets.

---

## 💰 Financial Analysis

Calculated key financial metrics including:

* Gross Sales
* Pre-Invoice Discount
* Net Invoice Sales
* Post-Invoice Discount
* Net Sales
* Market Share

### Net Sales Calculation

```text
Gross Sales
→ Pre-Invoice Discount
→ Net Invoice Sales
→ Post-Invoice Discount
→ Net Sales
```

---

## 📈 Key Analyses

### Top Performers

* Top 5 Markets by Net Sales
* Top 5 Customers by Net Sales
* Top 5 Products by Net Sales

### Ranking Analysis

* Top 3 Products in Each Division
* Top 2 Markets in Each Region

### Market Share

Used SQL window functions to calculate:

* Overall customer market share
* Customer market share within each region

---

## ⚙️ SQL Reusability

Created reusable:

* **Functions** for fiscal year and fiscal quarter calculations
* **Stored Procedures** for customer sales and market classification
* **Views** for pre-invoice discounts, post-invoice discounts, and net sales

This reduced repetitive SQL logic and simplified financial analysis.

---

## 🚀 Query Optimization

Used `EXPLAIN ANALYZE` to identify performance bottlenecks caused by repeated fiscal-year calculations.

### Optimization

```text
Initial execution:  ~14 seconds
Optimized execution: ~5.6 seconds
Improvement:        ~60%
```

Improved performance by introducing a fiscal-year mapping through a date dimension and later storing the fiscal year directly in the sales fact table.

---

## 🧠 SQL Concepts Demonstrated

* Aggregations
* Multi-table Joins
* CTEs
* Window Functions
* DENSE_RANK()
* PARTITION BY
* Views
* Stored Procedures
* User-Defined Functions
* Query Optimization
* EXPLAIN ANALYZE

---

Built a reusable SQL-based financial analysis solution capable of analyzing **5.38M+ records** across customers, products, markets, and regions while improving query execution performance by approximately **60%**.
