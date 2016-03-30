DECLARE
  @Object SysName = '[BackOffice].[Accounts:Trade Codes]'

SELECT
  N'EXEC sp_refreshview ' + [Pub].[Quote String]([SQL].[Object Name](V.[object_id]))
FROM [sys].[views] V
WHERE CharIndex(@Object, OBJECT_DEFINITION(V.[object_id])) > 0



