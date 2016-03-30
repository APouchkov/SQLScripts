SELECT 
	ST.text, 
    SUBSTRING(ST.text, (QS.statement_start_offset/2) + 1,
    ((CASE statement_end_offset 
        WHEN -1 THEN DATALENGTH(ST.text)
        ELSE QS.statement_end_offset END 
            - QS.statement_start_offset)/2) + 1) AS statement_text,
     --QS.[execution count]/(cast(QS.[Elapsed seconds] as numeric)+1) [execution per sec], 
     --QS.[Ttl IO]/(cast(QS.[Elapsed seconds] as numeric)+1) [IO per sec],
     QS.*
     --PL.*
	
FROM
	(SELECT TOP 200 
		SUM(query_stats.total_logical_reads + query_stats.total_logical_writes) AS "Ttl IO",
		SUM(query_stats.total_logical_reads) AS "Ttl reads",
		SUM(query_stats.total_physical_reads) AS "Ttl physical reads",
		SUM(query_stats.total_logical_writes) AS "Ttl writes",
		SUM(query_stats.total_worker_time)/1000000.0 AS "Ttl CPU Time (s)",
		SUM(query_stats.total_elapsed_time)/1000000.0 AS "Ttl Elapsed Time (s)",
		SUM(query_stats.execution_count) AS "execution count",
		SUM(query_stats.total_logical_reads + query_stats.total_logical_writes)/(SUM(query_stats.total_elapsed_time)/1000000.0 + DATEDIFF(SECOND, MIN(query_stats.creation_time), MAX(query_stats.last_execution_time))) [IO per sec],
		SUM(query_stats.execution_count)/(SUM(query_stats.total_elapsed_time)/1000000.0 + DATEDIFF(SECOND, MIN(query_stats.creation_time), MAX(query_stats.last_execution_time))) [exec per sec],
		(SUM(query_stats.total_worker_time)/1000000.0)/(SUM(query_stats.total_elapsed_time)/1000000.0 + DATEDIFF(SECOND, MIN(query_stats.creation_time), MAX(query_stats.last_execution_time))) [CPU per sec],
		CAST(SUM(query_stats.total_rows) as numeric(38,3))/SUM(query_stats.execution_count) as "avg_rows",
		CAST(MAX(query_stats.last_execution_time) as smalldatetime) "last start time", -- excel не любит миллисекунды
		CAST(MIN(query_stats.creation_time) as smalldatetime) "first start time", -- excel не любит миллисекунды
		DATEDIFF(SECOND, MIN(query_stats.creation_time), MAX(query_stats.last_execution_time)) "Elapsed seconds",
		MIN(query_stats.statement_start_offset) statement_start_offset, 
		MIN(query_stats.statement_end_offset) statement_end_offset, 
		MIN(query_stats.plan_handle) plan_handle, 
		MIN(query_stats.sql_handle) sql_handle
		--query_stats.query_hash AS "Query Hash" 
	FROM 
		sys.dm_exec_query_stats AS query_stats
	GROUP BY query_stats.query_hash
	HAVING SUM(query_stats.total_elapsed_time)/1000000.0>60
	ORDER BY 
		--"Ttl CPU Time (s)" DESC
		"Ttl IO" DESC
		--"Ttl Elapsed Time (s)" DESC,
		--"Ttl CPU Time (s)" DESC,
		--"Query Hash"
	) QS
	OUTER APPLY sys.dm_exec_sql_text(QS.sql_handle) as ST
