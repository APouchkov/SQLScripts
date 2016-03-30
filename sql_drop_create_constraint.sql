DECLARE @constraint VarChar(255)
SET @constraint = '([System].[User::Name]())'

SELECT
	[definition],
	object_name(parent_object_id),
	[name],
	col_name(parent_object_id , parent_column_id),
  'ALTER TABLE [' + SCHEMA_NAME(schema_id) + '].[' + object_name(parent_object_id) + '] DROP CONSTRAINT ' + QuoteName([name]),
  'ALTER TABLE [' + SCHEMA_NAME(schema_id) + '].[' + object_name(parent_object_id) + '] ADD CONSTRAINT ' + QuoteName([name]) + ' DEFAULT ' + @constraint + ' FOR [' + col_name(parent_object_id , parent_column_id) + ']'
FROM sys.default_constraints (NOLOCK)
WHERE [definition] = @constraint
GO

RETURN

DECLARE @Table SysName = '[Base].[Persons]'

SELECT
	[definition],
	object_name(parent_object_id),
	[name],
	col_name(parent_object_id , parent_column_id),
  'ALTER TABLE [' + SCHEMA_NAME(schema_id) + '].[' + object_name(parent_object_id) + '] DROP CONSTRAINT ' + QuoteName([name]),
  'ALTER TABLE [' + SCHEMA_NAME(schema_id) + '].[' + object_name(parent_object_id) + '] ADD CONSTRAINT ' + QuoteName([name]) + ' DEFAULT ' + [definition] + ' FOR [' + col_name(parent_object_id , parent_column_id) + ']'
FROM sys.default_constraints (NOLOCK)
WHERE parent_object_id = OBJECT_ID(@Table)
GO
