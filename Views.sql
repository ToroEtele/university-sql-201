CREATE OR ALTER VIEW biciklitRendelt
AS
SELECT DISTINCT FirstName, MiddleName, LastName, Title FROM Sales.SalesOrderDetail sod	--azon rendelesek melyek biciklit tartalmaznak
INNER JOIN Sales.SalesOrderHeader ssh ON ssh.SalesOrderID = sod.SalesOrderDetailID
INNER JOIN Sales.Customer c ON c.CustomerID = ssh.CustomerID
INNER JOIN Person.Person p ON p.BusinessEntityID = c.PersonID
WHERE ProductID IN
(SELECT p.ProductID FROM Production.Product p								
INNER JOIN Production.ProductSubCategory psc ON psc.ProductSubcategoryID = p.ProductSubcategoryID
WHERE psc.Name LIKE '%Bike%')	--Lista azokkal a termek ID-kal, amelyek biciklik

GO

SELECT * FROM dbo.biciklitRendelt