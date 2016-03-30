DECLARE
  @Object_Id Int = OBJECT_ID('client_commission_parameter_values')

  SELECT
    [#Объект]               = QuoteName(object_schema_name(I.[object_id])) + '.' + QuoteName(object_name(I.[object_id])),
    [#Индекс]               = I.[name],
    [#Тип]                  = I.[type_desc],
    [#Первичный]            = CASE WHEN I.[is_primary_key] = 1 THEN '+' ELSE '' END,
    [#Уникальный]           = CASE WHEN I.[is_unique] = 1 THEN '+' ELSE '' END,
    [#Кол-во]               = Size.[rows],
    [#Данные(Мб)]           = cast(8 * cast(Size.data as numeric(32,3)) / 1024 as numeric(32,3)),
    [#Зарезервированно(Мб)] = cast(8 * cast(Size.reserved as numeric(32,3)) / 1024 as numeric(32,3)),
    [#Фильтр]               = I.[filter_definition],
    [#Поля индекса]         = IC.[IndexColumns],
    [#Поля добавочные]      = IC.[IncludedColumns],
    [#Компрессия]           = IP.[DataCompression]
  FROM sys.indexes I
  INNER JOIN sys.objects O ON I.[object_id] = O.[object_id] AND O.[type] IN ('U', 'V')
  CROSS APPLY
  (
    SELECT
		  [rows]      = SUM(row_count),
		  [reserved]  = SUM(ps.reserved_page_count),
		  [data]      = SUM(ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count),
		  [used]      = SUM(ps.used_page_count)
	  FROM sys.dm_db_partition_stats ps
    WHERE I.[object_id] = ps.[object_id] and I.[index_id] = ps.[index_id]
  ) Size
  CROSS APPLY
  (
    SELECT
      [IndexColumns]    = [Pub].[Concat](IC.[IndexColumn], ', '),
      [IncludedColumns] = [Pub].[Concat](IC.[IncludedColumns], ', ') 
    FROM 
    (
      SELECT TOP 1000
        [IndexColumn]     = CASE WHEN IC.[is_included_column] = 0 THEN QuoteName(C.[name]) + ' ' + CASE WHEN IC.[is_descending_key] = 0 THEN 'ASC' ELSE 'DESC' END END,
        [IncludedColumns] = CASE WHEN IC.[is_included_column] = 1 THEN QuoteName(C.[name]) END
      FROM sys.index_columns IC 
      INNER JOIN sys.columns C ON C.[object_id] = I.[object_id] AND IC.[column_id] = C.[column_id] 
      WHERE IC.[object_id] = I.[object_id] AND IC.[index_id] = I.[index_id]
      ORDER BY IC.[key_ordinal]
    ) IC
  ) IC
  CROSS APPLY
  (
    SELECT
      [DataCompression] = [Pub].[Concat](DISTINCT P.[data_compression_desc], ',')
    FROM sys.partitions P
    WHERE P.[index_id] = I.[index_id]
      AND P.[object_id] = I.[object_id]
  ) IP
  WHERE (@Object_Id IS NULL OR @Object_Id = I.[object_id])
  ORDER BY 8 DESC, 1, 2

 