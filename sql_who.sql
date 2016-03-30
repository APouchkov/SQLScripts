set nocount on
set ansi_nulls on
set quoted_identifier on
set transaction isolation level read uncommitted
go
if object_id('tempdb..#result_sql_who') is not null
  drop table #result_sql_who
go
------------------------------------------------
-- <Фильтр>
------------------------------------------------
declare
  @active     bit           = 1,    -- NULL = все, 1 = только активные, 0 = неактивные
  @show_plan  bit           = NULL, -- NULL -> берем из @active
  @show_sql   bit           = NULL, -- NULL -> берем из @active
  @host       nvarchar(512) = NULL, -- NULL = все
  @login      nvarchar(512) = NULL, -- NULL = все
  @hide_sys   bit           = 1,    -- 1 = скрывать / иначе = не скрывать
  @order_by   nvarchar(512) = '([LogicReads] + [CPU] + [Writes]) desc, [Id] asc'
------------------------------------------------
-- </Фильтр>
------------------------------------------------

declare @sessions table
(
  [session_id] int not null primary key clustered
)

set @hide_sys = isnull(@hide_sys, 0)
if @active = 1
  insert into @sessions
  select [blocking_session_id]
  from sys.dm_exec_requests R
  where [blocking_session_id] is not null and [blocking_session_id] <> 0
    and (
          (@hide_sys = 1 and [blocking_session_id] > 50)
          or
          @hide_sys = 0
        )
  ------
  union
  ------
  select [session_id]
  from sys.dm_exec_requests R
  where [status] in ('running', 'runable')
    and (
          (@hide_sys = 1 and [session_id] > 50)
          or
          @hide_sys = 0
        )
    and R.[session_id] <> @@spid
else if @active = 0
  insert into @sessions
  select R.[session_id]
  from sys.dm_exec_requests R
  where [status] not in ('running', 'runable', 'background')
    and (
          (@hide_sys = 1 and [session_id] > 50)
          or
          @hide_sys = 0
        )
    and [session_id] is not null
else
  insert into @sessions
  select distinct C.[session_id]
  from sys.dm_exec_connections C
  where (
          (@hide_sys = 1 and [session_id] > 50)
          or
          @hide_sys = 0
        )
    and C.[session_id] is not null

select
  [Id]              = X.[session_id],
  [Blocked]         = nullif(R.[blocking_session_id], 0),
  [Status]          = S.[status],
  [DB]              = db_name(R.[database_id]),
  [Command]         = R.[command],
  [Start]           = R.[start_time],
  [TranCount]       = R.[open_transaction_count],
  [WaitTime]        = R.[wait_time],
  [WaitType]        = R.[wait_type],
  [Cmd.Reads]       = R.[reads],
  [Cmd.Writes]      = R.[writes],
  [Cmd.CPU]         = R.[cpu_time],
  [Reads]           = S.[reads],
  [Writes]          = S.[writes],
  [LogicReads]      = S.[logical_reads],
  [CPU]             = S.[cpu_time],
  [Login]           = S.[login_name],
  [Host]            = S.[host_name],
  [Plan.dbid]       = RP.[dbid],
  [Plan.objectid]   = RP.[objectid],
  --[Plan.number]     = RP.[number],
  --[Plan.Encrypted]  = RP.[encrypted],
  [Plan.query_plan] = RP.[query_plan],
  [SQL.dbid]        = SQ.[dbid],
  [SQL.objectid]    = SQ.[objectid],
  [SQL.number]      = SQ.[number],
  [SQL.Encrypted]   = SQ.[encrypted],
  [SQL.text]        = SQ.[text]
into #result_sql_who
from @sessions X
inner join sys.dm_exec_connections C on C.[session_id] = X.[session_id]
left join sys.dm_exec_sessions S on S.[session_id] = X.[session_id]
left join sys.dm_exec_requests R on R.[session_id] = X.[session_id]
outer apply
(
  select
    RP.[dbid],
    RP.[objectid],
    RP.[number],
    RP.[encrypted],
    RP.[query_plan]
  from sys.dm_exec_query_plan(R.[plan_handle]) RP
  where (@show_plan = 1)
     or (@show_plan is null and @active = 1)
) RP
outer apply
(
  select
    SQ.[dbid],
    SQ.[objectid],
    SQ.[number],
    SQ.[encrypted],
    SQ.[text]
  from sys.dm_exec_sql_text(R.[sql_handle]) SQ
  where (@show_sql = 1)
     or (@show_sql is null and @active = 1)
) SQ

declare @sql nvarchar(max)
set @sql = 'select * from #result_sql_who order by ' + @order_by
exec (@sql)


