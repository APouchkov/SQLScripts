SELECT TOP 100
  [name]      = OBJECT_NAME(ps.object_id, ps.database_id), 
  [dbname]    = DB_NAME(ps.database_id), 
  [io]        = ps.total_logical_reads + ps.total_logical_writes,
  * 
FROM sys.dm_exec_procedure_stats ps
--outer apply sys.dm_exec_query_plan(ps.plan_handle)
WHERE ps.database_id = DB_ID('opendb')
ORDER BY
  ps.max_elapsed_time DESC
--  ps.total_logical_reads + ps.total_logical_writes DESC
