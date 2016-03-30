-- MS SQL Server 2005
declare @SQL varchar(max), @Login sysname
set @Login = 'WebUser'

SET @SQL = Null
Select @SQL = IsNull(@SQL + char(13), '') + 'KILL ' + cast(spid as varchar) from sys.sysprocesses where loginame = @Login
Exec(@SQL)
GO

/*
-- MS SQL Server 2005
declare @SQL varchar(max)

SET @SQL = Null
Select 
  @SQL = IsNull(@SQL + char(13), '') + 'KILL ' + cast(spid as varchar) + ' -- ' + ISNULL([Pub].[Trim](hostname, ' '), '<NoHostName>') + ' :: ' + [Pub].[Trim](loginame, ' ')
from sys.sysprocesses

EXEC [SQL].[Print] @SQL
-- Exec(@SQL)
*/
