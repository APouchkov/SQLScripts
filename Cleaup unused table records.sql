SET NOCOUNT ON
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

DECLARE
  @Object_Id  Int           = OBJECT_ID('[Base].[Persons]'),
  @SQL        NVarChar(Max)


SELECT @SQL = N'DELETE FROM DELTABLE
FROM ' + QUOTENAME(SCHEMA_NAME(O.[schema_id])) + '.' + QUOTENAME(O.[name]) + ' AS DELTABLE
WHERE 1 = 1'
FROM [sys].[objects] AS O
WHERE O.[object_id] = @Object_Id
  
SELECT @SQL = @SQL + '
  AND NOT EXISTS
      (
        SELECT * FROM ' + QUOTENAME(SCHEMA_NAME(O.[schema_id])) + '.' + QUOTENAME(O.[name]) + ' AS ' + REPLACE(REPLACE(O.[name], ':', '_'), ' ', '') + '
        WHERE 1 = 1
' + REPLACE(REPLACE(COLS.[Condition], '<ALIAS>', REPLACE(REPLACE(O.[name], ':', '_'), ' ', '')), '<TABLE>', 'DELTABLE') + '
      )
'
FROM [sys].[foreign_keys] AS FK
INNER JOIN [sys].[objects] AS O ON O.[object_id] = FK.[parent_object_id]
CROSS APPLY
(
  SELECT
    [Condition] = [Pub].[Merge]('          AND <ALIAS>.' + QUOTENAME(FCol.[name]) + ' = <TABLE>.' + QUOTENAME(RCol.[name]), '
')
  FROM [sys].[foreign_key_columns] AS FKC
  INNER JOIN [sys].[columns] AS FCol ON FCol.[column_id] = FKC.[parent_column_id]
                                    AND FCol.[object_id] = FKC.[parent_object_id]
  INNER JOIN [sys].[columns] AS RCol ON RCol.[column_id] = FKC.[referenced_column_id]
                                    AND RCol.[object_id] = FKC.[referenced_object_id]
  WHERE FKC.[constraint_object_id] = FK.[object_id]
  -- ORDER BY FKC.[constraint_column_id]
) AS COLS
WHERE FK.[referenced_object_id] = @Object_Id
  AND [delete_referential_action_desc] = 'NO_ACTION'

EXEC [SQL].[Print] @SQL
GO

