-- SQL porfolio project.
-- download credit card transactions dataset from below link :
-- https://www.kaggle.com/datasets/thedevastator/analyzing-credit-card-spending-habits-in-india
-- import the dataset in sql server with table name : credit_card_transcations
-- change the column names to lower case before importing data to sql server.Also replace space within column names with underscore.
-- (alternatively you can use the dataset present in zip file)
-- while importing make sure to change the data types of columns. by defualt it shows everything as varchar.

-- write 4-6 queries to explore the dataset and put your findings 
USE pcredit;
ALTER TABLE credit_card_transcations
RENAME TO transactions;
SELECT *
FROM transactions;

-- solve below questions
-- 1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
SELECT SUM(amount) AS total_amount
FROM transactions;

SELECT city,SUM(amount) AS total_Sum,
(SUM(amount)/(SELECT SUM(amount) FROM transactions))*100 as percent
FROM transactions
GROUP BY city
ORDER BY total_Sum DESC
LIMIT 5 ;

-- 2- write a query to print highest spend month and amount spent in that month for each card type
WITH cte AS(
SELECT card_type, MONTH(transaction_date) AS mnth,
SUM(amount) AS totalAmount
FROM transactions
GROUP BY card_type,MONTH(transaction_date)
ORDER BY card_type,totalAmount DESC
)

SELECT * 
FROM (SELECT *,RANK() OVER (PARTITION BY card_type ORDER BY totalAmount DESC) AS rn
FROM cte) AS tab
WHERE rn=1;
-- 3- write a query to print the transaction details(all columns from the table) for each card type when
	-- it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
    WITH cte AS 
    (SELECT *, SUM(amount) OVER (PARTITION BY card_type ORDER BY transaction_date,transaction_id) AS totalSpend
    FROM transactions
    ORDER BY card_type,totalSpend DESC)
    SELECT * 
    FROM (SELECT *, RANK() OVER(PARTITION BY  card_type ORDER BY  totalSpend) as rn  
	FROM cte WHERE totalSpend >= 1000000) AS tag 
    WHERE rn=1;
    
-- 4- write a query to find city which had lowest percentage spend for gold card type

SELECT city, (SUM(amount)/(SELECT SUM(amount) FROM transactions WHERE card_type="Gold"))*100 AS perc
FROM transactions
WHERE card_type="Gold"
GROUP BY city
ORDER BY perc ASC
LIMIT 1;

-- 5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
SELECT DISTINCT exp_type
FROM transactions;

WITH cte AS
(SELECT city, exp_type,SUM(amount) AS totalAmount
FROM transactions
GROUP BY city,exp_type)

SELECT city,MAX(CASE WHEN rnasc=1 THEN exp_type END) AS low_exp,
MIN(CASE WHEN rndes=1 THEN exp_type END) AS high_exp
FROM
(SELECT *,
RANK() OVER(PARTITION BY city ORDER BY totalAmount DESC) AS rndes,
RANK() OVER(PARTITION BY city ORDER BY totalAmount ASC) AS rnasc
FROM cte) AS tag
GROUP BY city;

-- 6- write a query to find percentage contribution of spends by females for each expense type
SELECT exp_type,(SUM(CASE WHEN gender='F' THEN amount ELSE 0 END)/SUM(amount))*100 AS gen_exp
FROM transactions
GROUP BY exp_type;

-- 7- which card and expense type combination saw highest month over month growth in Jan-2014
WITH cte AS 
(SELECT card_type,exp_type,MONTH(transaction_date) AS mth,YEAR(transaction_date) AS yr, SUM(amount) AS totalAmount
FROM transactions
GROUP BY card_type, exp_type, MONTH(transaction_date),YEAR(transaction_date))

SELECT *,(totalAmount-prev_mth) AS mom_gth
FROM
(SELECT *,
LAG(totalAmount) OVER (PARTITION BY card_type,exp_type ORDER BY mth) AS prev_mth
FROM cte) AS tag
WHERE prev_mth IS NOT NULL AND mth = '1' AND yr ='2014'
ORDER BY mom_gth DESC
LIMIT 1;

-- 8- during weekends which city has highest total spend to total no of transcations ratio 

-- 9- which city took least number of days to reach its 500th transaction after the first transaction in that city

-- once you are done with this create a github repo to put that link in your resume. Some example github links:
-- https://github.com/ptyadana/SQL-Data-Analysis-and-Visualization-Projects/tree/master/Advanced%20SQL%20for%20Application%20Development
-- https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/COVID%20Portfolio%20Project%20-%20Data%20Exploration.sql