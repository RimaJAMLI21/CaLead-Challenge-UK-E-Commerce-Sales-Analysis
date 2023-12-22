select *
from SalesTransaction


ALTER TABLE SalesTransaction
ADD CancellationStatus VARCHAR(20);

UPDATE SalesTransaction
SET CancellationStatus = CASE 
                            WHEN LEFT(TransactionNo, 1) = 'C' THEN 'Cancellation'
                            ELSE 'Not Cancellation'
                        END;


SELECT 
    TransactionNo,
    SUM((Price * Quantity)) AS TotalSales
FROM SalesTransaction
GROUP BY TransactionNo
order by TotalSales;



SELECT 
    CustomerNo,sum(TotalNotCancellation),sum(TotalCancellation),
    CASE 
        WHEN sum(TotalNotCancellation) = 0 AND sum(TotalCancellation) > 0 THEN 0
        WHEN sum(TotalCancellation) > sum(TotalNotCancellation) THEN 0
        WHEN sum(TotalNotCancellation) >= sum(TotalCancellation) THEN SUM(Price * Quantity)
    END AS TotalSales
FROM (
			SELECT 
			CustomerNo,
			(CASE WHEN CancellationStatus = 'Not Cancellation' THEN 1 ELSE 0 END) AS TotalNotCancellation,
			(CASE WHEN CancellationStatus = 'Cancellation' THEN 1 ELSE 0 END) AS TotalCancellation,
			TransactionNo,
			Price,
			Quantity,ProductNo,
			CancellationStatus
		FROM SalesTransaction
		GROUP BY CustomerNo, Price, Quantity, CancellationStatus,ProductNo,TransactionNo

) AS SubQuery
GROUP BY CustomerNo, TotalNotCancellation, TotalCancellation
Order by TotalSales desc;

---------------------------
/*
SELECT name
FROM sys.default_constraints
WHERE parent_object_id = OBJECT_ID('SalesTransaction')
  AND type_desc = 'DEFAULT_CONSTRAINT'
  AND parent_column_id = (
      SELECT column_id
      FROM sys.columns
      WHERE object_id = OBJECT_ID('SalesTransaction')
        AND name = 'TotalSales'
  );

ALTER TABLE SalesTransaction
DROP CONSTRAINT [DF__SalesTran__Total__339FAB6E];

ALTER TABLE SalesTransaction
DROP COLUMN TotalSales;

*/

ALTER TABLE SalesTransaction
ADD TotalSales DECIMAL(18, 2) DEFAULT 0;


UPDATE SalesTransaction
SET TotalSales = CASE 
                    WHEN SubQuery.TotalSales < 0 THEN 0
                    ELSE SubQuery.TotalSales
                 END
FROM (
    SELECT 
        CustomerNo,
        SUM(CASE WHEN CancellationStatus = 'Not Cancellation' THEN 1 ELSE 0 END) AS TotalNotCancellation,
        SUM(CASE WHEN CancellationStatus = 'Cancellation' THEN 1 ELSE 0 END) AS TotalCancellation,
        CASE 
            WHEN SUM(CASE WHEN CancellationStatus = 'Not Cancellation' THEN 1 ELSE 0 END) = 0 
                 AND SUM(CASE WHEN CancellationStatus = 'Cancellation' THEN 1 ELSE 0 END) > 0 THEN 0
            WHEN SUM(CASE WHEN CancellationStatus = 'Cancellation' THEN 1 ELSE 0 END) > SUM(CASE WHEN CancellationStatus = 'Not Cancellation' THEN 1 ELSE 0 END) THEN 0
            WHEN SUM(CASE WHEN CancellationStatus = 'Not Cancellation' THEN 1 ELSE 0 END) >= SUM(CASE WHEN CancellationStatus = 'Cancellation' THEN 1 ELSE 0 END) THEN SUM(Price * Quantity)
        END AS TotalSales
    FROM SalesTransaction
    GROUP BY CustomerNo
) AS SubQuery
WHERE SalesTransaction.CustomerNo = SubQuery.CustomerNo;



select * from SalesTransaction;

--How was the sales trend over the months?

SELECT 
    YEAR(Date) AS SalesYear,
    MONTH(Date) AS SalesMonth,
    SUM(TotalSales) AS MonthlyTotalSales
FROM SalesTransaction
GROUP BY YEAR(Date), MONTH(Date)
ORDER BY SalesYear, SalesMonth;


--• What are the most frequently purchased products?

select top 10 ProductName, sum(Quantity) as Total_Purchased, SUM(TotalSales) AS TotalSales
from SalesTransaction
group by ProductName
order by Total_Purchased desc
;

----How many products does the customer purchase in each transaction?

SELECT TransactionNo AS TransactionNo ,
       COUNT(DISTINCT ProductNo) AS Number_Products,
	   SUM(TotalSales) AS TotalSales
FROM SalesTransaction
GROUP BY TransactionNo
order by Number_Products desc ;


--What are the most profitable segment customers?

SELECT top 10 CustomerNo AS Customer,
       sum(TotalSales) AS Revenue
FROM SalesTransaction
GROUP BY CustomerNo
order by Revenue desc ;

--Total sales KPI 1
--SELECT SUM(Revenue) AS TotalRevenue
--FROM (
    --SELECT CustomerNo, SUM(TotalSales) AS Revenue
    --FROM SalesTransaction
    --GROUP BY CustomerNo
--) AS CustomerRevenue;

SELECT SUM(TotalSales) AS TotalRevenue
FROM SalesTransaction;

SELECT COUNT(*) AS TotalTransactions
FROM SalesTransaction;
 

--Total transaction 
SELECT TransactionNo, SUM(TotalSales) AS Revenue
    FROM SalesTransaction
    GROUP BY TransactionNo
--Total transaction with positive sales
SELECT COUNT(*) AS TotalTransactionsWithPositiveSales
FROM (
    SELECT TransactionNo, SUM(TotalSales) AS Revenue
    FROM SalesTransaction
    GROUP BY TransactionNo
    HAVING SUM(TotalSales) > 0 -- Filter for transactions with positive sales
) AS TransactionsWithPositiveSales;

--Total transaction with NO Revenues
SELECT COUNT(*) AS TotalTransactionsWithPositiveSales
FROM (
    SELECT TransactionNo, SUM(TotalSales) AS Revenue
    FROM SalesTransaction
    GROUP BY TransactionNo
    HAVING SUM(TotalSales) <= 0 -- Filter for transactions with positive sales
) AS TransactionsWithPositiveSales;


UPDATE SalesTransaction
SET CustomerNo = 'Future_Customer'
WHERE CustomerNo = 'NA';

--Total customers
select COUNT(DISTINCT CustomerNo)
from SalesTransaction

----Total customers with positive Revenues
SELECT COUNT(DISTINCT CustomerNo) AS NumberOfCustomersWithPositiveSales
FROM SalesTransaction
WHERE TotalSales > 0;

----Total customers with no revenues ~~" loosing customers"
SELECT COUNT(DISTINCT CustomerNo) AS NumberOfCustomersWithPositiveSales
FROM SalesTransaction
WHERE TotalSales = 0;


ALTER TABLE SalesTransaction
ADD MonthName NVARCHAR(20);

UPDATE SalesTransaction
SET MonthName = DATENAME(MONTH, Date);


ALTER TABLE SalesTransaction
ADD DayOfWeek NVARCHAR(20); 

UPDATE SalesTransaction
SET DayOfWeek = DATENAME(WEEKDAY, Date); 

--Canceled vs not Canceled Transaction
SELECT COUNT(DISTINCT TransactionNo) AS CanceledTransactionsCount
FROM SalesTransaction
WHERE CancellationStatus = 'Cancellation';

SELECT COUNT(DISTINCT TransactionNo) AS NotCanceledTransactionsCount
FROM SalesTransaction
WHERE CancellationStatus = 'Not Cancellation';

-- Countries Revenues 
SELECT Country, SUM(TotalSales) AS TotalSales
FROM SalesTransaction
GROUP BY Country
ORDER BY TotalSales DESC

--  products that have no transactions with a positive quantity, indicating they might be out-of-stock.
SELECT TransactionNo ,ProductNo, ProductName,Quantity
FROM SalesTransaction
WHERE ProductNo NOT IN (
    SELECT DISTINCT ProductNo
    FROM SalesTransaction
    WHERE Quantity >= 0  
);


