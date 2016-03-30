SELECT
  OBJECT_SCHEMA_NAME(T.object_id),
  *
FROM sys.objects T
WHERE T.type = 'U'
AND NOT EXISTS(SELECT * FROm sys.indexes I WHERE T.object_id = I.object_id and I.[type] = 1)
ORDER BY 1, 2
