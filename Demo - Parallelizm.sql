DBCC FREEPROCCACHE
DBCC SETCPUWEIGHT(500)
GO

SELECT * FROM Sales.SalesOrderHeader SOH 
INNER JOIN Sales.SalesOrderDetail SOD on SOH.SalesOrderID=SOD.SalesOrderID 
INNER JOIN Production.Product P on SOD.ProductID=P.ProductID
OPTION (MAXDOP 6)
GO
