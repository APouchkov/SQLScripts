DECLARE @SQL VarChar(Max)

SELECT 
  @SQL = IsNull(@SQL + Char(13) + Char(10), '') 
    + 'DBCC DBREINDEX(' 
    + [Pub].[Quote String](QuoteName(SCHEMA_NAME(schema_id)) + '.' + QuoteName(name)) 
    + '); CHECKPOINT; DBCC DROPCLEANBUFFERS'
FROM sys.objects (NOLOCK)
where type = 'U' --in ('U', 'V')
AND is_ms_shipped = 0

IF @SQL IS NOT NULL
  EXEC(@SQL)

SET @SQL = NULL

SELECT
  @SQL = IsNull(@SQL + Char(13) + Char(10), '')
    + 'DBCC DBREINDEX(' 
    + [Pub].[Quote String](QuoteName(SCHEMA_NAME(SO.schema_id)) + '.' + QuoteName(SO.name)) 
    + ', ' 
    + [Pub].[Quote String](SI.name)
    + '); CHECKPOINT; DBCC DROPCLEANBUFFERS'
FROM sys.objects SO (NOLOCK)
INNER JOIN sys.indexes SI (NOLOCK) ON SO.object_id = SI.object_id
where SO.type = 'V'
AND SO.is_ms_shipped = 0

IF @SQL IS NOT NULL
  EXEC(@SQL)
