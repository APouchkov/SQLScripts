-- CREATE TABLE tblTestDurability (ID INT IDENTITY PRIMARY KEY CLUSTERED, Name Char(200))
--DROP TABLE tblTestDurability2
-- CREATE TABLE tblTestDurability2 (ID INT IDENTITY PRIMARY KEY NONCLUSTERED HASH WITH (bucket_count=200000), Name Char(200) COLLATE Latin1_General_BIN2) WITH (MEMORY_OPTIMIZED=ON, DURABILITY=SCHEMA_ONLY)

--SET STATISTICS TIME OFF

SET NOCOUNT ON
GO
TRUNCATE TABLE tblTestDurability
GO
--ALTER DATABASE [CIS] SET DELAYED_DURABILITY = ALLOWED WITH NO_WAIT
GO

GO

DECLARE @Time DateTime = GetDate()
BEGIN TRANSACTION

DECLARE @I int = 9
WHILE @i < 100001
BEGIN
SET @i = @i +1
INSERT INTO tblTestDurability
(Name)
VALUES
('My Test ')
END


COMMIT TRANSACTION 
SELECT Cast(GetDate() - @Time AS Time)
GO
SET NOCOUNT ON

BEGIN TRANSACTION 
DELETE tblTestDurability2 WITH (SNAPSHOT)
COMMIT TRANSACTION 

DECLARE @Time DateTime = GetDate()

BEGIN TRANSACTION

DECLARE @I int = 9
WHILE @i < 100001
BEGIN
SET @i = @i +1
INSERT INTO tblTestDurability2
(Name)
VALUES
('My Test ')
END

COMMIT TRANSACTION 
SELECT Cast(GetDate() - @Time AS Time)
GO
