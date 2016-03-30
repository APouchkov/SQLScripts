select 
  [SQL].[Object Name]([parent_object_id]), 
  [name], 
  COL_NAME([parent_object_id], [parent_column_id]), 
  definition,
  'ALTER TABLE ' + [SQL].[Object Name]([parent_object_id]) + ' DROP CONSTRAINT ' + QuoteName([name]),
  'ALTER TABLE ' + [SQL].[Object Name]([parent_object_id]) + ' ADD CONSTRAINT ' 
    + QuoteName('DF_' + SCHEMA_NAME(schema_id) + '.' + OBJECT_NAME([parent_object_id]) + '#' + COL_NAME([parent_object_id], [parent_column_id])) 
    + ' DEFAULT ' + [definition] + ' FOR ' + QuoteName(COL_NAME([parent_object_id], [parent_column_id]))
FROM sys.default_constraints
ORDER BY 1

