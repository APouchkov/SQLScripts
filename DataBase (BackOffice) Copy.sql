USE [master]
GO
BACKUP DATABASE [BackOffice] 
  TO DISK = N'\\PUCHKOV\Backups\NEW\BackOffice.Transit.bak' 
  WITH NOFORMAT,
  INIT,
  NAME = N'BackOffice-Full Database Backup',
  SKIP,
  NOREWIND,
  NOUNLOAD,
  COMPRESSION,
  STATS = 10
GO
EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'BackOffice.Test'
GO
USE [master]
GO
ALTER DATABASE [BackOffice.Test] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
DROP DATABASE [BackOffice.Test]
GO
RESTORE DATABASE [BackOffice.Test] 
  FROM DISK = N'\\PUCHKOV\Backups\NEW\BackOffice.Transit.bak' 
  WITH FILE = 1,
  MOVE N'Data' TO N'D:\DATABASES\BackOffice.Test.mdf',
  MOVE N'Log' TO N'D:\DATABASES\BackOffice.Test.ldf',
  NOUNLOAD,
  STATS = 10
GO
BEGIN TRY
  ALTER DATABASE [BackOffice.Test] SET COMPATIBILITY_LEVEL = 110
END TRY
BEGIN CATCH
  PRINT ERROR_MESSAGE()
END CATCH
GO
EXEC [BackOffice.Test].dbo.sp_changedbowner @loginame = N'sa', @map = false
GO
  DECLARE @SQL varchar(max), @DataBase sysname
  SET @DataBase = 'BackOffice.Test'

  SET @SQL = '
  ALTER DATABASE ' + QuoteName(@DataBase) + ' SET
  ANSI_NULLS ON,
  ANSI_NULL_DEFAULT ON,
  ANSI_PADDING ON,
  ANSI_WARNINGS ON,
  ARITHABORT ON,
  CONCAT_NULL_YIELDS_NULL ON,
  QUOTED_IDENTIFIER ON,
  CURSOR_DEFAULT LOCAL,
  READ_COMMITTED_SNAPSHOT ON,
  DB_CHAINING ON, 
  TRUSTWORTHY ON
  WITH ROLLBACK IMMEDIATE
'
  EXEC(@SQL)

  SET @SQL = 'ALTER DATABASE ' + QuoteName(@DataBase) + ' SET NEW_BROKER WITH ROLLBACK IMMEDIATE'
  EXEC(@SQL)
  SET @SQL = 'ALTER DATABASE ' + QuoteName(@DataBase) + ' SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE'
  EXEC(@SQL)
GO
USE [BackOffice.Test]
GO
EXEC sp_addrolemember N'db_owner', N'VELES-CAPITAL\Gagarkin'
EXEC sp_addrolemember N'Grant_Read', N'Gagarkin'
EXEC sp_addrolemember N'Grant_Write', N'Gagarkin'
EXEC sp_addrolemember N'db_owner', N'VELES-CAPITAL\Negash'
EXEC sp_addrolemember N'Grant_Read', N'Negash'
EXEC sp_addrolemember N'Grant_Write', N'Negash'
GO
IF  EXISTS (SELECT * FROM sys.triggers WHERE parent_class_desc = 'DATABASE' AND name = N'DataBase DDL Trigger')
DISABLE TRIGGER [DataBase DDL Trigger] ON DATABASE
GO
