DECLARE
  @Object_Id  Int = OBJECT_ID('[System].[Test]')

SELECT
  C.[name],
  [SQL].[Field Type Compile](TYPE_NAME([user_type_id]), [max_length], [precision], [scale], NULL)
FROM sys.columns C WITH (NOLOCK)
WHERE C.[object_id] = @Object_Id AND C.[is_identity] = 1

SELECT TOP 1
  C.[name],
  [SQL].[Field Type Compile](TYPE_NAME([user_type_id]), [max_length], [precision], [scale], NULL)
FROM sys.indexes I WITH (NOLOCK)
CROSS APPLY
(
  SELECT
    C.[column_id],
    [Inc:Id]  = ROW_NUMBER() OVER (ORDER BY C.[index_column_id]),
    [Dec:Id]  = ROW_NUMBER() OVER (ORDER BY C.[index_column_id] DESC)
  FROM sys.index_columns C WITH (NOLOCK)
  WHERE C.[object_id] = @Object_Id AND C.[index_id] = I.[index_id]
) IC
INNER JOIN sys.columns C WITH (NOLOCK) ON C.[object_id] = @Object_Id AND IC.[column_id] = C.[column_id] AND C.[is_computed] = 1
WHERE I.[object_id] = @Object_Id AND I.[is_unique] = 1 AND I.[has_filter] = 0 AND I.[is_disabled] = 0 AND I.[ignore_dup_key] = 0 AND I.[is_unique_constraint] = 0
      AND IC.[Inc:Id] = IC.[Dec:Id]
ORDER BY I.[is_primary_key] DESC, I.[type]

SELECT *
FROM sys.columns C WITH (NOLOCK)
WHERE C.[object_id] = @Object_Id
