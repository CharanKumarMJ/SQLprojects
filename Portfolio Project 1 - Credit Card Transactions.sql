 -- MySQL 
 -- Skills used :DQL,AGGREGATIONS, DATE FUNCTIONS,CASE STATEMENTS,CTE, SUB-QUERY, WINDOW FUNCTIONS 
USE pcredit;

SELECT *
FROM transactions;



-- Query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
SELECT SUM(amount) AS total_amount
FROM transactions;

SELECT city,SUM(amount) AS total_Sum,
(SUM(amount)/(SELECT SUM(amount) FROM transactions))*100 as percent
FROM transactions
GROUP BY city
ORDER BY total_Sum DESC
LIMIT 5 ;

-- Query to print highest spend month and amount spent in that month for each card type
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

-- Query to print the transaction details(all columns from the table) for each card type when
	-- it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
    WITH cte AS 
    (SELECT *, SUM(amount) OVER (PARTITION BY card_type ORDER BY transaction_date,transaction_id) AS totalSpend
    FROM transactions
    ORDER BY card_type,totalSpend DESC)
    SELECT * 
    FROM (SELECT *, RANK() OVER(PARTITION BY  card_type ORDER BY  totalSpend) as rn  
	FROM cte WHERE totalSpend >= 1000000) AS tag 
    WHERE rn=1;
    
-- Query to find city which had lowest percentage spend for gold card type

SELECT city, (SUM(amount)/(SELECT SUM(amount) FROM transactions WHERE card_type="Gold"))*100 AS perc
FROM transactions
WHERE card_type="Gold"
GROUP BY city
ORDER BY perc ASC
LIMIT 1;

-- Query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
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

-- Query to find percentage contribution of spends by females for each expense type
SELECT exp_type,(SUM(CASE WHEN gender='F' THEN amount ELSE 0 END)/SUM(amount))*100 AS gen_exp
FROM transactions
GROUP BY exp_type;

-- which card and expense type combination saw highest month over month growth in Jan-2014
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

-- during weekends which city has highest total spend to total no of transcations ratio 
SELECT city,SUM(amount)/COUNT(*) AS ratio
FROM transactions
WHERE WEEKDAY(transaction_date) IN (5,6)
GROUP BY city
ORDER BY ratio DESC;

-- which city took least number of days to reach its 500th transaction after the first transaction in that city
WITH cte AS 
(SELECT *,
ROW_NUMBER() OVER(PARTITION BY city ORDER BY transaction_id,transaction_date) AS rn
FROM transactions)

SELECT city, DATEDIFF(MAX(transaction_date), MIN(transaction_date)) AS date_diff
FROM cte
WHERE rn = 1 OR rn=500
GROUP BY city
HAVING COUNT(1)=2
ORDER BY date_diff ASC;