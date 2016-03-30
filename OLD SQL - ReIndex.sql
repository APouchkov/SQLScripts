DECLARE
  @Fragmentation  TinyInt     = 30,
  @Execute        Bit         = 0,
  @Action         VarChar(50) = 'REBUILD', -- 'REBUILD', 'REINDEX'
  @Debug          Bit         = 1,
  @MaxDop         SmallInt    = 2

  SET NOCOUNT ON

  IF @Action IS NULL OR @Action NOT IN ('REBUILD', 'REINDEX', 'ALL') BEGIN
    RaisError('Тип действия %s нераспознан.', 16, 1, @Action)
    Return 
  END

  DECLARE 
    @objectid         int,
    @indexid          int,
    @partitioncount   bigint,
    @objectname       nvarchar(130),
    @indexname        nvarchar(130),
    @partitionnum     bigint,
    @partitions       bigint,
    @frag             float,
    @command          nvarchar(4000),
    @i                int,
    @j                int,
    @Page_Size        Int             = 4096,
    @DefaultFrag      float           = 5     -- Низшая граница фрагментации для действия "ALL"

  DECLARE @work_to_do TABLE
  (
    [Object:Id]               Int           NOT NULL,
    [Object:Name]             SysName       NOT NULL,
    [Index:Id]                Int           NOT NULL,
    [Index:Name]              SysName       NOT NULL,
    [Index:Type:Description]  nvarchar(120) NOT NULL,
    [Index:Partition:Number]  Int           NOT NULL,
    [Index:Fragmentation]     float         NOT NULL,
    [Index:Rows]              BigInt        NOT NULL,
    PRIMARY KEY CLUSTERED([Object:Id], [Index:Id], [Index:Partition:Number])
  )

  -- Conditionally select tables and indexes from the sys.dm_db_index_physical_stats function 
  -- and convert object and index IDs to names.

  INSERT INTO @work_to_do ([Object:Id], [Object:Name], [Index:Id], [Index:Name], [Index:Type:Description], [Index:Partition:Number], [Index:Fragmentation], [Index:Rows])
  SELECT
    [Object:Id]               = ips.object_id,
    [Object:Name]             = QUOTENAME(OBJECT_SCHEMA_NAME(ips.object_id)) + '.' + QUOTENAME(object_name(ips.object_id)),
    [Index:Id]                = ips.index_id,
    [Index:Name]              = QUOTENAME(si.name),
    [Index:Type:Description]  = ips.index_type_desc,
    [Index:Partition:Number]  = ips.partition_number,
    [Index:Fragmentation]     = ips.avg_fragmentation_in_percent,
    [Index:Rows]              = si.[rows]
  FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL , NULL, 'LIMITED') ips
  join sys.sysindexes si WITH (NOLOCK) on ips.index_id = si.indid and ips.object_id = si.id
  WHERE ips.index_id > 0
        AND ips.alloc_unit_type_desc = 'IN_ROW_DATA'
        AND CASE @Action
              WHEN 'REORGANIZE' THEN CASE WHEN ips.avg_fragmentation_in_percent > @Fragmentation THEN 1 END
              WHEN 'REBUILD' THEN CASE WHEN ips.avg_fragmentation_in_percent > @Fragmentation AND si.[rows] > @Page_Size THEN 1 END
              ELSE CASE WHEN ips.avg_fragmentation_in_percent > @DefaultFrag THEN 1 END
            END = 1
  SET @j = @@ROWCOUNT

  IF @Execute = 0
    SELECT
      *
    FROM @work_to_do
    ORDER BY [Object:Name], [Index:Name]

  -- Declare the cursor for the list of partitions to be processed.
  DECLARE partitions CURSOR FOR
    SELECT
      [Object:Id],
      [Object:Name], 
      [Index:Id],
      [Index:Name],
      [Index:Partition:Number], 
      [Index:Fragmentation] 
    FROM @work_to_do
    ORDER BY [Object:Name], [Index:Name]

  -- Open the cursor.
  OPEN partitions

  SET @i = 0
  -- Loop through the partitions.
  WHILE (1 = 1)
  BEGIN
    FETCH NEXT
    FROM partitions
    INTO @objectid, @objectname, @indexid, @indexname, @partitionnum, @frag

      IF @@FETCH_STATUS < 0 BREAK

      SELECT
        @partitioncount = count (*)
      FROM sys.partitions
      WHERE object_id = @objectid AND index_id = @indexid

      -- Если уровень фрагментации не критический, то обойдёмся реорганизацией индекса
      IF @Action = 'REBUILD' AND @frag < @fragmentation
        CONTINUE
      ELSE IF @Action = 'REORGANIZE' OR @frag < @fragmentation
        SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @objectname + N' REORGANIZE'
                          + CASE
                              WHEN @partitioncount > 1 THEN N' PARTITION = ' + CAST(@partitionnum AS nvarchar(10))
                              ELSE ''
                            END
      ELSE BEGIN
        SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @objectname + N' REBUILD'
                          + CASE
                              WHEN @partitioncount > 1 THEN N' PARTITION = ' + CAST(@partitionnum AS nvarchar(10))
                              ELSE ''
                            END
                          + ' WITH (SORT_IN_TEMPDB = OFF'
                          + CASE
                              WHEN @partitioncount = 1
                                AND NOT EXISTS
                                        (
                                          select 1 
                                          from sys.columns c WITH (NOLOCK) 
                                          WHERE c.object_id = @objectid
                                                  and 
                                                  (
                                                    c.max_length = -1
                                                    OR
                                                    TYPE_NAME(c.system_type_id) in ('image', 'text', 'ntext', 'xml')
                                                  )
                                        )
                              THEN N', ONLINE = ON'
                              ELSE N''
                            END
                          + IsNull(N', MAXDOP = ' + CAST(@MaxDop AS VarChar), N'')
                          + N')'
      END

      SET @i = @i + 1
      SET @command = @command + N'  --  Fragmentation = ' + CAST(CAST(@frag AS numeric(10,2)) AS VarChar) + ', Complete = ' + CAST(CAST(round(@i * 1.0 / @j * 100, 2) as numeric(10,2)) AS nvarchar(6)) + N'%%'

      IF @Debug = 1
        RaisError(@command, 0, 1) WITH NOWAIT

      IF @Execute = 1
        EXEC(@command)
  END

  -- Close and deallocate the cursor.
  CLOSE partitions
  DEALLOCATE partitions
