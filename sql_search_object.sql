  DECLARE
    @NameLike     nvarchar(100), --    = '%Document%', 
    @item         nvarchar(100)    = 'INSERT',
    @itemIn       nvarchar(200),--    = 'client',
    @itemInScope  nvarchar(200)    = 'client',
    @RegEx        nvarchar(200)    = 'INSERT\s+(INTO\s+|)(\[?dbo\]?\.|)\[?client[\s(\]]',
    @itemNotIn    nvarchar(200)

  DECLARE
    @id         int,
    @number     smallint,
    @name       sysname         = '', 
    @text       varchar(max),
    @i          int,
    @j          int,
    @k          int,
    @l          int,
    @Line       VarChar(Max)


LB_N:
  SELECT TOP 1
    @name   = QuoteName(schema_name(SO.schema_id)) + '.' + QuoteName(object_name(SO.object_id)),
    @text   = OBJECT_DEFINITION(so.object_id, SC.number),
    @id     = SO.object_id,
    @number = SC.number
  FROM sys.objects SO (NOLOCK)
  CROSS APPLY
  (
    SELECT DISTINCT
      SC.number
    FROM sys.syscomments SC (NOLOCK)
    WHERE sc.id = so.object_id
    GROUP BY SC.number
  ) SC
  WHERE (
          QuoteName(schema_name(schema_id)) + '.' + QuoteName(name) > @name
          OR SO.object_id = @id AND @number < number
        )
        AND so.name NOT LIKE '=%'
        AND so.name NOT LIKE '@%'
        AND OBJECT_DEFINITION(so.object_id, SC.number) like '%' + Replace(Replace(@item, '[', '[[]'), '_', '[_]') + '%'
        AND (@NameLike IS NULL OR so.name LIKE @NameLike)
  ORDER BY QuoteName(schema_name(SO.schema_id)) + '.' + QuoteName(object_name(SO.object_id)), SC.number

  IF @@rowcount = 1 BEGIN
    SET @i = 0
    SET @l = datalength(@text)

LB_CI:
    IF @itemInScope <> N'' AND CharIndex(@itemInScope, @text) = 0 GOTO LB_N
    IF @RegEx <> N'' BEGIN
      --[Pub].[RegExp::IsMatch](@text, @RegExInScope, 'singleline,multiline,ignorecase') = 0
      SET @Line = NULL
      SELECT
        @Line = IsNull(@Line + char(13) + char(10), N'') + [Pub].[Trim(Spaces)](@name + ';' + cast(@number as varchar) + ': ' + [Match])
      FROM [Pub].[RegExp::Matches]
      (
        @Text,
        @RegEx,
        'singleline,multiline,ignorecase'
      )
      WHERE [GroupIndex] = 0

      IF @Line <> N''
        PRINT @Line
      GOTO LB_N
    END

    SET @i = CharIndex(@item, @text, @i + 1)
    IF @i > 0 BEGIN
      SET @j = @i - 1
      WHILE @j > 0 AND ascii(substring(@text, @j, 1)) > 13 SET @j = @j -1
      SET @k = @i + 1
      WHILE @k <= @l AND ascii(substring(@text, @k, 1)) > 13 SET @k = @k + 1
      SET @Line = substring(@text, @j + 1, @k - @j)
      IF @itemIn <> '' AND CharIndex(@itemIn, @Line) = 0 GOTO LB_CI
      IF @itemNotIn <> '' AND CharIndex(@itemNotIn, @Line) > 0 GOTO LB_CI
      SET @Line = [Pub].[Trim(Spaces)](@name + ';' + cast(@number as varchar) + ': ' + @Line)
      PRINT @Line
      GOTO LB_CI
    END
    GOTO LB_N
  END
