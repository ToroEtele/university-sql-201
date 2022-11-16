--Írjunk egy INSERT triggert az OrderDetail táblára mely frissíti a OrderHeader tábla SubTotal mezőjét SubTotal = SubTotal + OrderQty * UnitPrice


--Egy tábla beszúrása esetén
/*
CREATE OR ALTER TRIGGER Purchasing.UpdateSubtotal
ON PurchaseOrderDetail
FOR INSERT
AS
BEGIN
--SELECT @uPrice=OrderQty, @qty=UnitPrice FROM inserted
DECLARE @sum INT = (SELECT (UnitPrice*OrderQty) s FROM inserted)

UPDATE PurchaseOrderHeader 
SET SubTotal = SubTotal + @sum
WHERE PurchaseOrderID = (SELECT PurchaseOrderID FROM inserted)

END
*/
--Több tábla beszúrása esetén:

/*
CREATE OR ALTER TRIGGER Purchasing.UpdateMultipleSubtotal
ON Purchasing.PurchaseOrderDetail
FOR INSERT
AS
BEGIN
DECLARE @ID INT;

DECLARE orders_cursor CURSOR FOR
SELECT DISTINCT PurchaseOrderID FROM inserted

OPEN orders_cursor
FETCH NEXT FROM orders_cursor INTO @ID

WHILE @@FETCH_STATUS = 0
BEGIN
	DECLARE @sum INT = (SELECT SUM(UnitPrice*OrderQty) s FROM inserted WHERE PurchaseOrderID=@ID)
	UPDATE PurchaseOrderHeader 
	SET SubTotal = SubTotal + @sum
	WHERE PurchaseOrderID = @ID

	FETCH NEXT FROM orders_cursor INTO @ID
END

CLOSE orders_cursor
DEALLOCATE orders_cursor

END
*/

--Bővítsük ki DELETE-re is és frissítsük a SubTotalt

CREATE OR ALTER TRIGGER Purchasing.UpdateMultipleSubtotal
ON Purchasing.PurchaseOrderDetail
FOR INSERT
AS
BEGIN
DECLARE @ID INT;

DECLARE orders_cursor CURSOR FOR
SELECT DISTINCT PurchaseOrderID FROM inserted
UNION
SELECT DISTINCT PurchaseOrderID FROM deleted

OPEN orders_cursor
FETCH NEXT FROM orders_cursor INTO @ID

WHILE @@FETCH_STATUS = 0
BEGIN
	DECLARE @sum INT = (SELECT SUM(UnitPrice*OrderQty) s FROM Purchasing.PurchaseOrderDetail WHERE PurchaseOrderID=@ID)
	UPDATE PurchaseOrderHeader 
	SET SubTotal = SubTotal + @sum
	WHERE PurchaseOrderID = @ID

	FETCH NEXT FROM orders_cursor INTO @ID
END

CLOSE orders_cursor
DEALLOCATE orders_cursor

END