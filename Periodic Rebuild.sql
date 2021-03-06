USE [CIS]
GO
/****** Object:  StoredProcedure [System].[Periodic@Rebuild]    Script Date: 04/01/2016 12:34:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [System].[Periodic@Rebuild]
  @Name     SysName,        -- Имя таблицы
  @Release  Bit       = 0,  -- Принудительное освобождение от виртуальных объектов
  @Debug    Bit       = 0
---
  WITH EXECUTE AS 'dbo'
---
AS
  SET NOCOUNT ON

  DECLARE
    @DataBaseCollation              SysName,
    @Object_Name                    SysName,
    @Object_Id                      Int,
    @Object                         SysName,

    @Values_Id                      NVarChar(Max),
    @AllValues_Id                   NVarChar(Max),
    @Values_IdAndName               NVarChar(Max),
    @AllValues_IdAndName            NVarChar(Max),

    @Translate                      Bit,
    @Translate_Table_Id             SmallInt,
    @Translate_Fields_PIDs          VarChar(8000),
    @HaveUnTranslatableFields       Bit,

    @Logging                        Bit,

    @Function_Name                  SysName,
    @Table_Id                       SmallInt,
    @Field_Id                       SmallInt,
    @FieldName                      SysName,
    @ListFieldsExists               Bit,
    @FieldType                      NVarChar(255),
    @FieldNullAble                  Bit,
    @FieldTranslate                 Bit,
    @KeyField                       SysName,
    @KeyFieldIdentity               Bit,
    @GUIdField                      SysName,
    @DateFirstField                 SysName,
    @DateFirstFieldType             SysName,
    @DateFirstNullAble              Bit,
    @MostUsedField                  SysName,
    @ActiveField                    SysName,
    @ActiveMethod                   Char(3),
    @InterfaceView                  Bit,
    @InterfaceProc                  Bit,
    @ServiceFields                  NVarChar(2000),
    @PeriodicFieldCount             TinyInt,
    @PeriodicListFields             NVarChar(Max),
    @InterfaceProcModifiableFields  NVarChar(Max),
    @InterfaceProcDefaultFields     NVarChar(Max),
    @Future                         Bit,
    @TableHaveVariantField          Bit,
    @SQL                            NVarChar(Max)

  DECLARE @AllFields TABLE
  (
    [Name]                    SysName         NOT NULL PRIMARY KEY CLUSTERED,
    [Column_Id]               Int                 NULL,
    [PeriodicField_Id]        SmallInt            NULL,
    [PeriodicFieldKind]       Char(1) COLLATE Cyrillic_General_BIN NULL,
    [TranslateField_Id]       SmallInt            NULL,
    [Type_Short]              SysName         NOT NULL,
    [Type_Full]               SysName         NOT NULL,
    [Collation]               SysName             NULL,
    [IsNullAble]              Bit             NOT NULL,
    [IsIdentityOrComputed]    Bit             NOT NULL,
    [IsService]               Bit             NOT NULL,
    [DefaultConstraint]       NVarChar(4000)      NULL,

    [Keys]                    NVarChar(256)       NULL,
    [ForeignTableSchema]      SysName             NULL,
    [ForeignTableName]        SysName             NULL,
    [ForeignTablePeriodic_Id] SmallInt            NULL,
    [ForeignKeys]             NVarChar(256)       NULL,
    [ForeignLinks]            NVarChar(512)       NULL,
    [ForeignList]             SysName             NULL,
    [ForeignValue]            SysName             NULL,
    [ForeignIdentity]         SysName             NULL
  )

  BEGIN TRY
    IF @Name IS NULL BEGIN
      SET @Table_Id = 0

      WHILE 1 = 1 BEGIN
        SELECT TOP 1
          @Table_Id = [Id],
          @Name     = [Name]
        FROM [System].[Periodic->Tables]
        WHERE [Id] > @Table_Id
        ORDER BY [Id]

        IF @@ROWCOUNT = 0
          BREAK
        ELSE
          EXEC [System].[Periodic@Rebuild] @Name = @Name, @Release = @Release
      END

      RETURN 0
    END

    SET @Object_Id = @@PROCID
    IF @Object_Id IS NULL
      RaisError('Abstract error', 16, 2)

    SET @Object_Name = '[System].' + QuoteName(@Name)
    IF @Release = 0 BEGIN
      SET @Object_Id = OBJECT_ID(@Object_Name)
      IF @Object_Id IS NULL
        RaisError('Объект «%s» не обнаружен.', 16, 2, @Object_Name)

      SELECT
        @DataBaseCollation = [collation_name]
      FROM sys.databases (NOLOCK)
      WHERE [database_id] = DB_ID()

      SELECT
        @Table_Id           = PT.[Id],
        @KeyField           = PT.[KeyField],
        @GUIdField          = PT.[GUIdField],
        @DateFirstField     = PT.[DateFirstField],
        @DateFirstFieldType = TYPE_NAME(SF.[user_type_id]),
        @DateFirstNullAble  = SF.[is_nullable],
        @MostUsedField      = PT.[MostUsedField],
        @ActiveField        = CASE WHEN PT.[ActiveMethod] IS NOT NULL THEN PT.[ActiveField] END,
        @ActiveMethod       = CASE WHEN PT.[ActiveField] IS NOT NULL THEN PT.[ActiveMethod] END,
        @InterfaceView      = PT.[InterfaceView],
        @InterfaceProc      = PT.[InterfaceProc],
        @ServiceFields      = PT.[ServiceFields],
        @Future             = PT.[Future]
      FROM [System].[Periodic->Tables] PT WITH (SERIALIZABLE)
      LEFT JOIN [sys].[columns] SF WITH (NOLOCK) ON SF.[object_id] = @Object_Id AND PT.[DateFirstField] = SF.[Name]
      WHERE PT.[Name] = @Name

      IF @@ROWCOUNT <> 1
        RaisError('Таблица «%s» не зарегистрированна в периодике.', 16, 2, @Name)

      SELECT
        @PeriodicFieldCount = COUNT(1),
        @MostUsedField      = CASE
                                WHEN @MostUsedField IS NULL OR SUM(CASE WHEN [Name] = @MostUsedField THEN 1 ELSE 0 END) = 0 THEN MIN([Name])
                                ELSE @MostUsedField
                              END
      FROM [System].[Periodic->Fields] WITH (SERIALIZABLE)
      WHERE [Table_Id] = @Table_Id

      IF @PeriodicFieldCount = 0
        SET @Release = 1
    END

    IF @Release = 0 BEGIN
      IF @ActiveMethod NOT IN ('ATF', 'ATN', 'DTF', 'DTN', 'DN')
        RaisError('Объект «%s» имеет неверное описание параметра [ActiveMethod] = «%s».', 16, 2, @Object_Name, @ActiveMethod)

      IF @ActiveMethod IS NOT NULL AND @DateFirstField IS NOT NULL
        RaisError('Объект «%s» имеет одновременное описание метода [DateFirstField] = «%s» и [ActiveField] = «%s».', 16, 2, @Object_Name, @DateFirstField, @ActiveField)

      INSERT INTO @AllFields
      (
        [Name],
        [Column_Id],
        [PeriodicField_Id],
        [PeriodicFieldKind],
        [Type_Short],
        [Type_Full],
        [Collation],
        [IsNullAble],
        [IsIdentityOrComputed],
        [IsService],
        [DefaultConstraint],

        [Keys],
        [ForeignTableSchema],
        [ForeignTableName],
        [ForeignTablePeriodic_Id],
        [ForeignKeys],
        [ForeignLinks],
        [ForeignList],
        [ForeignValue],
        [ForeignIdentity]
      )
      SELECT
        [Name]                    = C.[Name],
        [Column_Id]               = C.[Column_Id],
        [PeriodicField_Id]        = C.[PeriodicField_Id],
        [PeriodicFieldKind]       = C.[PeriodicFieldKind],
        [Type_Short]              = C.[Type_Short],
        [Type_Full]               = C.[Type_Full],
        [Collation]               = C.[Collation],
        [IsNullAble]              = C.[IsNullAble],
        [IsIdentityOrComputed]    = C.[IsIdentityOrComputed],
        [IsService]               = CASE WHEN Srv.[Value] IS NULL THEN 0 ELSE 1 END,
        [DefaultConstraint]       = C.[DefaultConstraint],

        [Keys]                    = C.[Keys],
        [ForeignTableSchema]      = C.[ForeignTableSchema],
        [ForeignTableName]        = C.[ForeignTableName],
        [ForeignTablePeriodic_Id] = FPT.[Id],
        [ForeignKeys]             = C.[ForeignKeys],
        [ForeignLinks]            =
        (
          SELECT
            [Pub].[Concat]
            (
              N'<%SOURCE%>.' + QuoteName(K.[Value]) + N' = <%TARGET%>.' + QuoteName(FK.[Value]),
              N'<%SEPARATOR%>'
            )
          FROM [Pub].[Array To RowSet Of Values](C.[Keys], N',') K
          INNER JOIN [Pub].[Array To RowSet Of Values](C.[ForeignKeys], N',') FK ON K.[Index] = FK.[Index]
          WHERE C.[Keys] <> N''
        ),
        [ForeignList]             = C.[ForeignList],
        [ForeignValue]            = C.[ForeignValue],
        [ForeignIdentity]         = FPT.[KeyField]
      FROM
      (
        SELECT
          [Name]                  = IsNull(SF.[Name], PF.[Name]),
          [Column_Id]             = SF.[Column_Id],
          [PeriodicField_Id]      = PF.[PeriodicField_Id],
          [PeriodicFieldKind]     = PF.[PeriodicFieldKind],
          [Type_Short]            = IsNull(SF.[Type_Short], N'NVarChar'),
          [Type_Full]             = IsNull(SF.[Type_Full], N'NVarChar(4000)'),
          [Collation]             = NullIf(SF.[Collation], @DataBaseCollation),
          [IsNullAble]            = IsNull(SF.[IsNullAble], 1),
          [IsIdentityOrComputed]  = IsNull(SF.[IsIdentityOrComputed], 0),
          [DefaultConstraint]     = SF.[DefaultConstraint],

          [Keys]                  = PF.[Keys],
          [ForeignTableSchema]    = PARSENAME(PF.[ForeignTable], 2),
          [ForeignTableName]      = PARSENAME(PF.[ForeignTable], 1),
          [ForeignTable]          = PF.[ForeignTable],
          [ForeignKeys]           = CASE WHEN PF.[PeriodicFieldKind] = 'L' THEN Left(PF.[ForeignKeys], CharIndex(N'->', PF.[ForeignKeys]) - 1) ELSE PF.[ForeignKeys] END,
          [ForeignList]           = CASE WHEN PF.[PeriodicFieldKind] = 'L' THEN SubString(PF.[ForeignKeys], CharIndex(N'->', PF.[ForeignKeys]) + 2, 1000) END,
          [ForeignValue]          = PF.[ForeignValue]
        FROM
        (
          SELECT TOP 1000000 -- Чтобы SQL не разворачивал подзапрос
            [Column_Id]             = C.[column_id],
            [Name]                  = C.[name],
            [Type_Short]            = TYPE_NAME(C.[system_type_id]),
            [Type_Full]             = [SQL].[Field Type Compile](TYPE_NAME(C.[system_type_id]), C.[max_length], C.[precision], C.[scale], NULL),
            [Collation]             = C.[collation_name],
            [IsNullAble]            = C.[is_nullable],
            [IsIdentityOrComputed]  = CASE WHEN C.[is_identity] = 0 AND C.[is_computed] = 0 THEN 0 ELSE 1 END,
            [DefaultConstraint]     = DF.[definition]
          FROM [sys].[columns] C
          LEFT JOIN [sys].[default_constraints] DF ON DF.[parent_object_id] = @Object_Id
                                                        AND C.[is_identity] = 0 AND C.[is_computed] = 0
                                                        AND C.[column_id] = DF.[parent_column_id]
          WHERE C.[object_id] = @Object_Id
        ) SF
        FULL OUTER JOIN
        (
          SELECT TOP 1000000 -- Чтобы SQL не разворачивал подзапрос
            [PeriodicField_Id]  = PF.[Id],
            [Name]              = PF.[Name],
            [PeriodicFieldKind] = CASE
                                    WHEN PF.[ForeignKeys] IS NOT NULL AND CharIndex(N'->', PF.[ForeignKeys]) > 0 THEN 'L'
                                  END,

            [Keys]              = PF.[Keys],
            [ForeignTable]      = PF.[ForeignTable],
            [ForeignKeys]       = PF.[ForeignKeys],
            [ForeignValue]      = PF.[ForeignValue]

          FROM [System].[Periodic->Fields] PF
          WHERE PF.[Table_Id] = @Table_Id
        ) PF ON SF.[Name] = PF.[Name]
        WHERE [System].[Raise Error]
              (
                @@PROCID,
                CASE
                  WHEN SF.[Name] IS NULL AND PF.[PeriodicFieldKind] IS NULL THEN N'Поле с именем ' + PF.[Name] + N' в таблице ' + @Object_Name + N' отсутствует'
                END
              ) IS NULL
      ) C
      LEFT JOIN [Pub].[Array To RowSet Of Values](@ServiceFields, N',') Srv ON C.[Name] = Cast(Srv.[Value] AS SysName)
      LEFT JOIN [System].[Periodic->Tables] FPT ON C.[PeriodicFieldKind] = 'L' AND C.[ForeignTableName] = FPT.[Name]
                                                    AND FPT.[ActiveField] = C.[ForeignValue]
                                                    AND FPT.[ActiveMethod] = 'DTN'
      WHERE [System].[Raise Error]
            (
              @@PROCID,
              CASE
                WHEN C.[PeriodicField_Id] IS NOT NULL AND Srv.[Value] IS NOT NULL THEN N'Служебное поле с именем ' + C.[Name] + N' в таблице ' + @Object_Name + N' не должно быть зарегистрированно в периодике'
                WHEN C.[PeriodicFieldKind] = 'L' AND C.[Keys] IS NULL THEN N'Поля связи [Keys] для раскрытия периодического поля ' + C.[Name] + N' в таблице ' + @Object_Name + N' не заданы'
                WHEN C.[PeriodicFieldKind] = 'L' AND C.[ForeignTableName] IS NULL THEN N'Связанная с полем ' + C.[Name] + N' в таблице ' + @Object_Name + N' субтаблица [ForeignTable] не задана'
                WHEN C.[PeriodicFieldKind] = 'L' AND IsNull(C.[ForeignTableSchema], N'') <> N'[<Schema>]' THEN N'Связанная с полем ' + C.[Name] + N' в таблице ' + @Object_Name + N' субтаблица "' + C.[ForeignTableName] + N'" расположена в другой схеме "' + C.[ForeignTableSchema] + N'"'
                WHEN C.[PeriodicFieldKind] = 'L' AND C.[ForeignValue] IS NULL THEN N'Связанное с полем ' + C.[Name] + N' в таблице ' + @Object_Name + N' поле значения [ForeignValue] субтаблицы не задано'
                WHEN C.[PeriodicFieldKind] = 'L' AND FPT.[Id] IS NULL THEN N'Связанная с полем ' + C.[Name] + N' в таблице ' + @Object_Name + N' субтаблица ' + QuoteName(C.[ForeignTableSchema]) + N'.' + QuoteName(C.[ForeignTableName]) + N' имеет неверные настройки периодики'
              END
            ) IS NULL

      IF @ActiveField IS NOT NULL AND NOT EXISTS(SELECT 1 FROM @AllFields WHERE [Name] = @ActiveField AND [PeriodicField_Id] IS NOT NULL)
        RaisError('Объект %s имеет описание поля [ActiveField] = %s, не зарегистрированного в периодике.', 16, 2, @Object_Name, @ActiveField)

      SELECT
        @InterfaceProcModifiableFields  = [Pub].[Concat](CASE WHEN C.[IsIdentityOrComputed] = 0 AND C.[IsService] = 0 OR C.[PeriodicFieldKind] IS NOT NULL THEN C.[Name] END, N','),
        @InterfaceProcDefaultFields     = [Pub].[Concat](CASE WHEN C.[DefaultConstraint] IS NOT NULL AND C.[IsService] = 0 THEN C.[Name] END, N','),
        @Values_Id                      = [Pub].[Concat](CASE WHEN C.[PeriodicField_Id] IS NOT NULL AND C.[PeriodicFieldKind] IS NULL THEN N'(' + Cast(C.[PeriodicField_Id] AS NVarChar) + N')' END, N', '),
        @AllValues_Id                   = [Pub].[Concat](CASE WHEN C.[PeriodicField_Id] IS NOT NULL THEN N'(' + Cast(C.[PeriodicField_Id] AS NVarChar) + N')' END, N', '),
        @Values_IdAndName               = [Pub].[Concat](CASE WHEN C.[PeriodicField_Id] IS NOT NULL AND C.[PeriodicFieldKind] IS NULL THEN N'(' + Cast(C.[PeriodicField_Id] AS NVarChar) + N', ' + [Pub].[Quote String](C.[Name]) + N')' END, N', '),
        @AllValues_IdAndName            = [Pub].[Concat](CASE WHEN C.[PeriodicField_Id] IS NOT NULL THEN N'(' + Cast(C.[PeriodicField_Id] AS NVarChar) + N', ' + [Pub].[Quote String](C.[Name]) + N')' END, N', '),
        @ListFieldsExists               = CASE WHEN SUM(CASE WHEN C.[PeriodicFieldKind] = 'L' THEN 1 ELSE 0 END) > 0 THEN 1 ELSE 0 END
      FROM @AllFields C

      IF EXISTS
         (
           SELECT 1
           FROM [sys].[columns] C
           WHERE C.[object_id] = @Object_Id AND C.[name] = @KeyField AND (C.[is_identity] = 1 OR C.[is_computed] = 1)
         )
        SET @KeyFieldIdentity = 1
      ELSE
        SET @KeyFieldIdentity = 0

      IF @DateFirstField IS NOT NULL AND @DateFirstNullAble IS NULL
        RaisError('Таблица %s не содержит поля «%s».', 16, 2, @Object_Name, @DateFirstField)

      IF @DateFirstFieldType IS NOT NULL AND @DateFirstFieldType NOT IN ('Date', 'SmallDateTime', 'DateTime')
        RaisError('Тип «%s» поля «%s» таблицы %s недопустим.', 16, 2, @DateFirstFieldType, @DateFirstField, @Object_Name)

      IF @GUIdField IS NOT NULL
        SET @InterfaceProcDefaultFields = [Pub].[Arrays Merge](@InterfaceProcDefaultFields, @GUIdField, ',')

      IF EXISTS(SELECT TOP 1 1 FROM [sys].[columns] WHERE [object_id] = @Object_Id AND [system_type_id] =  TYPE_ID('SQL_Variant'))
        SET @TableHaveVariantField = 1
      ELSE
        SET @TableHaveVariantField = 0

      SET @Translate = 0
      SET @HaveUnTranslatableFields = 1
      IF OBJECT_ID('[System].[Translate->Fields]') IS NOT NULL BEGIN
        SET @Translate_Table_Id = [System].[Translate->Table@Id](@Name)

        UPDATE SF SET
          [TranslateField_Id] = TF.[Id]
        FROM [System].[Translate->Fields] TF
        INNER JOIN @AllFields SF ON TF.[Name] = SF.[Name]
        WHERE TF.[Table_Id] = @Translate_Table_Id
          AND [System].[Raise Error]
              (
                @@PROCID,
                CASE
                  WHEN TF.[Name] = @ActiveField THEN 'Поле логической активности записи «' + @ActiveField + '» не должно быть зарегистрированно в системе перевода'
                END
              ) IS NULL

        IF @@ROWCOUNT > 0 BEGIN
          SET @Translate = 1
          SELECT
            @Translate_Fields_PIDs    = [Pub].[ConCat](TF.[PeriodicField_Id], ','),
            @HaveUnTranslatableFields = CASE WHEN COUNT(1) < @PeriodicFieldCount THEN 1 ELSE 0 END
          FROM @AllFields TF
          WHERE TF.[PeriodicField_Id] IS NOT NULL AND TF.[TranslateField_Id] IS NOT NULL
        END
      END

      SET @Logging = 0
      IF OBJECT_ID('[System].[Log->Table@Id]') IS NOT NULL
        IF [System].[Log->Table@Id](@Name) IS NOT NULL
          SET @Logging = 1
    END

    -- 1. InLine Table-Valued function
    SET @Function_Name = '[System].' + QuoteName(@Name + '@Periodic')
    IF @Release = 0 BEGIN
      SELECT
        @SQL = CASE WHEN OBJECT_ID(@Function_Name) IS NULL THEN 'CREATE' ELSE 'ALTER' END + ' FUNCTION ' + @Function_Name + ' (@Date Date'
              + CASE WHEN @Translate = 1 THEN N', @Language Char(2) = NULL' ELSE '' END
              + ')
  RETURNS TABLE
AS
  RETURN
  (
    SELECT'
              +
              [Pub].[Concat]
              (
                N'
      ' + [SQL].[Shift](QuoteName(SF.[Name]), 26) + N'= '
                +
                CASE
                  WHEN SF.[PeriodicField_Id] IS NOT NULL THEN
                    CASE
                      WHEN SF.[TranslateField_Id] IS NOT NULL THEN
                        N'IsNull(Cast(VT' + Cast(SF.[PeriodicField_Id] AS NVarChar) + N'.[Value] AS ' + SF.[Type_Full] + N'), '
                      ELSE N''
                    END
                    + CASE WHEN SF.[Type_Short] <> N'SQL_Variant' THEN N'Cast(' ELSE N'' END
                    + N'V' + Cast(SF.[PeriodicField_Id] AS NVarChar) + N'.[Value]'
                    + CASE WHEN SF.[Type_Short] <> N'SQL_Variant' THEN N' AS ' + SF.[Type_Full] + N')' ELSE N'' END
                    + CASE WHEN SF.[TranslateField_Id] IS NOT NULL THEN N')' ELSE N'' END
                    + CASE WHEN SF.[Collation] <> N'' AND SF.[Type_Short] IN (N'Char', N'NChar', N'VarChar', N'NVarChar') THEN N' COLLATE ' + SF.[Collation] ELSE N'' END
                  WHEN SF.[TranslateField_Id] IS NOT NULL THEN
                    N'IsNull(Cast(T' + Cast(SF.[TranslateField_Id] AS NVarChar) + N'.[Value] AS ' + SF.[Type_Full] + N'), T.' + QuoteName(SF.[Name]) + N')'
                  ELSE
                    N'T.' + QuoteName(SF.[Name])
                END
                , N','
              )
              + N'
    FROM ' + @Object_Name + ' T'
    + [Pub].[Concat]
      (
        CASE
          WHEN SF.[PeriodicField_Id] IS NOT NULL THEN
            N'
    ' + CASE WHEN SF.[Name] = @MostUsedField THEN 'CROSS' ELSE 'OUTER' END + N' APPLY (SELECT TOP 1 V.[Date], V.[Value] FROM [System].[Periodic:Values] V WHERE V.[Field_Id] = ' + Cast(SF.[PeriodicField_Id] AS NVarChar) + ' AND V.[Key] = T.' + QuoteName(@KeyField) + N' AND V.[Date] <= @Date ORDER BY V.[Date] DESC) V' + Cast(SF.[PeriodicField_Id] AS NVarChar)
            + CASE
                WHEN SF.[TranslateField_Id] IS NOT NULL THEN N'
    LEFT JOIN [System].[Periodic:Values:Translate] VT' + Cast(SF.[PeriodicField_Id] AS NVarChar) + ' ON VT' + Cast(SF.[PeriodicField_Id] AS NVarChar) + N'.[Field_Id] = ' + Cast(SF.[PeriodicField_Id] AS NVarChar) + ' AND VT' + Cast(SF.[PeriodicField_Id] AS NVarChar) + '.[Key] = T.' + QuoteName(@KeyField) + N' AND V' + Cast(SF.[PeriodicField_Id] AS NVarChar) + '.[Date] = VT' + Cast(SF.[PeriodicField_Id] AS NVarChar) + N'.[Date] AND VT' + Cast(SF.[PeriodicField_Id] AS NVarChar) + N'.[Language] = @Language'
                ELSE N''
              END
          WHEN SF.[TranslateField_Id] IS NOT NULL THEN N'
    LEFT JOIN [System].[Translate:Values] T' + Cast(SF.[TranslateField_Id] AS NVarChar) + ' ON T' + Cast(SF.[TranslateField_Id] AS NVarChar) + '.[Field_Id] = ' + Cast(SF.[TranslateField_Id] AS NVarChar) + ' AND T' + Cast(SF.[TranslateField_Id] AS NVarChar) + '.[Key] = T.' + QuoteName(@KeyField) + ' AND T' + Cast(SF.[TranslateField_Id] AS NVarChar) + N'.[Language] = @Language'
          ELSE N''
        END,
        N''
      )
    + '
  )'
      FROM
      (
        SELECT TOP 1000000
          SF.*
        FROM @AllFields SF
        WHERE SF.[PeriodicFieldKind] IS NULL
        ORDER BY IsNull(SF.[Column_Id], 1000 + SF.[PeriodicField_Id])
      ) SF

      EXEC [SQL].[Debug Exec] @SQL = @SQL, @RaiseIfEmpty = 'InLine Table-Valued function', @Debug = @Debug
    END ELSE IF OBJECT_ID(@Function_Name, 'IF') IS NOT NULL BEGIN
      SET @SQL = 'DROP FUNCTION ' + @Function_Name
      EXEC [SQL].[Debug Exec] @SQL = @SQL, @Debug = @Debug
    END

    -- 2. Table Triggers
    IF @Release = 0 BEGIN
      -- 2.1 Table Trigger :: Insert
      SELECT TOP 1
        @Function_Name  = N'[System].' + QuoteName([name])
      FROM sys.objects WITH (NOLOCK)
      WHERE [parent_object_id] = @Object_Id AND [type] = 'TR' AND [name] LIKE '% (Periodic Insert)'

      IF @@ROWCOUNT <> 1 BEGIN
        SET @Function_Name  = N'[System].' + QuoteName(@Name + ' (Periodic Insert)')
        SET @SQL = N'CREATE TRIGGER ' + @Function_Name
      END ELSE
        SET @SQL  = N'ALTER TRIGGER ' + @Function_Name

      SET @SQL += N' ON ' + @Object_Name + N'
  FOR INSERT
AS
  IF NOT EXISTS(SELECT TOP 1 1 FROM Inserted) RETURN
  SET NOCOUNT ON'
          +
          CASE
            WHEN @DateFirstNullAble IS NULL OR @DateFirstNullAble = 1 OR @Translate_Fields_PIDs IS NOT NULL THEN N'

  DECLARE'
            ELSE N''
          END
          +
          CASE
            WHEN @DateFirstNullAble IS NULL OR @DateFirstNullAble = 1 THEN N'
    @Today  Date = [Pub].[Today]()'
              + CASE WHEN @Translate_Fields_PIDs IS NOT NULL THEN N',' ELSE N'' END
            ELSE N''
          END
          +
          CASE
            WHEN @Translate_Fields_PIDs IS NOT NULL THEN N'
    @DefaultLanguage  Char(2) = [System].[Default Language]()'
            ELSE N''
          END
          + N'

  INSERT INTO [System].[Periodic:Values] ([Field_Id], [Key], [Date], [Value])'
          +
          (
            SELECT
              [Pub].[Concat]
              (
                N'
  SELECT
    ' + Cast(PF.[PeriodicField_Id] AS NVarChar) + N',
    ' + QuoteName(@KeyField) + N',
    '
                +
                CASE
                  WHEN @DateFirstNullAble = 0 THEN QuoteName(@DateFirstField)
                  WHEN @DateFirstNullAble = 1 THEN N'IsNull(' + QuoteName(@DateFirstField) + N', @Today)'
                  ELSE N'@Today'
                END
                + N',
    Cast(' + QuoteName(PF.[Name]) + N' AS SQL_Variant)
  FROM Inserted', N'
    UNION ALL'
              )
            FROM @AllFields PF
            WHERE PF.[PeriodicField_Id] IS NOT NULL AND PF.[PeriodicFieldKind] IS NULL
          )
          +
          CASE
            WHEN @Translate_Fields_PIDs IS NOT NULL THEN N'

  INSERT INTO [System].[Periodic:Values:Translate] ([Field_Id], [Key], [Date], [Language], [Value])
  SELECT
    [Field_Id]  = V.[Field_Id],
    [Key]       = V.[Key],
    [Date]      = V.[Date],
    [Language]  = @DefaultLanguage,
    [Value]     = Cast(V.[Value] AS NVarChar(4000))
  FROM Inserted I
  INNER JOIN [System].[Periodic:Values] V ON V.[Field_Id] IN (' + @Translate_Fields_PIDs + ') AND I.' + QuoteName(@KeyField) + ' = V.[Key] AND V.[Value] IS NOT NULL'
            ELSE N''
          END

      EXEC [SQL].[Debug Exec] @SQL = @SQL, @RaiseIfEmpty = 'Table Trigger :: Insert', @Debug = @Debug

      -- 2.2 Table Trigger :: Update
      SELECT TOP 1
        @SQL  = 'ALTER TRIGGER [System].' + QuoteName([name])
      FROM sys.objects WITH (NOLOCK)
      WHERE [parent_object_id] = @Object_Id AND [type] = 'TR' AND [name] LIKE '% (Periodic Update)'

      IF @@ROWCOUNT <> 1
        SET @SQL = 'CREATE TRIGGER [System].' + QuoteName(@Name + ' (Periodic Update)')

      SET @SQL += ' ON ' + @Object_Name + '
  FOR UPDATE
AS
  IF NOT EXISTS(SELECT TOP 1 1 FROM Inserted) RETURN
  SET NOCOUNT ON

  DECLARE
    @Error  Int

  BEGIN TRY'
        +
        CASE
          WHEN @DateFirstField IS NOT NULL THEN N'
    IF Update(' + QuoteName(@DateFirstField) + N') BEGIN
      UPDATE V SET
        [Date]      = CASE WHEN V.[PriorDate] IS NULL     THEN P.[Age] ELSE V.[Date] END,
        [PriorDate] = CASE WHEN V.[PriorDate] IS NOT NULL THEN P.[Age] END
      FROM
      (
        SELECT
          [Field_Id]        = V.[Field_Id],
          [Key]             = V.[Key],
          [Age]             = I.' + QuoteName(@DateFirstField) + ',
          [Date]            = V.[Date],
          [NextDate]        = V.[NextDate]
        FROM Deleted D
        INNER JOIN Inserted I ON D.' + QuoteName(@KeyField) + N' = I.' + QuoteName(@KeyField)
                      + CASE WHEN @DateFirstNullAble = 1 THEN N' AND I.' + QuoteName(@DateFirstField) + N' IS NOT NULL' ELSE '' END
                      + ' AND D.' + QuoteName(@DateFirstField) + N' <> I.' + QuoteName(@DateFirstField) + N'
        CROSS JOIN (VALUES ' + @Values_Id + N') F([Id])' + CASE WHEN @DateFirstNullAble = 1 THEN N'
        CROSS APPLY [System].[Periodic:Row@Info](' + Cast(@Table_Id AS NVarChar) + N', D.' + QuoteName(@KeyField) + N', Default) RI' ELSE N'' END + N'
        INNER JOIN [System].[Periodic:Values] V ON F.[Id] = V.[Field_Id]'
                        + N' AND D.' + QuoteName(@KeyField) + N' = V.[Key]'
                        + N' AND V.[PriorDate] IS NULL
        WHERE [System].[Raise Error]
              (
                @@PROCID,
                CASE
                  WHEN V.[NextDate] IS NOT NULL AND I.' + QuoteName(@DateFirstField) + N' >= V.[NextDate]
                    THEN N''Первичная запись в периодике [Age] = '' + Convert(NVarChar, I.' + QuoteName(@DateFirstField) + N', 104) + '' должна быть меньше даты первого изменения [Date] = '' + Convert(NVarChar, V.[NextDate], 104)
                END
              ) IS NULL
      ) P
      INNER JOIN [System].[Periodic:Values] V ON P.[Field_Id] = V.[Field_Id] AND P.[Key] = V.[Key]
                AND (P.[Date] = V.[Date] OR P.[NextDate] IS NOT NULL AND P.[NextDate] = V.[Date])
    END
' ELSE N'' END
      +
      (
        SELECT
          [Pub].[Concat](N'
    IF Update(' + QuoteName(PF.[Name]) + ')
      SET @Error =
        (
          SELECT TOP 1 1
          FROM Inserted I
          OUTER APPLY [System].[Periodic:Field:Value@Info](' + Cast(PF.[PeriodicField_Id] AS NVarChar) + N', ' + QuoteName(@KeyField) + ', [Pub].[Today](), Default) V
          WHERE [System].[Raise Error]
                (
                  @@PROCID,
                  CASE
                    WHEN [Pub].[Is Equal Variants](I.' + QuoteName(PF.[Name]) + ', V.[Value]) = 0
                      THEN '
                  + [Pub].[Quote String]('Неверное текущее периодическое значение поля ' + QuoteName(PF.[Name]) + N' = ')
                  + N' + '
                  + CASE
                      WHEN PF.[IsNullable] = 1 THEN N'IsNull(''«'''
                      ELSE N'''«'''
                    END
                  + N' + '
                  + CASE
                      WHEN PF.[Type_Short] NOT IN ('Char', 'NChar', 'VarChar', 'NVarChar') THEN N'Cast('
                      ELSE N''
                    END
                  + N'I.' + QuoteName(PF.[Name])
                  + CASE
                      WHEN PF.[Type_Short] NOT IN ('Char', 'NChar', 'VarChar', 'NVarChar') THEN N' AS NVarChar(4000))'
                      ELSE N''
                    END
                  + ' + '
                  + CASE
                      WHEN PF.[IsNullable] = 1 THEN '''»'', ''Null'')'
                      ELSE N'''»'''
                    END
                  + N' + '
                  + [Pub].[Quote String](', [Periodic:Value] = ')
                  + N' + IsNull(''«'' + Cast(V.[Value] AS NvarChar(4000)) + ''»'', ''Null'') + '
                  + [Pub].[Quote String](' таблицы ' + @Object_Name + ' для записи ' + QuoteName(@KeyField) + N' = ')
                  + N' + Cast(I.' + QuoteName(@KeyField) + N' AS NVarChar)'
                  + N' + ''.''
                  END
                ) = 1
        )
', '')
        FROM @AllFields PF
        WHERE PF.[PeriodicField_Id] IS NOT NULL AND PF.[PeriodicFieldKind] IS NULL
      )
        + N'
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 AND XACT_STATE() <> 0 ROLLBACK TRAN
    EXEC [System].[ReRaise Error] @ProcedureId = @@PROCID
  END CATCH'

      EXEC [SQL].[Debug Exec] @SQL = @SQL, @RaiseIfEmpty = 'Table Trigger :: Update', @Debug = @Debug

      -- 2.3 Table Trigger :: Delete
      SELECT TOP 1
        @SQL  = 'ALTER TRIGGER [System].' + QuoteName([name])
      FROM sys.objects WITH (NOLOCK)
      WHERE [parent_object_id] = @Object_Id AND [type] = 'TR' AND [name] LIKE '% (Periodic Delete)'

      IF @@ROWCOUNT <> 1
        SET @SQL = 'CREATE TRIGGER [System].' + QuoteName(@Name + ' (Periodic Delete)')

      SET @SQL += ' ON ' + @Object_Name + '
  FOR DELETE
AS
  IF NOT EXISTS(SELECT TOP 1 1 FROM Deleted) RETURN
  SET NOCOUNT ON

  DELETE V
  FROM (VALUES ' + @Values_Id + N') F([Id])
  INNER JOIN [System].[Periodic:Values] V ON F.[Id] = V.[Field_Id]
  INNER HASH JOIN Deleted D ON V.[Key] = D.' + QuoteName(@KeyField) + N'
  OPTION (FORCE ORDER, MAXDOP 1)
'

      EXEC [SQL].[Debug Exec] @SQL = @SQL, @RaiseIfEmpty = 'Table Trigger :: Delete', @Debug = @Debug
    END ELSE BEGIN
      SELECT
        @SQL  = [Pub].[Concat]('DROP TRIGGER [System].' + QuoteName([name]), Char(13))
      FROM sys.objects WITH (NOLOCK)
      WHERE [parent_object_id] = @Object_Id AND [type] = 'TR'
      AND
      (
           [name] LIKE '% (Periodic Insert)'
        OR [name] LIKE '% (Periodic Update)'
        OR [name] LIKE '% (Periodic Delete)'
      )

      IF @SQL IS NOT NULL
        EXEC [SQL].[Debug Exec] @SQL = @SQL, @Debug = @Debug
    END

    -- 3 Interface for Insert
    SET @Object = '[System].' + QuoteName(@Name + '*Insert?Periodic')
    IF @Release = 0 AND @InterfaceView = 1 AND (@DateFirstNullAble IS NULL OR @DateFirstNullAble = 1) BEGIN
      -- 3.1 Interface View for Insert
      SELECT
        @SQL = CASE WHEN OBJECT_ID(@Object) IS NULL THEN 'CREATE' ELSE 'ALTER' END + ' VIEW ' + @Object + '
AS
  SELECT TOP 0'
          +
          [Pub].[Concat]
          (
            N'
    ' + QuoteName([name]),
            N','
          )
          + CASE
              WHEN @KeyFieldIdentity = 1 THEN ',
    [Row:Index]           = Cast(NULL AS Int)'
              ELSE ''
            END
          + ',
    [Row:Fields]          = Cast(NULL AS NVarChar(Max))'
          + CASE
              WHEN @DateFirstNullAble = 0 THEN ''
              ELSE ',
    [Periodic:Date]       = Cast(NULL AS Date)'
            END
          + CASE
              WHEN @Translate = 1 THEN ',
    [Translate:Language]  = Cast(NULL AS Char(2)) COLLATE Cyrillic_General_BIN'
              ELSE ''
            END
          + N'
  FROM ' + @Object_Name
      FROM sys.columns (NOLOCK)
      WHERE [object_id] = @Object_Id AND [is_identity] = 0 AND [is_computed] = 0

      EXEC [SQL].[Debug Exec] @SQL = @SQL, @RaiseIfEmpty = 'Interface View for Insert', @Debug = @Debug

      -- 3.2 Interface View Trigger :: Insert
      SET @Object = '[System].' + QuoteName(@Name + '*Insert?Periodic Instead Of Insert')
      SET @SQL = CASE WHEN OBJECT_ID(@Object) IS NULL THEN N'CREATE' ELSE N'ALTER' END + N' TRIGGER ' + @Object + N' ON [System].' + QuoteName(@Name + N'*Insert?Periodic') + N'
  INSTEAD OF INSERT
AS
  IF @@ROWCOUNT = 0 RETURN
  SET NOCOUNT ON'
          +
          CASE
            WHEN @KeyFieldIdentity = 1 THEN N'

  DECLARE @IDs TABLE([Key] Int NOT NULL PRIMARY KEY CLUSTERED, [Index] Int NOT NULL, UNIQUE ([Index])' + CASE WHEN @GUIdField IS NOT NULL THEN ', [GUId] Uniqueidentifier NOT NULL, UNIQUE ([GUId])' ELSE '' END + ')'
            ELSE N''
          END

          + N'
  BEGIN TRY'
          +
          CASE
            WHEN @Logging = 1 THEN N'
    EXEC [System].[Log@Begin]
'
            ELSE N''
          END
          +
          (
            SELECT
              N'
    ;MERGE ' + CASE WHEN @Translate = 1 THEN '[System].' + QuoteName(@Name + '*Insert?Translate') ELSE @Object_Name END + ' T
    USING
    (
      SELECT
        '
              +
              [Pub].[Concat]
              (
                QuoteName(SC.[name])
                +
                CASE
                  WHEN @Translate = 0 THEN
                    Replicate(N' ', [Pub].[Is Negative Int](22 - Len(SC.[name]), 0))
                    + N'= CASE WHEN [Pub].[In Array]([Row:Fields], ' + [Pub].[Quote String](SC.[name]) + ', '','') = 1 THEN ' + QuoteName(SC.[name]) + IsNull(N' ELSE ' + DC.[definition], N'') + ' END'
                  ELSE N''
                END,
                N',
        '
              )
              +
              CASE
                WHEN @KeyFieldIdentity = 1 THEN N',
        [Row:Index]'
                ELSE N''
              END
              +
              CASE
                WHEN @Translate = 1 THEN N',
        [Row:Fields],
        [Translate:Language]'
                ELSE N''
              END
              + N'
      FROM Inserted
      WHERE [System].[Raise Error]
            (
              @@PROCID,
              CASE
                WHEN ' + QuoteName(CASE WHEN @KeyFieldIdentity = 1 THEN 'Row:Index' ELSE @KeyField END) + ' IS NULL THEN
                  ''Значение поля ' + QuoteName(CASE WHEN @KeyFieldIdentity = 1 THEN 'Row:Index' ELSE @KeyField END) + ' не может быть NULL'''
              + CASE
                  WHEN @DateFirstNullAble = 1 THEN N'
                WHEN ' + QuoteName(@DateFirstField) + ' <> [Periodic:Date] THEN
                  ''Дата создания записи не совпадает с датой периодического её заведения.'''
                  ELSE N''
                END
              + CASE
                  WHEN @Translate = 1 THEN '
                WHEN [Translate:Language] IS NULL THEN
                  ''Значение поля [Translate:Language] не может быть NULL'''
                  ELSE N''
                END
              + N'
              END
            ) IS NULL
    ) S ON 1 = 0
    WHEN NOT MATCHED BY TARGET THEN
      INSERT (' + CASE WHEN @KeyFieldIdentity = 1 AND @Translate = 1 THEN '[Row:Index], ' ELSE N'' END + CASE WHEN @Translate = 1 THEN '[Row:Fields], ' ELSE N'' END + [Pub].[Concat](QuoteName(SC.[name]), N', ') + CASE WHEN @Translate = 1 THEN N', [Translate:Language]' ELSE N'' END + N')
      VALUES (' + CASE WHEN @KeyFieldIdentity = 1 AND @Translate = 1 THEN 'S.[Row:Index], ' ELSE N'' END + CASE WHEN @Translate = 1 THEN 'S.[Row:Fields], ' ELSE N'' END + [Pub].[Concat](N'S.' + QuoteName(SC.[name]), N', ') + CASE WHEN @Translate = 1 THEN N', S.[Translate:Language]' ELSE N'' END + N')'

              +
              CASE
                WHEN @KeyFieldIdentity = 1 AND @Translate = 0 THEN '
    OUTPUT Inserted.' + QuoteName(@KeyField) + ', S.[Row:Index] INTO @IDs([Key], [Index])'
                ELSE N''
              END
              + N';'
            FROM sys.columns SC WITH (NOLOCK)
            LEFT JOIN sys.default_constraints DC WITH (NOLOCK) ON DC.[parent_object_id] = @Object_Id AND SC.[column_id] = DC.[parent_column_id]
            WHERE SC.[object_id] = @Object_Id AND (SC.[is_identity] = 0 AND SC.[is_computed] = 0/* OR @Translate = 1 AND SC.[name] = @KeyField*/)
          )

          +
          CASE
            WHEN @KeyFieldIdentity = 1 AND @Translate = 1 THEN N'

    INSERT INTO @IDs([Key], [Index]' + CASE WHEN @GUIdField IS NOT NULL THEN N', [GUId]' ELSE N'' END + N')
    SELECT
      [Key]   = [Identity],
      [Index] = [Index]'
              +
              CASE
                WHEN @GUIdField IS NOT NULL THEN N',
      [GUId]  = [GUId]'
                ELSE N''
              END
              + N'
    FROM [System].[Scope Identities]'
            ELSE ''
          END

          +
          CASE
            WHEN @DateFirstField IS NULL OR @DateFirstNullAble = 1 THEN N'

    UPDATE V SET
      [Date] = I.[Periodic:Date]
    FROM Inserted I'
              +
              CASE
                WHEN @KeyFieldIdentity = 1 THEN N'
    INNER JOIN @IDs ID ON I.[Row:Index] = ID.[Index]'
                ELSE N''
              END
              + N'
    CROSS JOIN (VALUES ' + @Values_Id + N') F([Id])
    INNER JOIN [System].[Periodic:Values] V ON F.[Id] = V.[Field_Id] AND ' + CASE WHEN @KeyFieldIdentity = 1 THEN N'ID.[Key]' ELSE N'I.' + QuoteName(@KeyField) END + N' = V.[Key] AND V.[Date] <> I.[Periodic:Date]'
            ELSE N''
          END

          +
          CASE
            WHEN @Translate_Fields_PIDs IS NOT NULL THEN N'

    UPDATE VT SET
      [Language] = I.[Translate:Language]
    FROM Inserted I'
              +
              CASE
                WHEN @KeyFieldIdentity = 1 THEN N'
    INNER JOIN @IDs ID ON I.[Row:Index] = ID.[Index]'
                ELSE N''
              END
              + N'
    CROSS JOIN (VALUES ' + @Values_Id + N') F([Id])
    INNER JOIN [System].[Periodic:Values] V ON F.[Id] = V.[Field_Id] AND ' + CASE WHEN @KeyFieldIdentity = 1 THEN 'ID.[Key]' ELSE 'I.' + QuoteName(@KeyField) END + ' = V.[Key]
    INNER JOIN [System].[Periodic:Values:Translate] VT ON F.[Id] = VT.[Field_Id] AND ' + CASE WHEN @KeyFieldIdentity = 1 THEN 'ID.[Key]' ELSE 'I.' + QuoteName(@KeyField) END + ' = VT.[Key] AND V.[Date] = VT.[Date] AND VT.[Language] <> I.[Translate:Language]'
            ELSE N''
          END
          +
          CASE
            WHEN @KeyFieldIdentity = 1 THEN N'

    INSERT INTO [System].[Scope Identities]([Identity], [Index]' + CASE WHEN @GUIdField IS NOT NULL THEN N', [GUId]' ELSE N'' END + N')
    SELECT
      [Identity]  = [Key],
      [Index]     = [Index]'
              +
              CASE
                WHEN @GUIdField IS NOT NULL THEN N',
      [GUId]      = [GUId]'
                ELSE N''
              END
            + N'
    FROM @IDs'
            ELSE N''
          END
          +
          CASE
            WHEN @Logging = 1 THEN N'

    EXEC [System].[Log@Commit]'
            ELSE N''
          END
          + N'
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 AND XACT_STATE() <> 0 ROLLBACK TRAN
    EXEC [System].[ReRaise Error] @ProcedureId = @@PROCID
  END CATCH'

      EXEC [SQL].[Debug Exec] @SQL = @SQL, @RaiseIfEmpty = 'Interface View Trigger :: Insert', @Debug = @Debug
    END ELSE IF OBJECT_ID(@Object, 'V') IS NOT NULL BEGIN
      SET @SQL = 'DROP VIEW ' + @Object
      EXEC [SQL].[Debug Exec] @SQL = @SQL, @Debug = @Debug
    END

    -- 4 Interface for Update
    SET @Object = '[System].' + QuoteName(@Name + '*Update?Periodic')
    IF @InterfaceView = 1 BEGIN
      -- 4.1 Interface View for Update
      SET @SQL = CASE WHEN OBJECT_ID(@Object) IS NULL THEN 'CREATE' ELSE 'ALTER' END + ' VIEW ' + @Object + N'
AS
  SELECT
    *,
    [Periodic:Date]       = Cast(NULL AS Date)'
          + CASE
              WHEN @Translate = 1 THEN ',
    [Translate:Language]  = Cast(NULL AS Char(2)) COLLATE Cyrillic_General_BIN'
              ELSE ''
            END
          + ',
    [Row:Fields]          = Cast(NULL AS NVarChar(Max))
  FROM ' + @Object_Name

      EXEC [SQL].[Debug Exec] @SQL = @SQL, @RaiseIfEmpty = 'Interface View for Update', @Debug = @Debug

      -- 4.2 Interface View Trigger :: Update
      SET @Object = '[System].' + QuoteName(@Name + '*Update?Periodic Instead Of Update')
      SET @SQL = CASE WHEN OBJECT_ID(@Object) IS NULL THEN 'CREATE' ELSE 'ALTER' END + ' TRIGGER ' + @Object + ' ON [System].' + QuoteName(@Name + '*Update?Periodic') + N'
  INSTEAD OF INSERT, UPDATE
AS
  DECLARE
    @ROWCOUNT     Int,
    @Updated      Bit,
    @NotNullDate  Int,
    @Today        Date

  SET @ROWCOUNT = @@ROWCOUNT
  IF @ROWCOUNT = 0 RETURN

  SET NOCOUNT ON

  DECLARE @Periodic TABLE
  (
    [Key]       Int                                     NOT NULL,
    [Date]      Date                                    NOT NULL,'
          +
          CASE
            WHEN @Translate_Fields_PIDs IS NOT NULL THEN N'
    [Language]  Char(2) COLLATE Cyrillic_General_BIN        NULL,'
            ELSE N''
          END
          + N'
    [Value]     SQL_Variant                                 NULL,
    PRIMARY KEY CLUSTERED ([Key])
  )

  BEGIN TRY'
          +
          CASE
            WHEN @Logging = 1 THEN N'
    EXEC [System].[Log@Begin]
'
            ELSE N''
          END
          + N'
    SET @Today = [Pub].[Today]()
'
          +
          CASE
            WHEN @DateFirstField IS NOT NULL THEN N'
    IF Update(' + QuoteName(@DateFirstField) + N')
      UPDATE T SET
        ' + QuoteName(@DateFirstField) + N'= I.' + QuoteName(@DateFirstField) + N'
      FROM Deleted D, Inserted I, ' + @Object_Name + N' T
      WHERE D.' + QuoteName(@KeyField) + ' = I.' + QuoteName(@KeyField) + N'
        AND ' + CASE WHEN @DateFirstNullAble = 1 THEN 'I.' + QuoteName(@DateFirstField) + N' IS NOT NULL AND (D.' + QuoteName(@DateFirstField) + N' IS NULL OR ' ELSE N'(' END + N'D.' + QuoteName(@DateFirstField) + N' <> I.' + QuoteName(@DateFirstField) + N')
        AND I.' + QuoteName(@KeyField) + N' = T.' + QuoteName(@KeyField) + N'
'
            ELSE N''
          END
          + N'
    SELECT
      @NotNullDate  = COUNT(Distinct I.' + QuoteName(@KeyField) + N')
    FROM Inserted I
    CROSS JOIN (VALUES ' + @Values_IdAndName + N') F([Id], [Name])
    LEFT JOIN [System].[Periodic:Values] V WITH (SERIALIZABLE) ON I.' + QuoteName(@KeyField) + N' = V.[Key] AND V.[Field_Id] = F.[Id] AND V.[NextDate] IS NULL
    WHERE I.[Periodic:Date] IS NOT NULL
        AND [System].[Raise Error]
            (
              @@PROCID,
              CASE
                WHEN I.' + QuoteName(@KeyField) + N' IS NULL
                  THEN ' + [Pub].[Quote String](N'Поле ' + QuoteName(@KeyField) + N' периодической записи не может быть «NULL».') + N'
                WHEN V.[PriorDate] IS NULL AND V.[Date] > I.[Periodic:Date]
                  THEN ''Для периодической записи (Id = '' + CAST(I.' + QuoteName(@KeyField) + N' AS NVarChar) + '') дата изменения поля ('' + convert(VarChar, I.[Periodic:Date], 104) + '') не должна быть меньше даты заведения записи ('' + convert(VarChar, V.[Date], 104) + '').''
                WHEN V.[Date] IS NULL
                  THEN ''Для периодической записи (Id = '' + CAST(I.' + QuoteName(@KeyField) + N' AS NVarChar) + '') поле '' + QuoteName(F.[Name]) + '' не имеет периодического значения.'''
  + CASE
      WHEN @Future = 0 THEN N'
                WHEN I.[Periodic:Date] > @Today
                  THEN ''Для периодической записи (Id = '' + CAST(I.' + QuoteName(@KeyField) + N' AS NVarChar) + '') изменение не может быть сохранено будущим числом ('' + convert(VarChar, I.[Periodic:Date], 104) + '').'''
      ELSE N''
    END
  + N'
              END
            ) IS NULL

    IF @NotNullDate <> @ROWCOUNT
      RaisError(''Не указана дата периодического изменения записи.'', 16, 2)'

        SET @Field_Id = 0
        WHILE 1 = 1 BEGIN
          SELECT TOP 1
            @Field_Id       = PF.[PeriodicField_Id],
            @FieldName      = PF.[Name],
            @FieldType      = PF.[Type_Full],
            @FieldNullAble  = PF.[IsNullable],
            @FieldTranslate = CASE WHEN PF.[TranslateField_Id] IS NOT NULL THEN 1 ELSE 0 END
          FROM @AllFields PF
          WHERE PF.[PeriodicField_Id] > @Field_Id
          ORDER BY PF.[PeriodicField_Id]

          IF @@ROWCOUNT = 0 BREAK
          SET @SQL += N'

    IF Update(' + QuoteName(@FieldName) + ') BEGIN
      DELETE FROM @Periodic
      INSERT INTO @Periodic ([Key], [Date], ' + CASE WHEN @FieldTranslate = 1 THEN '[Language], ' ELSE '' END + '[Value])
      SELECT
        [Key]      = I.' + QuoteName(@KeyField) + ',
        [Date]     = I.[Periodic:Date],'
          + CASE
              WHEN @FieldTranslate = 1 THEN '
        [Language] = I.[Translate:Language],'
              ELSE ''
            END
          + N'
        [Value]    = I.' + QuoteName(@FieldName) + '
      FROM Inserted I
      CROSS APPLY [System].[Periodic:Field:Value@Info](' + CAST(@Field_Id AS NVarChar) + ', I.' + QuoteName(@KeyField) + ', I.[Periodic:Date], ' + CASE WHEN @FieldTranslate = 1 THEN 'I.[Translate:Language]' ELSE 'Default' END + ') V
      WHERE [Pub].[In Array](I.[Row:Fields], ' + [Pub].[Quote String](@FieldName) + N', '','') = 1 AND /*I.[Periodic:Date] = V.[Date] OR*/ ' + CASE WHEN @FieldNullAble = 1 THEN '[Pub].[Is Equal Variants](I.' + QuoteName(@FieldName) + ', V.[Value]) = 0' ELSE 'I.' + QuoteName(@FieldName) + ' <> Cast(V.[Value] AS ' + @FieldType + ')' END + '

      IF @@ROWCOUNT > 0 BEGIN
        SET @Updated = 1

        UPDATE V SET
          [PriorDate] = NULL,
          [NextDate]  = NULL
        FROM (SELECT DISTINCT [Key] FROM @Periodic) P
        INNER JOIN [System].[Periodic:Values] V ON V.[Field_Id] = ' + Cast(@Field_Id AS NVarChar) + ' AND V.[Key] = P.[Key]

        MERGE [System].[Periodic:Values' + CASE WHEN @FieldTranslate = 1 THEN N'*Update?Translate' ELSE N'' END + N'] V
        USING @Periodic P ON V.[Field_Id] = ' + CAST(@Field_Id AS NVarChar) + N' AND P.[Key] = V.[Key] AND P.[Date] = V.[Date]
        WHEN MATCHED THEN UPDATE SET
          [Value] = P.[Value]' + CASE WHEN @FieldTranslate = 1 THEN N', [Language] = P.[Language]' ELSE N'' END + N'
        WHEN NOT MATCHED BY TARGET THEN
          INSERT ([Field_Id], [Key], [Date], [Value]' + CASE WHEN @FieldTranslate = 1 THEN N', [Language]' ELSE N'' END + N')
          VALUES (' + CAST(@Field_Id AS NVarChar) + N', P.[Key], P.[Date], P.[Value]' + CASE WHEN @FieldTranslate = 1 THEN N', [Language]' ELSE N'' END + N');

        DELETE V
        FROM @Periodic P
        CROSS APPLY (SELECT TOP 1 PN.[Date], PN.[Value] FROM [System].[Periodic:Values] PN WHERE PN.[Key] = P.[Key] AND PN.[Field_Id] = ' + Cast(@Field_Id AS NVarChar) + ' AND PN.[Date] > P.[Date] ORDER BY PN.[Date]) PN
        INNER JOIN [System].[Periodic:Values] V ON V.[Date] = PN.[Date] AND V.[Field_Id] = ' + CAST(@Field_Id AS NVarChar) + ' AND V.[Key] = P.[Key]
        WHERE ' + CASE WHEN @FieldNullAble = 0 THEN 'P.[Value] = PN.[Value]' ELSE '[Pub].[Is Equal Variants](P.[Value], PN.[Value]) = 1' END + '

        UPDATE V SET
          [PriorDate] = PP.[Date],
          [NextDate]  = PN.[Date]
        FROM (SELECT DISTINCT [Key] FROM @Periodic) P
        INNER JOIN [System].[Periodic:Values] V ON V.[Field_Id] = ' + Cast(@Field_Id AS NVarChar) + N' AND V.[Key] = P.[Key]
        OUTER APPLY (SELECT TOP 1 PP.[Date] FROM [System].[Periodic:Values] PP WHERE PP.[Key] = P.[Key] AND PP.[Field_Id] = ' + Cast(@Field_Id AS NVarChar) + ' AND PP.[Date] < V.[Date] ORDER BY PP.[Date] DESC) PP
        OUTER APPLY (SELECT TOP 1 PN.[Date] FROM [System].[Periodic:Values] PN WHERE PN.[Key] = P.[Key] AND PN.[Field_Id] = ' + Cast(@Field_Id AS NVarChar) + ' AND PN.[Date] > V.[Date] ORDER BY PN.[Date]) PN
      END
    END
'
        END

        SET @SQL += N'
    IF '
          +
          (
            SELECT
              IsNull
              (
                [Pub].[Concat](CASE WHEN PF.[Id] IS NULL AND SF.[Name] <> @KeyField THEN 'Update(' + QuoteName(SF.[Name]) + ') OR ' END,
                ''
              ), '')
              + '@Updated = 1'
              +
              CASE
                WHEN @Translate = 0 THEN N'
      UPDATE T SET
          '
                  +
                  [Pub].[Concat]
                  (
                    CASE
                      WHEN SF.[Name] <> @KeyField THEN
                        [SQL].[Shift](QuoteName(SF.[Name]), 26)
                        + N'= '
                        +
                        CASE
                          WHEN PF.[Id] IS NULL THEN 'CASE WHEN [Pub].[In Array](I.[Row:Fields], ' + [Pub].[Quote String](SF.[Name]) + ', '','') = 1 THEN I.' + QuoteName(SF.[Name]) + N' ELSE T.' + QuoteName(SF.[Name]) + N' END'
                          ELSE 'P' + '.' + QuoteName(SF.[Name])
                        END
                    END,
                    N'
        , '
                  )
                  + N'
      FROM Inserted I
      INNER JOIN ' + @Object_Name + ' T ON I.' + QuoteName(@KeyField) + ' = T.' + QuoteName(@KeyField) + '
      CROSS APPLY ' + QuoteName(@Name + '@Periodic') + '([Pub].[Today]()) P
      WHERE I.' + QuoteName(@KeyField) + ' = P.' + QuoteName(@KeyField)
                ELSE N'
      INSERT INTO [System].' + QuoteName(@Name + '*Update?Translate')
                  + ' ([Row:Fields], [Translate:Language], '
                  + [Pub].[Concat](QuoteName(SF.[Name]), ', ')
                  + ')
      SELECT
        [Row:Fields]              = I.[Row:Fields],
        [Translate:Language]      = I.[Translate:Language],
        '
                  + [Pub].[Concat]
                    (
                      [SQL].[Shift](QuoteName(SF.[Name]), 26)
                      + N'= '
                      + CASE WHEN PF.[Id] IS NULL THEN 'I' ELSE 'P' END
                      + '.'
                      + QuoteName(SF.[Name])
                      , N',
        '
                    )
                  + N'
      FROM Inserted I
      CROSS APPLY [System].' + QuoteName(@Name + '@Periodic') + '([Pub].[Today](), I.[Translate:Language]) P
      WHERE I.' + QuoteName(@KeyField) + ' = P.' + QuoteName(@KeyField)
              END
            FROM sys.columns SF WITH (NOLOCK)
            LEFT JOIN [System].[Periodic->Fields] PF ON PF.[Table_Id] = @Table_Id AND SF.[Name] = PF.[Name]
            WHERE SF.[object_id] = @Object_Id AND SF.[is_computed] = 0 AND (@DateFirstField IS NULL OR @DateFirstField <> SF.[Name])
          )
          +
          CASE
            WHEN @Logging = 1 THEN N'

    EXEC [System].[Log@Commit]'
            ELSE N''
          END
          + N'
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 AND XACT_STATE() <> 0 ROLLBACK TRAN
    EXEC [System].[ReRaise Error] @ProcedureId = @@PROCID
  END CATCH'

      EXEC [SQL].[Debug Exec] @SQL = @SQL, @RaiseIfEmpty = 'Interface View Trigger :: Update', @Debug = @Debug
    END ELSE IF OBJECT_ID(@Object) IS NOT NULL BEGIN
      SET @SQL = N'DROP VIEW ' + @Object
      EXEC [SQL].[Debug Exec] @SQL = @SQL, @Debug = @Debug
    END

    -- 5. Interface Procedure :: Set
    SET @Object = '[System].' + QuoteName(@Name + '(Periodic Set)')
    IF @Release = 0 AND @InterfaceProc = 1 AND @TableHaveVariantField = 0 BEGIN
      SET @SQL = CASE WHEN OBJECT_ID(@Object) IS NULL THEN N'CREATE' ELSE N'ALTER' END + N' PROCEDURE ' + @Object + N'
  @Data  XML
AS
  SET NOCOUNT ON

  DECLARE
    @Today        Date,
    @RowCount_P   Int,
    @SubData      XML'

      + CASE
          WHEN @Translate = 1 THEN N',
    @Data_T_ID    XML,
    @Data_T_U     XML'
          ELSE N''
        END
      + N'

  DECLARE
    @TranCount    Int,
    @Retry        TinyInt,
    @ErrorNumber  Int
'
      +
      (
        SELECT
          N'
  DECLARE @Inserted TABLE
  (
    [Index]     Int               NOT NULL,
    [GUId]      UniqueIdentifier  NOT NULL,
    [Identity]  BigInt            NOT NULL,
    PRIMARY KEY CLUSTERED ([Index])
  )

  DECLARE @Records TABLE
  (
    [Row:Action]              Char(1) COLLATE Cyrillic_General_BIN  NOT NULL'
          +
          CASE
            WHEN @KeyFieldIdentity = 1 THEN ',
    [Row:Index]               Int                   NULL'
            ELSE N''
          END

          + N',
    [Row:Fields]              NVarChar(Max)         NULL,
    [Row:Fields:Periodic]     NVarChar(Max)         NULL'

          +
          CASE
            WHEN @Translate = 1 THEN N',
    [Row:Fields:Translate]    NVarChar(Max)         NULL'
            ELSE N''
          END
          + N',
    [Row:Version]             TinyInt           NOT NULL,'
          + CASE
              WHEN @Translate = 1 THEN N'
                                                        -- 0 = RECORD/PERIODIC                                          = MONO LANGUAGE SET
                                                        -- 1 = RECORD/(TRANSLATE + PERIODIC + PERIODIC/TRANSLATE)       = MULTI LANGUAGE SET
                                                        -- 2 = RECORD/FIELD/(TRANSLATE + PERIODIC + PERIODIC/TRANSLATE) = EXPANDED FIELDS SET'
              ELSE N'
                                                        -- 0 = RECORD/PERIODIC        = DEFAULT SET
                                                        -- 2 = RECORD/FIELD/PERIODIC  = EXPANDED FIELDS SET'
            END

          + N'
    [Row:Data]                XML                   NULL,
    [Periodic:Age]            Date              NOT NULL,'
          +
          CASE
            WHEN @ListFieldsExists = 1 THEN N'
    [Periodic:Age:Old]        Date                  NULL,'
            ELSE N''
          END
          +
          CASE
            WHEN @ActiveMethod IS NOT NULL THEN N'
    [Periodic:Active:Age]     Date                  NULL,'
            ELSE N''
          END

          +
          CASE
            WHEN @GUIdField IS NULL THEN N'
    [Periodic:GUId]           UniqueIdentifier  NOT NULL,'
            ELSE N''
          END

          +
          CASE
            WHEN @Translate = 1 THEN N'
    [Translate:Language]      Char(2) COLLATE Cyrillic_General_BIN      NULL,'
            ELSE N''
          END
          + N'
'

          +
          [Pub].[Concat]
          (
            N'
    '
            + [SQL].[Shift](QuoteName(SF.[Name]), 25)
            + N' ' + SF.[Type_Full] + IsNull(N' COLLATE ' + SF.[Collation], N'')
            + CASE WHEN SF.[Name] = @GUIdField THEN N' NOT NULL' ELSE N'' END
            , N','
          )
          + N',
    PRIMARY KEY CLUSTERED (' + QuoteName(IsNull(@GUIdField, 'Periodic:GUId')) + ')'
          +
          CASE
            WHEN @KeyFieldIdentity = 0 THEN N',
    UNIQUE (' + QuoteName(@KeyField) + ')'
            ELSE ''
          END
          + N'
  )'
          +
          CASE
            WHEN @Translate = 1 THEN N'

  DECLARE @Translate TABLE
  (
    [Field_Id]      SmallInt          NOT NULL,
    [GUId]          UniqueIdentifier  NOT NULL,
    [Language]      Char(2) COLLATE Cyrillic_General_BIN  NOT NULL,
    [Value]         NVarChar(Max)         NULL,
    PRIMARY KEY CLUSTERED ([Field_Id], [GUId], [Language])
  )'
            ELSE N''
          END

          + N'

  DECLARE @Periodic TABLE
  (
    [Field_Id]      SmallInt          NOT NULL,
    [GUId]          UniqueIdentifier  NOT NULL,
    [Date]          Date              NOT NULL,
    [Value]         SQL_Variant           NULL,
    [PriorDate]     Date                  NULL,
    [NextDate]      Date                  NULL,
    PRIMARY KEY CLUSTERED ([Field_Id], [GUId], [Date])
  )

  DECLARE @PeriodicFields TABLE
  (
    [Field_Id]      SmallInt          NOT NULL,
    [GUId]          UniqueIdentifier  NOT NULL
    PRIMARY KEY CLUSTERED ([Field_Id], [GUId])
  )'
          +
          CASE
            WHEN @Translate_Fields_PIDs IS NOT NULL THEN N'

  DECLARE @Periodic_T TABLE
  (
    [Field_Id]            SmallInt          NOT NULL,
    [GUId]                UniqueIdentifier  NOT NULL,
    [Date]                Date              NOT NULL,
    [Translate:Language]  Char(2) COLLATE Cyrillic_General_BIN  NOT NULL,
    [Value]               NVarChar(4000)        NULL,
    [PriorDate]           Date                  NULL,
    [NextDate]            Date                  NULL,
    PRIMARY KEY CLUSTERED ([Field_Id], [GUId], [Date], [Translate:Language])
  )'
            ELSE N''
          END

          +
          CASE
            WHEN @ListFieldsExists = 1 THEN
              [Pub].[Concat]
              (
                CASE
                  WHEN SF.[PeriodicFieldKind] = 'L' THEN N'

  DECLARE @Periodic' + Cast(SF.[PeriodicField_Id] AS NVarChar) + N' TABLE
  (
    [Row:GUId]          UniqueIdentifier  NOT NULL,
    [Periodic:Date]     Date              NOT NULL,
    '
                    +
                    [TParams]::[Format]
                    (
                      N':{N|String=20}:{T|String=18}NOT NULL',
                      [TParams]::[New]()
                        .[Add]('N', QuoteName(SF.[ForeignList]))
                        .[Add]('T', [SQL].[Object:Field@Type](QuoteName(SF.[ForeignTableSchema]) + N'.' + QuoteName(SF.[ForeignTableName]), SF.[ForeignList], 'S'))
                    )
                    + N',
    PRIMARY KEY CLUSTERED([Row:GUId], ' + QuoteName(SF.[ForeignList]) + N', [Periodic:Date])
  )'
                END
                , N''
              )
            ELSE N''
          END

          + N'

  BEGIN TRY
    SET @Today = [Pub].[Today]()

    INSERT INTO @Records
    (
      [Row:Action]'
          + CASE WHEN @KeyFieldIdentity = 1 THEN N', [Row:Index]' ELSE N'' END
          + N', [Row:Fields], [Row:Fields:Periodic], '
          + CASE WHEN @Translate = 1 THEN N'[Row:Fields:Translate], ' ELSE N'' END
          + N'[Row:Version], [Row:Data], [Periodic:Age], '
          + CASE WHEN @ListFieldsExists = 1 THEN N'[Periodic:Age:Old], ' ELSE N'' END
          + CASE WHEN @ActiveMethod IS NOT NULL THEN '[Periodic:Active:Age], ' ELSE N'' END
          + CASE WHEN @GUIdField IS NULL THEN N'[Periodic:GUId], ' ELSE N'' END
          + CASE WHEN @Translate = 1 THEN N'[Translate:Language], ' ELSE N'' END
          + N'
      '
          + [Pub].[ConCat](QuoteName(SF.[Name]), N', ')
          + N'
    )
    SELECT'
          +
          CASE
            WHEN @ActiveMethod IS NOT NULL THEN N'
      [Row:Action]              = CASE WHEN I.[Row:Action] <> ''U'' OR AF.[Periodic:Active:Need Check] IS NULL OR AF.[Periodic:Active:Age] IS NOT NULL THEN I.[Row:Action] ELSE ''D'' END'
            ELSE N'
      [Row:Action]              = I.[Row:Action]'
          END
          +
          CASE
            WHEN @KeyFieldIdentity = 1 THEN N',
      [Row:Index]               = CASE WHEN I.[Row:Action] = ''I'' THEN I.[Row:Index] END'
            ELSE N''
          END
          -- ' + CASE WHEN @ActiveMethod IS NOT NULL THEN 'CASE WHEN AF.[Periodic:Active:Age] > IA.[Periodic:Age] THEN [Pub].[Arrays Merge]' ELSE '
          + N',
      [Row:Fields]              = ' + IsNull('CASE WHEN I.[Row:Action] = ''I'' THEN [Pub].[Arrays Merge](I.[Row:Fields], ' + [Pub].[Quote String](@InterfaceProcDefaultFields) + ', '','') ELSE I.[Row:Fields] END', 'I.[Row:Fields]') + N',
      [Row:Fields:Periodic]     = CASE WHEN I.[Row:Action] = ''D'' THEN NULL ELSE [Pub].[Arrays Join](I.[Row:Fields], ' + [Pub].[Quote String]((SELECT [Pub].[Concat](PF.[Name], N',') FROM @AllFields PF WHERE PF.[PeriodicField_Id] IS NOT NULL)) + N', '','') END'
          +
          CASE
            WHEN @Translate = 1 THEN N',
      [Row:Fields:Translate]    = CASE WHEN I.[Row:Action] = ''D'' THEN NULL ELSE [Pub].[Arrays Join](I.[Row:Fields], ' + [Pub].[Quote String]((SELECT [Pub].[Concat](TF.[Name], ',') FROM @AllFields TF WHERE TF.[TranslateField_Id] IS NOT NULL)) + ', '','') END'
            ELSE N''
          END
          + N',
      [Row:Version]             = I.[Row:Version],
      [Row:Data]                = I.[Row:Data],
      [Periodic:Age]            = IA.[Periodic:Age],'
          +
          CASE
            WHEN @ListFieldsExists = 1 THEN N'
      [Periodic:Age:Old]        = RI.[Age],'
            ELSE N''
          END
          +
          CASE
            WHEN @ActiveMethod IS NOT NULL THEN N'
      [Periodic:Active:Age]     = CASE WHEN AF.[Periodic:Active:Age] > IA.[Periodic:Age] THEN AF.[Periodic:Active:Age] END,'
            ELSE N''
          END
          +
          CASE
            WHEN @GUIdField IS NULL THEN N'
      [Periodic:GUId]           = NEWID(),'
            ELSE N''
          END
          +
          CASE
            WHEN @Translate = 1 THEN N'
      [Translate:Language]      = I.[Translate:Language],'
            ELSE N''
          END
          +
          [Pub].[ConCat]
          (
            N'
      '
            + [SQL].[Shift](QuoteName(SF.[Name]), 26)
            + N'= I.'
            + QuoteName(SF.[Name])
            , N','
          )
          + N'
    FROM
    (
      SELECT
        [Row:Action]              = B.[Row:Action]'

          +
          CASE
            WHEN @KeyFieldIdentity = 1 THEN N',
        [Row:Index]               = B.[Row:Index]'
            ELSE N''
          END

          + N',
        [Row:Fields]              = BF.[Row:Fields],
        [Row:Version]             = B.[Row:Version],
        [Row:Data]                = CASE
                                      WHEN B.[Row:Action] = ''D'' THEN NULL
                                      WHEN B.[Row:Version] = 2 THEN I.Node.query(''FIELD'')'
          +
          CASE
            WHEN @Translate = 1 THEN N'
                                      WHEN B.[Row:Version] = 1 THEN (SELECT I.Node.query(''PERIODIC''), I.Node.query(''TRANSLATE'') FOR XML PATH(''''), TYPE)'
            ELSE N''
          END
          + N'
                                      ELSE I.Node.query(''PERIODIC'')
                                    END,'

          +
          CASE
            WHEN @DateFirstField IS NULL OR @DateFirstNullAble = 1 THEN '
        [Periodic:Age]            = CASE WHEN Priv.[#:AGE] = 1 THEN I.Node.value(''@AGE[1]'', ''Date'') WHEN B.[Row:Action] = ''I'' THEN @Today END,'
              ELSE N''
          END

          +
          CASE
            WHEN @Translate = 1 THEN N'
        [Translate:Language]      = I.Node.value(''@LANGUAGE[1]'', ''Char(2)'') COLLATE Cyrillic_General_BIN,'
            ELSE N''
          END

          + N'
        Priv.*,'

          +
          [Pub].[ConCat]
          (
            N'
        '
            + [SQL].[Shift](QuoteName(SF.[Name]), 26)
            + N'= '
            +
            CASE
              WHEN SF.[Name] = @KeyField THEN
                CASE
                  WHEN @KeyFieldIdentity = 1 THEN N''  -- Всегда (для режима "I" будет проверка)
                  ELSE 'CASE WHEN B.[Row:Action] <> ''I'' OR Priv.' + QuoteName(N'#:' + @KeyField) + ' = 1 THEN '
                END
              ELSE
                N'CASE WHEN Priv.' + QuoteName(N'#:' + SF.[Name]) + ' = 1 THEN '
            END

-- <Value>
            + CASE WHEN SF.[Type_Short] = 'XML' THEN '[Pub].[XML Record@InnerXml](' ELSE '' END
            + 'I.Node.'
            +
            CASE
              WHEN SF.[Type_Short] = 'XML' THEN
                'query('
                + [Pub].[Quote String](SF.[Name])
                + ')'
              ELSE
                'value('
                + [Pub].[Quote String]('@' + SF.[Name] + '[1]')
                + ', '
                + [Pub].[Quote String](SF.[Type_Full])
                + ')'
            END

            + CASE WHEN SF.[Type_Short] = 'XML' THEN ', ' + [Pub].[Quote String](SF.[Name]) + ')' ELSE '' END
-- </Value>
            +
            CASE
              WHEN SF.[Name] = @KeyField THEN
                CASE
                  WHEN @KeyFieldIdentity = 1 THEN N''  -- Всегда (для режима "I" будет проверка)
                  ELSE IsNull(' ELSE ' + SF.[DefaultConstraint], '') + ' END'
                END
              ELSE
                CASE
                  WHEN SF.[Name] = @GUIdField AND (SF.[DefaultConstraint] IS NULL OR SF.[DefaultConstraint] = '(newid())') THEN ' ELSE NEWID()'
                  WHEN SF.[Name] = @GUIdField AND SF.[DefaultConstraint] IS NOT NULL THEN ' WHEN B.[Row:Action] = ''I'' THEN ' + SF.[DefaultConstraint] + N' ELSE NEWID()'
                  WHEN SF.[DefaultConstraint] IS NOT NULL THEN ' WHEN B.[Row:Action] = ''I'' THEN ' + SF.[DefaultConstraint]
                  ELSE N''
                END
                + ' END'
            END
            , N','
          )

          + N'
      FROM @Data.nodes(''RECORD'') AS I (Node)
      CROSS APPLY
      (
        SELECT
          [Row:Action]          = I.Node.value(''@ACTION[1]'', ''Char(1)'') COLLATE Cyrillic_General_BIN'
          + CASE
              WHEN @KeyFieldIdentity = 1 THEN ',
          [Row:Index]           = I.Node.value(''@INDEX[1]'', ''Int'')'
              ELSE ''
            END
          + ',
          [Row:Version]         = CASE
                                    WHEN I.Node.exist(''FIELD/@NAME'') = 1 THEN 2'
          + CASE
              WHEN @Translate = 1 THEN N'
                                    WHEN I.Node.exist(''PERIODIC/TRANSLATE/@LANGUAGE'') = 1 OR I.Node.exist(''TRANSLATE/@LANGUAGE'') = 1 THEN 1'
              ELSE N''
            END
          + N'
                                    ELSE 0
                                  END
      ) B
      CROSS APPLY
      (
        VALUES
        (
          CASE WHEN B.[Row:Action] IN (''I'', ''U'') THEN [Pub].[Arrays Join](I.Node.value(''@FIELDS[1]'', ''NVarChar(Max)''), '
          + [Pub].[Quote String](@InterfaceProcModifiableFields + CASE WHEN @DateFirstField IS NULL OR @DateFirstNullAble = 1 THEN N',AGE' ELSE N'' END)
          + N', '','') END
        )
      ) BF([Row:Fields])
      OUTER APPLY'
          +
          [SQL].[Generate?Field Test]
          (
            @InterfaceProcModifiableFields + CASE WHEN @DateFirstField IS NULL OR @DateFirstNullAble = 1 THEN N',AGE' ELSE N'' END,
            N'BF.[Row:Fields]',
            3,
            N'#:'
          ) + N' Priv
      WHERE [System].[Raise Error]
            (
              @@PROCID,
              CASE
                WHEN B.[Row:Action] IS NULL OR B.[Row:Action] NOT IN (''I'', ''U'', ''D'') THEN ''Недопустимое значение аттрибута [ACTION] = '' + IsNull(''«'' + Cast(B.[Row:Action] AS NVarChar(2)) + ''»'', ''NULL'')
              END
            ) IS NULL
    ) I
    LEFT JOIN ' + @Object_Name + ' T WITH (UPDLOCK) ON I.[Row:Action] <> ''I'' AND I.' + QuoteName(@KeyField) + ' = T.' + QuoteName(@KeyField)
          +
          CASE
            WHEN @DateFirstField IS NULL OR @DateFirstNullAble = 1 THEN '
    OUTER APPLY
    (
      SELECT
        RI.[Age]
      FROM [System].[Periodic:Row@Info](' + Cast(@Table_Id AS NVarChar) + ', I.' + QuoteName(@KeyField) + ', Default) RI
      WHERE I.[Row:Action] <> ''I''
    ) RI'
            ELSE N''
          END
          + N'
    CROSS APPLY (VALUES(CASE WHEN I.[Row:Action] = ''D'' OR I.[Row:Action] = ''U'' AND '
          +
          CASE
            WHEN @DateFirstField IS NOT NULL AND @DateFirstNullAble = 0 THEN N'I.' + QuoteName(N'#:' + @DateFirstField) + ' = 0 THEN T.' + QuoteName(@DateFirstField) + N' ELSE I.' + QuoteName(@DateFirstField)
            WHEN @DateFirstField IS NOT NULL AND @DateFirstNullAble = 1 THEN N'I.' + QuoteName(@DateFirstField) + ' IS NULL THEN RI.[Age] ELSE I.[Periodic:Age]'
            ELSE N'I.[#:AGE] = 0 THEN RI.[Age] ELSE I.[Periodic:Age]'
          END
          + ' END)) IA([Periodic:Age])'
          +
          CASE
            WHEN @ActiveMethod IS NOT NULL THEN N'
    OUTER APPLY
    (
      SELECT
        [Periodic:Active:Need Check]  = Cast(1 AS Bit),
        [Periodic:Active:Age]         =
          CASE'
              +
              CASE -- ???? 'DN'
                WHEN @ActiveMethod = 'DTN' THEN N'
            WHEN I.' + QuoteName(N'#:' + @ActiveField) + N' = 0 THEN I.[Periodic:Age]'
                ELSE N''
              END
              + N'
            WHEN I.[Row:Version] = 0 THEN I.[Row:Data].value(''min(for $c in /PERIODIC['
              +
              CASE @ActiveMethod
                WHEN 'DN'  THEN N'empty(@' + @ActiveField + N')=false()'
                WHEN 'DTN' THEN N'empty(@' + @ActiveField + N')=true()'
                WHEN 'DTF' THEN N'@' + @ActiveField + N'=false()'
                ELSE N'@' + @ActiveField + N'=true()'
              END
              + ']/@DATE[1] return xs:date($c))'', ''Date'')
            WHEN I.[Row:Version] = 2 THEN I.[Row:Data].value(''min(for $c in /FIELD[@NAME="' + @ActiveField + N'"][1]/PERIODIC['
              +
              CASE @ActiveMethod
                WHEN 'DN'  THEN N'empty(@VALUE)=false()'
                WHEN 'DTN' THEN N'empty(@VALUE)=true()'
                WHEN 'DTF' THEN N'@VALUE=false()'
                ELSE N'@VALUE=true()'
              END
              + ']/@DATE return xs:date($c))'', ''Date'')
          END
      WHERE'
              +
              CASE
                WHEN @ActiveMethod IN ('DTN', 'DN') THEN N' I.[Row:Action] = ''I'' AND I.' + QuoteName(@ActiveField) + N' IS NULL OR I.[Row:Action] = ''U'''
                ELSE N' I.[Row:Action] <> ''D'''
              END
              + N' AND I.' + QuoteName(N'#:' + @ActiveField) + N' = 1
    ) AF'
            ELSE N''
          END
          + N'
    WHERE [System].[Raise Error]
          (
            @@PROCID,
            CASE'
          + CASE
              WHEN @KeyFieldIdentity = 1 THEN '
              WHEN I.[Row:Action] = ''I'' AND I.' + QuoteName(@KeyField) + ' IS NOT NULL THEN ''При вставки записи значение поля ' + QuoteName(@KeyField) + ' должно быть NULL''
              WHEN I.[Row:Action] <> ''I'' AND I.' + QuoteName(@KeyField) + ' IS NULL THEN ''При изменении и удалении записи значение поля ' + QuoteName(@KeyField) + ' не может быть NULL'''
              ELSE '
              WHEN I.' + QuoteName(@KeyField) + ' IS NULL THEN ''Значение поля ' + QuoteName(@KeyField) + ' не может быть NULL''
              WHEN I.[Row:Action] = ''I'' AND T.' + QuoteName(@KeyField) + ' IS NOT NULL THEN ''Вставляемая запись с ' + QuoteName(@KeyField) + ' = '' + Cast(I.' + QuoteName(@KeyField) + ' AS NVarChar) + '' в базе данных уже существует'''
            END
          + '
              WHEN I.[Row:Action] <> ''I'' AND T.' + QuoteName(@KeyField) + ' IS NULL THEN ''Запись с ' + QuoteName(@KeyField) + ' = '' + Cast(I.' + QuoteName(@KeyField) + ' AS NVarChar) + '' в базе данных не обнаружена'''
          +
          IsNull
          (
            [Pub].[Concat]
            (
              CASE
                WHEN SF.[IsNullAble] = 0 AND SF.[Name] <> @KeyField AND SF.[PeriodicField_Id] IS NULL AND SF.[TranslateField_Id] IS NULL THEN N'
              WHEN (I.[Row:Action] = ''I'' OR I.[Row:Action] = ''U'' AND I.' + QuoteName(N'#:' + SF.[Name]) + ' = 1) AND I.' + QuoteName(SF.[Name]) + ' IS NULL THEN ''Значение поля ' + QuoteName(SF.[Name]) + ' не может быть NULL'''
              END,
              N''
            ),
            N''
          )
          +
          CASE
            WHEN @DateFirstNullAble = 1 THEN N'
              WHEN I.' + QuoteName(@DateFirstField) + ' <> I.[Periodic:Age] THEN ''Ошибка определения возраста записи: ' + QuoteName(@DateFirstField) + ' = '' + Convert(VarChar, I.' + QuoteName(@DateFirstField) + ', 104) + '', [AGE] = '' + Convert(VarChar, I.[Periodic:Age], 104)'
            ELSE N''
          END

          + N'
              WHEN I.[Row:Action] IN (''I'', ''U'') AND I.'
          + QuoteName(N'#:' + CASE WHEN @DateFirstNullAble = 0 THEN @DateFirstField ELSE 'AGE' END)
          + ' = 1 AND I.' + QuoteName(CASE WHEN @DateFirstNullAble = 0 THEN @DateFirstField ELSE 'Periodic:Age' END)
          + ' > @Today THEN ''Первичная запись в периодике [Age] = '' + Convert(VarChar, I.' + QuoteName(CASE WHEN @DateFirstNullAble = 0 THEN @DateFirstField ELSE 'Periodic:Age' END)
          + ', 104) + '' не может быть в будущем периоде'''

          + '
            END
          ) IS NULL
          AND (I.[Row:Action] IN (''I'', ''D'') OR I.[Row:Fields] <> '''')'
          +
          CASE
            WHEN @ActiveMethod IS NOT NULL THEN N'
          AND (AF.[Periodic:Active:Need Check] IS NULL OR I.[Row:Action] = ''U'' OR AF.[Periodic:Active:Age] IS NOT NULL)'
            -- + CASE @ActiveMethod WHEN 'ATN' THEN 'IS NOT NULL' WHEN 'ATF' THEN '= 1' WHEN 'DTN' THEN 'IS NULL' WHEN 'DTF' THEN '= 0' END
            ELSE N''
          END

          + N'

    IF @@ROWCOUNT = 0
      GOTO OK_EXIT

    INSERT INTO @Periodic([GUId], [Date], [Field_Id], [Value]' + CASE WHEN @HaveUnTranslatableFields = 1 THEN N', [PriorDate], [NextDate]' ELSE N'' END + N')
    SELECT
      [GUId]                = PV.[GUId],
      [Date]                = PV.[Date],
      [Field_Id]            = PV.[Field_Id],
      [Value]               = PV.[Value]'
          +
          CASE
            WHEN @HaveUnTranslatableFields = 1 THEN N',
      [PriorDate]           = LAG(PV.[Date]) OVER (PARTITION BY PV.[GUId], PV.[Field_Id] ORDER BY PV.[Date]),
      [NextDate]            = LEAD(PV.[Date]) OVER (PARTITION BY PV.[GUId], PV.[Field_Id] ORDER BY PV.[Date])'
            ELSE ''
          END

          + N'
    FROM
    (
      SELECT
        [GUId]      = NP.' + QuoteName(IsNull(@GUIdField, 'Periodic:GUId')) + N',
        [Date]      = '

          +
          CASE
            WHEN @ActiveMethod IS NOT NULL AND @PeriodicFieldCount > 1 THEN N'CASE WHEN PV.[Inactive:Index] = 1 THEN NP.[Periodic:Active:Age] ELSE PV.[Date] END'
            ELSE N'PV.[Date]'
          END
          + N',
        [Field_Id]  = PV.[Field_Id],
        [Value]     = PV.[Value]
      FROM @Records NP
      OUTER APPLY'
          + [SQL].[Generate?Field Test]([Pub].[Concat](CASE WHEN SF.[PeriodicField_Id] IS NOT NULL THEN SF.[Name] END, N','), N'NP.[Row:Fields:Periodic]', 3, Default)
          + N' Priv
      CROSS APPLY
      (
        SELECT
          [Date]            = B.[Date],
          [Field_Id]        = F.[Field_Id],
          [Value]           = F.[Value]'

          +
          CASE
            WHEN @HaveUnTranslatableFields = 1 THEN N',
          [Duplicate]       = CASE WHEN ' + IsNull('F.[Field_Id] NOT IN (' + @Translate_Fields_PIDs + N') AND ', '') + '(ROW_NUMBER() OVER (PARTITION BY F.[Field_Id] ORDER BY B.[Date])) > 1 THEN [Pub].[Is Equal Variants](LAG(F.[Value]) OVER (PARTITION BY F.[Field_Id] ORDER BY B.[Date]), F.[Value]) ELSE 0 END'
            ELSE N''
          END
          +
          CASE
            WHEN @ActiveMethod IS NULL OR @PeriodicFieldCount = 1 THEN N''
            ELSE N',
          [Inactive:Index]  = CASE WHEN B.[Date] <= NP.[Periodic:Active:Age] THEN ROW_NUMBER() OVER (PARTITION BY F.[Field_Id], CASE WHEN B.[Date] <= NP.[Periodic:Active:Age] THEN 0 ELSE 1 END ORDER BY B.[Date] DESC) END'
          END
          + N'
        FROM (VALUES(NULL)) Non([None])
        OUTER APPLY [Row:Data].nodes(''PERIODIC'') AS I (Node)
        CROSS APPLY
        (
          SELECT
            [Date]  = IsNull(I.Node.value(''@DATE[1]'', ''Date''), NP.[Periodic:Age])
        ) B
        CROSS APPLY
        ('
          + [Pub].[ConCat]
            (
              N'
          SELECT
            [Field_Id]  = ' + CAST(SF.[PeriodicField_Id] AS NVarChar) + N',
            [Value]     = V.[Value]
          FROM (VALUES(Cast(IsNull(NP.' + QuoteName(SF.[Name])
                + N', CASE WHEN Priv.' + QuoteName(SF.[Name]) + N' = 1 THEN I.Node.value('
                + [Pub].[Quote String]('@' + SF.[Name] + '[1]') + N', '
                + [Pub].[Quote String](SF.[Type_Full])
                + N') END) AS SQL_Variant))) V([Value])'
              --+ CASE
              --    WHEN TF.[Id] IS NOT NULL THEN 'NULL'
              --    ELSE 'Cast(IsNull(NP.' + QuoteName(SF.[Name]) + ', CASE WHEN V.[Updated] = 1 THEN V.[Value] END) AS SQL_Variant)'
              --  END
              + N'
          WHERE (NP.[Row:Action] = ''I'' OR Priv.' + QuoteName(SF.[Name]) + N' = 1)'
              +
              CASE
                WHEN SF.[Name] = @ActiveField THEN N'
              AND (NP.[Periodic:Active:Age] IS NULL OR B.[Date] >= NP.[Periodic:Active:Age])'
                ELSE N''
              END
              +
              CASE
                WHEN (SF.[Name] = @ActiveField AND @ActiveMethod <> 'DN') OR SF.[IsNullAble] = 0 AND SF.[TranslateField_Id] IS NULL THEN N'
              AND
              [System].[Raise Error]
              (
                @@PROCID,
                CASE
                  WHEN NP.[Row:Action] <> ''I'' OR Priv.' + QuoteName(SF.[Name]) + N' = 0 THEN NULL
                  WHEN V.[Value] '
                  +
                  CASE
                    WHEN SF.[Name] = @ActiveField AND @ActiveMethod IN ('ATN', 'DTN') THEN
                      N'= 0 THEN ' + [Pub].[Quote String]('Периодическое значение поля ' + QuoteName(SF.[Name]) + N' не может быть FALSE')
                    ELSE
                      N'IS NULL THEN ' + [Pub].[Quote String]('Периодическое значение поля ' + QuoteName(SF.[Name]) + N' не может быть NULL')
                  END
                  + N'
                END
              ) IS NULL'
                ELSE N''
              END
              , N'
          UNION ALL'
            )
          + N'
        ) F
        WHERE NP.[Row:Version]' + CASE WHEN @Translate = 1 THEN N' IN (0,1)' ELSE N' = 0' END + N'

        UNION ALL

        SELECT
          [Date]            = B.[Date],
          [Field_Id]        = PF.[Id],
          [Value]           = F.[Value]'
          +
          CASE
            WHEN @HaveUnTranslatableFields = 1 THEN ',
          [Duplicate]       = CASE WHEN (ROW_NUMBER() OVER (PARTITION BY PF.[Id] ORDER BY B.[Date])) > 1 THEN [Pub].[Is Equal Variants](LAG(F.[Value]) OVER (PARTITION BY PF.[Id] ORDER BY B.[Date]), F.[Value]) ELSE 0 END'
            ELSE ''
          END
          +
          CASE
            WHEN @ActiveMethod IS NULL OR @PeriodicFieldCount = 1 THEN N''
            ELSE N',
          [Inactive:Index]  = CASE WHEN B.[Date] <= NP.[Periodic:Active:Age] THEN ROW_NUMBER() OVER (PARTITION BY PF.[Id], CASE WHEN B.[Date] <= NP.[Periodic:Active:Age] THEN 0 ELSE 1 END ORDER BY B.[Date] DESC) END'
          END
          + N'
        FROM (VALUES ' + @Values_IdAndName + N') PF([Id], [Name])
        LEFT JOIN NP.[Row:Data].nodes(''FIELD'') AS I (Node) ON PF.[Name] = I.Node.value(''@NAME[1]'', ''SysName'') COLLATE Cyrillic_General_BIN
        OUTER APPLY I.Node.nodes(''PERIODIC'') AS J (SubNode)
        CROSS APPLY (VALUES(IsNull(J.SubNode.value(''@DATE[1]'', ''Date''), NP.[Periodic:Age]))) B([Date])
        CROSS APPLY
        ('
          +
          [Pub].[ConCat]
          (
            CASE
              WHEN SF.[PeriodicField_Id] IS NOT NULL THEN N'
          SELECT
            [Value] = Cast(V.' + QuoteName(SF.[Name]) + ' AS SQL_Variant)
          FROM (VALUES(IsNull(NP.' + QuoteName(SF.[Name]) + ', CASE WHEN Priv.' + QuoteName(SF.[Name]) + N' = 1 THEN J.SubNode.value(''@VALUE[1]'', ' + [Pub].[Quote String](SF.[Type_Full]) + ') END))) V(' + QuoteName(SF.[Name]) + ')
          WHERE PF.[Name] = ' + [Pub].[Quote String](SF.[Name]) + N'
              AND (NP.[Row:Action] = ''I'' OR Priv.' + QuoteName(SF.[Name]) + N' = 1)'
                +
                CASE
                  WHEN SF.[Name] = @ActiveField THEN N'
              AND (NP.[Periodic:Active:Age] IS NULL OR B.[Date] >= NP.[Periodic:Active:Age])'
                  ELSE N''
                END
                +
                CASE
                  WHEN (SF.[Name] = @ActiveField AND @ActiveMethod <> 'DN') OR SF.[IsNullAble] = 0 AND SF.[TranslateField_Id] IS NULL THEN N'
              AND
              [System].[Raise Error]
              (
                @@PROCID,
                CASE
                  WHEN NP.[Row:Action] <> ''I'' OR Priv.' + QuoteName(SF.[Name]) + N' = 0 THEN NULL
                  WHEN V.' + QuoteName(SF.[Name]) + N' '
                    +
                    CASE
                      WHEN SF.[Name] = @ActiveField AND @ActiveMethod IN ('ATN', 'DTN') THEN
                      N'= 0 THEN ' + [Pub].[Quote String]('Периодическое значение поля ' + QuoteName(SF.[Name]) + N' не может быть FALSE')
                      ELSE
                      N'IS NULL THEN ' + [Pub].[Quote String]('Периодическое значение поля ' + QuoteName(SF.[Name]) + N' не может быть NULL')
                    END
                    + N'
                END
              ) IS NULL'
                  ELSE ''
                END
            END
            , N'
          UNION ALL'
          )
          + N'
        ) F
        WHERE NP.[Row:Version] = 2' -- AND (NP.[Row:Action] = ''I'' OR UF.[Value] IS NOT NULL)
          + N'
      ) PV
      WHERE (NP.[Row:Action] = ''I'' OR NP.[Row:Action] = ''U'' AND NP.[Row:Fields:Periodic] <> N'''')'
          +
          CASE
            WHEN @HaveUnTranslatableFields = 1 THEN N'
        AND PV.[Duplicate] = 0'
            ELSE N''
          END
          +
          CASE
            WHEN @ActiveMethod IS NOT NULL AND @PeriodicFieldCount > 1 THEN N'
        AND (PV.[Inactive:Index] IS NULL OR PV.[Inactive:Index] = 1)'
            ELSE N''
          END
          +
          CASE
            WHEN @Future = 0 THEN N'
        AND [System].[Raise Error]
            (
              @@PROCID,
              CASE
                WHEN PV.[Date] > @Today THEN ''Периодическое изменение в этом объекте не может быть сохранено будущей датой.''
              END
            ) IS NULL'
            ELSE ''
          END
          + N'
    ) PV
    OPTION (FORCE ORDER, MAXDOP 1)

    SET @RowCount_P = @@ROWCOUNT'

        +
        CASE
          WHEN @DateFirstField IS NOT NULL THEN N'

    SELECT
      @ErrorNumber = 1
    FROM @Records NP
    CROSS APPLY [Pub].[Array To RowSet Of Values](NP.[Row:Fields:Periodic], '','') F
    INNER JOIN
    (
      VALUES ' + @Values_IdAndName + N'
    ) PF([Id], [Name]) ON F.[Value] = PF.[Name]
    LEFT JOIN
    (
      SELECT
        [GUId]      = P.[GUId],
        [Field_Id]  = P.[Field_Id],
        [Age]       = MIN(P.[Date])
      FROM @Periodic P
      GROUP BY P.[GUId], P.[Field_Id]
    ) P ON NP.' + QuoteName(IsNull(@GUIdField, 'Periodic:GUId')) + ' = P.[GUId] AND PF.[Id] = P.[Field_Id]
    WHERE NP.[Row:Action] IN (''I'', ''U'')
      AND [System].[Raise Error]
          (
            @@PROCID,
            CASE
              WHEN P.[Field_Id] IS NULL THEN
                N''Для записи [Id] = '' + Cast(NP.' + QuoteName(@KeyField) + ' AS NVarChar) + '' отсутствуют данные по периодике''
              WHEN P.[Age] < NP.[Periodic:Age] THEN
                N''Для записи [Id] = '' + Cast(NP.' + QuoteName(@KeyField) + ' AS NVarChar) + '' присутствуют записи в таблице периодики на дату [Date] = '' + Convert(NVarChar, P.[Age], 104) + '', более раннюю чем первичная [Age] = '' + Convert(NVarChar, NP.[Periodic:Age], 104)
              WHEN P.[Age] > NP.[Periodic:Age] THEN
                N''Для записи [Id] = '' + Cast(NP.' + QuoteName(@KeyField) + ' AS NVarChar) + '' отсутствует первичное упоминание в таблице периодики на дату [Age] = '' + Convert(VarChar, NP.[Periodic:Age], 104)
            END
          ) IS NULL'
          ELSE N''
        END

        +
        CASE
          WHEN @ListFieldsExists = 1 THEN
            [Pub].[Concat]
            (
              CASE
                WHEN SF.[PeriodicFieldKind] = 'L' THEN N'

    INSERT INTO @Periodic' + Cast(SF.[PeriodicField_Id] AS NVarChar) + N'([Row:GUId], ' + QuoteName(SF.[ForeignList]) + N', [Periodic:Date])
    SELECT
      P.[GUId], V.[Value], P.[Date]
    FROM @Periodic P
    CROSS APPLY [Pub].[Array To RowSet Of Values](Cast(P.[Value] AS NVarChar(Max)), N'','') V
    WHERE P.[Field_Id] = ' + Cast(SF.[PeriodicField_Id] AS NVarChar)
              END
              , N''
            )
          ELSE N''
        END
        +
        CASE
          WHEN @Translate_Fields_PIDs IS NOT NULL THEN
            IsNull
            (
              N'

    INSERT INTO @Translate([GUId], [Language], [Field_Id], [Value])
    SELECT
      [GUId]      = NP.' + QuoteName(IsNull(@GUIdField, 'Periodic:GUId')) + ',
      [Language]  = TV.[Language],
      [Field_Id]  = TV.[Field_Id],
      [Value]     = TV.[Value]
    FROM @Records NP
    CROSS APPLY' + [SQL].[Generate?Field Test]([Pub].[Concat](CASE WHEN SF.[TranslateField_Id] IS NOT NULL THEN SF.[Name] END, N','), N'NP.[Row:Fields:Translate]', 2, Default)
              + N' Priv
    CROSS APPLY
    (
      SELECT
        [Language]  = NP.[Translate:Language],
        [Field_Id]  = F.[Field_Id],
        [Value]     = F.[Value]
      FROM
      ('
              +
              [Pub].[ConCat]
              (
                CASE
                  WHEN SF.[TranslateField_Id] IS NOT NULL THEN N'
        SELECT
          [Field_Id]  = ' + CAST(IsNull(SF.[PeriodicField_Id], -SF.[TranslateField_Id]) AS NVarChar) + N',
          [Value]     = Cast(NP.' + QuoteName(SF.[Name]) + ' AS NVarChar(4000))
        WHERE Priv.' + QuoteName(SF.[Name]) + ' = 1'
                END,
                N'
        UNION ALL'
              )
              + N'
      ) F
      WHERE NP.[Row:Version] = 0

      UNION ALL

      SELECT
        [Language]  = B.[Language],
        [Field_Id]  = F.[Field_Id],
        [Value]     = F.[Value]
      FROM NP.[Row:Data].nodes(''TRANSLATE'') AS I (Node)
      CROSS APPLY (VALUES(I.Node.value(''@LANGUAGE[1]'', ''Char(2)'') COLLATE Cyrillic_General_BIN)) B([Language])
      CROSS APPLY
      ('
              +
              [Pub].[ConCat]
              (
                CASE
                  WHEN SF.[TranslateField_Id] IS NOT NULL THEN N'
        SELECT
          [Field_Id]  = ' + CAST(IsNull(SF.[PeriodicField_Id], -SF.[TranslateField_Id]) AS NVarChar) + N',
          [Value]     = I.Node.value(' + [Pub].[Quote String]('@' + SF.[Name] + '[1]') + ', ''NVarChar(4000)'')
        WHERE Priv.' + QuoteName(SF.[Name]) + ' = 1'
                END,
                N'
        UNION ALL'
              )
              + N'
      ) F
      WHERE NP.[Row:Version] = 1

      UNION ALL

      SELECT
        [Language]  = B.[Language],
        [Field_Id]  = F.[Field_Id],
        [Value]     = F.[Value]
      FROM NP.[Row:Data].nodes(''FIELD/TRANSLATE'') AS I (Node)
      CROSS APPLY
      (
        VALUES
        (
          I.Node.value(''../@NAME[1]'', ''SysName'') COLLATE Cyrillic_General_BIN,
          I.Node.value(''@LANGUAGE[1]'', ''Char(2)'') COLLATE Cyrillic_General_BIN
        )
      ) B([Name], [Language])
      CROSS APPLY
      ('
              +
              [Pub].[ConCat]
              (
                CASE
                  WHEN SF.[TranslateField_Id] IS NOT NULL THEN N'
        SELECT
          [Field_Id]  = ' + CAST(IsNull(SF.[PeriodicField_Id], -SF.[TranslateField_Id]) AS NVarChar) + N',
          [Value]     = I.Node.value(''@VALUE[1]'', ''NVarChar(4000)'')
        WHERE Priv.' + QuoteName(SF.[Name]) + N' = 1 AND B.[Name] = ' + [Pub].[Quote String](SF.[Name])
                END,
                N'
        UNION ALL'
              )
              + N'
      ) F
      WHERE NP.[Row:Version] = 2
    ) TV
    LEFT JOIN [System].[Languages] L ON TV.[Language] = L.[Code]
    WHERE NP.[Row:Action] IN (''I'', ''U'')
          AND NP.[Row:Fields:Translate] <> ''''
          AND [System].[Raise Error]
              (
                @@PROCID,
                CASE
                  WHEN L.[Code] IS NULL THEN ''Язык перевода «'' + IsNull(Cast(TV.[Language] AS NVarChar(4)), ''Null'') + ''» не распознан системой''
                END
              ) IS NULL
'
              -- IsNull ","
              , N''
            )
          ELSE N''
        END

        + N'

    IF @RowCount_P > 0 BEGIN'

        +
        CASE
          WHEN @Translate_Fields_PIDs IS NOT NULL THEN N'
      INSERT INTO @Periodic_T([GUId], [Date], [Field_Id], [Translate:Language], [Value])
      SELECT
        [GUId]                = NP.' + QuoteName(IsNull(@GUIdField, 'Periodic:GUId')) + ',
        [Date]                = '
            +
            CASE
              WHEN @ActiveMethod IS NOT NULL AND @PeriodicFieldCount > 1 THEN N'CASE WHEN PV.[Inactive:Index] = 1 THEN NP.[Periodic:Active:Age] ELSE PV.[Date] END'
              ELSE N'PV.[Date]'
            END
            + N',
        [Field_Id]            = PV.[Field_Id],
        [Translate:Language]  = PV.[Translate:Language],
        [Value]               = PV.[Value]
      FROM @Records NP
      CROSS APPLY' + [SQL].[Generate?Field Test]([Pub].[Concat](CASE WHEN SF.[PeriodicField_Id] IS NOT NULL AND SF.[TranslateField_Id] IS NOT NULL THEN SF.[Name] END, N','), N'NP.[Row:Fields:Periodic]', 3, Default)
        + N' Priv
      CROSS APPLY
      (
        SELECT
          [Date]                = B.[Date],
          [Field_Id]            = F.[Field_Id],
          [Translate:Language]  = NP.[Translate:Language],
          [Value]               = F.[Value]'
            +
            CASE
              WHEN @ActiveMethod IS NULL OR @PeriodicFieldCount = 1 THEN N''
              ELSE N',
          [Inactive:Index]      = CASE WHEN B.[Date] <= NP.[Periodic:Active:Age] THEN DENSE_RANK() OVER (PARTITION BY F.[Field_Id], CASE WHEN B.[Date] <= NP.[Periodic:Active:Age] THEN 0 ELSE 1 END ORDER BY B.[Date] DESC) END'
            END
            + N'
        FROM (SELECT [None] = NULL) N
        OUTER APPLY [Row:Data].nodes(''PERIODIC'') AS I(Node)
        CROSS APPLY (VALUES(IsNull(I.Node.value(''@DATE[1]'', ''Date''), NP.[Periodic:Age]))) B([Date])
        CROSS APPLY
        ('
            +
            [Pub].[ConCat]
            (
              CASE
                WHEN SF.[PeriodicField_Id] IS NOT NULL AND SF.[TranslateField_Id] IS NOT NULL THEN N'
          SELECT
            [Field_Id]  = ' + CAST(SF.[PeriodicField_Id] AS NVarChar) + N',
            [Value]     = IsNull(NP.' + QuoteName(SF.[Name]) + ', I.Node.value(' + [Pub].[Quote String]('@' + SF.[Name] + '[1]') + ', ''NVarChar(4000)''))
          WHERE Priv.' + QuoteName(SF.[Name]) + N' = 1'
                  +
                  CASE
                    WHEN SF.[Name] = @ActiveField THEN N'
              AND (NP.[Periodic:Active:Age] IS NULL OR B.[Date] >= NP.[Periodic:Active:Age])'
                    ELSE N''
                  END
              END
              , N'
          UNION ALL'
            )
            + N'
        ) F
        WHERE NP.[Row:Version] = 0

        UNION ALL

        SELECT
          [Date]                = B.[Date],
          [Field_Id]            = F.[Field_Id],
          [Translate:Language]  = L.[Translate:Language],
          [Value]               = F.[Value]'
            +
            CASE
              WHEN @ActiveMethod IS NULL OR @PeriodicFieldCount = 1 THEN N''
              ELSE N',
          [Inactive:Index]      = CASE WHEN B.[Date] <= NP.[Periodic:Active:Age] THEN DENSE_RANK() OVER (PARTITION BY F.[Field_Id], CASE WHEN B.[Date] <= NP.[Periodic:Active:Age] THEN 0 ELSE 1 END ORDER BY B.[Date] DESC) END'
            END
            + N'
        FROM [Row:Data].nodes(''PERIODIC'') AS I(Node)
        CROSS APPLY (VALUES(IsNull(I.Node.value(''@DATE[1]'', ''Date''), NP.[Periodic:Age]))) B([Date])
        CROSS APPLY I.Node.nodes(''TRANSLATE'') AS J(SubNode)
        CROSS APPLY (VALUES(J.SubNode.value(''@LANGUAGE[1]'', ''Char(2)'') COLLATE Cyrillic_General_BIN)) L([Translate:Language])
        CROSS APPLY
        ('
            +
            [Pub].[ConCat]
            (
              CASE
                WHEN SF.[PeriodicField_Id] IS NOT NULL AND SF.[TranslateField_Id] IS NOT NULL THEN N'
          SELECT
            [Field_Id]  = ' + CAST(SF.[PeriodicField_Id] AS NVarChar) + N',
            [Value]     = J.SubNode.value(' + [Pub].[Quote String]('@' + SF.[Name] + '[1]') + ', ''NVarChar(4000)'')
          WHERE Priv.' + QuoteName(SF.[Name]) + ' = 1'
                  +
                  CASE
                    WHEN SF.[Name] = @ActiveField THEN N'
              AND (NP.[Periodic:Active:Age] IS NULL OR B.[Date] >= NP.[Periodic:Active:Age])'
                    ELSE N''
                  END
              END
              , N'
          UNION ALL'
            )
            + N'
        ) F
        WHERE NP.[Row:Version] = 1

        UNION ALL

        SELECT
          [Date]                = B.[Date],
          [Field_Id]            = V.[Field_Id],
          [Translate:Language]  = B.[Language],
          [Value]               = B.[Value]'
            +
            CASE
              WHEN @ActiveMethod IS NULL OR @PeriodicFieldCount = 1 THEN N''
              ELSE N',
          [Inactive:Index]      = CASE
                                    WHEN B.[Date] <= NP.[Periodic:Active:Age] THEN
                                      DENSE_RANK() OVER
                                        (
                                          PARTITION BY V.[Field_Id], CASE WHEN B.[Date] <= NP.[Periodic:Active:Age] THEN 0 ELSE 1 END
                                          ORDER BY B.[Date] DESC
                                        ) END'
            END
            + N'
        FROM NP.[Row:Data].nodes(''/FIELD/PERIODIC/TRANSLATE'') AS I(Node)
        CROSS APPLY
        (
          VALUES
          (
            I.Node.value(''../../@NAME[1]'', ''SysName'') COLLATE Cyrillic_General_BIN,
            IsNull(I.Node.value(''../@DATE[1]'', ''Date''), NP.[Periodic:Age]),
            I.Node.value(''@LANGUAGE[1]'', ''Char(2)'') COLLATE Cyrillic_General_BIN,
            I.Node.value(''@VALUE[1]'', ''NVarChar(4000)'')
          )
        ) B([Name], [Date], [Language], [Value])
        INNER JOIN
        (
          VALUES '
          +
          [Pub].[ConCat]
          (
            CASE
              WHEN SF.[PeriodicField_Id] IS NOT NULL AND SF.[TranslateField_Id] IS NOT NULL THEN
                N'(' + [Pub].[Quote String](SF.[Name]) + N', '+ CAST(SF.[PeriodicField_Id] AS NVarChar) + N', Priv.' + QuoteName(SF.[Name]) + N')'
            END,
            N', '
          )
          + N'
        ) V([Name], [Field_Id], [Privileged]) ON B.[Name] = V.[Name] AND V.[Privileged] = 1
        WHERE NP.[Row:Version] = 2'
            +
            CASE
              WHEN @ActiveField IS NOT NULL THEN N'
          AND (B.[Name] <> ' + [Pub].[Quote String](@ActiveField) + N' OR NP.[Periodic:Active:Age] IS NULL OR B.[Date] >= NP.[Periodic:Active:Age])'
              ELSE N''
            END
            + N'
      ) PV
      LEFT JOIN [System].[Languages] L ON PV.[Translate:Language] = L.[Code]
      WHERE NP.[Row:Action] IN (''I'', ''U'')'
            +
            CASE
              WHEN @ActiveMethod IS NOT NULL AND @PeriodicFieldCount > 1 THEN N'
        AND (PV.[Inactive:Index] IS NULL OR PV.[Inactive:Index] = 1)'
              ELSE N''
            END
            + N'
        AND [System].[Raise Error]
            (
              @@PROCID,
              CASE
                WHEN L.[Code] IS NULL THEN ''Язык перевода «'' + IsNull(Cast(PV.[Translate:Language] AS NVarChar(4)), ''Null'') + ''» не распознан системой''
              END
            ) IS NULL

      INSERT INTO @Periodic_T([GUId], [Date], [Field_Id], [Translate:Language], [Value])
      SELECT
        [GUId]                = PTF.[GUId],
        [Date]                = PV.[Date],
        [Field_Id]            = PTF.[Field_Id],
        [Translate:Language]  = PTF.[Translate:Language],
        [Value]               = NULL
      FROM
      (
        -- Все периодические переводимые поля присутствующие в таблице периодического перевода на всех указанных языках
        SELECT DISTINCT
          [GUId],
          [Field_Id],
          [Translate:Language]
        FROM @Periodic_T
      ) PTF
      -- Все периодические переводимые поля присутствующие в таблице периодического перевода на всех указанных языках на все даты периодики
      INNER JOIN @Periodic PV ON PTF.[GUId] = PV.[GUId] AND PTF.[Field_Id] = PV.[Field_Id]
      LEFT JOIN @Periodic_T PTV ON PTF.[GUId] = PTV.[GUId] AND PTF.[Field_Id] = PTV.[Field_Id] AND PV.[Date] = PTV.[Date] AND PTF.[Translate:Language] = PTV.[Translate:Language]
      WHERE PTV.[Field_Id] IS NULL
        UNION ALL
      SELECT
        [GUId]                = PT.[GUId],
        [Date]                = PV.[Date],
        [Field_Id]            = PT.[Field_Id],
        [Translate:Language]  = L.[Code],
        [Value]               = NULL
      FROM
      (
        -- Все периодические переводимые поля
        SELECT DISTINCT
          [GUId],
          [Field_Id]
        FROM @Periodic
        WHERE [Field_Id] IN (' + @Translate_Fields_PIDs + N')
      ) PT
      -- Все периодические переводимые поля которых нет в таблице периодического перевода
      LEFT JOIN
      (
        SELECT DISTINCT
          [GUId],
          [Field_Id]
        FROM @Periodic_T
      ) PTF ON PT.[GUId] = PTF.[GUId] AND PT.[Field_Id] = PTF.[Field_Id]
      INNER JOIN @Periodic PV ON PT.[GUId] = PV.[GUId] AND PT.[Field_Id] = PV.[Field_Id]
      -- На всех системных языках (для удаления мусора)
      CROSS JOIN [System].[Languages] L
      WHERE PTF.[Field_Id] IS NULL

      MERGE @Periodic P
      USING
      (
        SELECT
          [GUId],
          [Field_Id],
          [Date],
          [Value],
          [Priority],
          [Duplicate] = CASE WHEN SUM(CASE WHEN [Index] = 1 OR [Pub].[Is Equal Variants]([Value], [PriorValue]) = 0 THEN 1 ELSE 0 END) OVER (PARTITION BY [GUId], [Field_Id], [Date]) = 0 THEN 1 END
        FROM
        (
          SELECT
            [GUId]        = PTV.[GUId],
            [Field_Id]    = PTV.[Field_Id],
            [Date]        = PTV.[Date],
            [Value]       = PTV.[Value],
            [PriorValue]  = LAG(PTV.[Value], 1) OVER (PARTITION BY PTV.[GUId], PTV.[Field_Id], PTV.[Translate:Language] ORDER BY PTV.[Date]),
            [Index]       = ROW_NUMBER() OVER (PARTITION BY PTV.[GUId], PTV.[Field_Id], PTV.[Translate:Language] ORDER BY PTV.[Date]),
            [Priority]    = ROW_NUMBER() OVER (PARTITION BY PTV.[GUId], PTV.[Field_Id], PTV.[Date] ORDER BY CASE WHEN PTV.[Value] IS NOT NULL THEN 1 ELSE 0 END, L.[Priority])
          FROM @Periodic_T PTV
          INNER JOIN [System].[Languages] L ON PTV.[Translate:Language] = L.[Code]
        ) PT
      ) I ON I.[Priority] = 1 AND I.[GUId] = P.[GUId] AND I.[Field_Id] = P.[Field_Id] AND I.[Date] = P.[Date]
      WHEN MATCHED AND I.[Duplicate] = 1 THEN DELETE
      WHEN MATCHED THEN UPDATE SET
        [Value] = I.[Value];

      UPDATE P SET
        [PriorDate] = PP.[Date],
        [NextDate]  = PN.[Date]
      FROM @Periodic P
      OUTER APPLY (SELECT TOP 1 PP.[Date] FROM @Periodic PP WHERE P.[GUId] = PP.[GUId] AND P.[Field_Id] = PP.[Field_Id] AND P.[Date] > PP.[Date] ORDER BY PP.[Date] DESC) PP
      OUTER APPLY (SELECT TOP 1 PN.[Date] FROM @Periodic PN WHERE P.[GUId] = PN.[GUId] AND P.[Field_Id] = PN.[Field_Id] AND P.[Date] < PN.[Date] ORDER BY PN.[Date]) PN
      WHERE P.[Field_Id] IN (' + @Translate_Fields_PIDs + N')
'
          ELSE N''
        END
        -- EOC / CASE WHEN @Translate_Fields_PIDs IS NOT NULL

        + N'
      UPDATE R SET'
        +
        CASE
          WHEN @ActiveMethod IS NOT NULL THEN N'
        [Periodic:Age]            = IsNull(R.[Periodic:Active:Age], R.[Periodic:Age]),
        [Row:Fields]              = CASE WHEN R.[Periodic:Active:Age] > R.[Periodic:Age] THEN [Pub].[Arrays Merge](R.[Row:Fields], ''AGE'', '','') ELSE R.[Row:Fields] END,'
          ELSE N''
        END
        +
        [Pub].[Concat]
        (
          N'
        ' + [SQL].[Shift](QuoteName(SF.[Name]), 26) + N'= Cast(P' + Cast(SF.[PeriodicField_Id] AS NVarChar) + N'.[Value] AS ' + SF.[Type_Full] + N')'
          , N','
        )
        + N'
      FROM @Records R'
        +
        [Pub].[Concat]
        (
          N'
      OUTER APPLY (SELECT TOP 1 P.[Value] FROM @Periodic P WHERE R.' + QuoteName(IsNull(@GUIdField, 'Periodic:GUId')) + N' = P.[GUId] AND P.[Field_Id] = ' + Cast(SF.[PeriodicField_Id] AS NVarChar) + N' AND P.[Date] <= @Today ORDER BY P.[Date] DESC) P' + Cast(SF.[PeriodicField_Id] AS NVarChar)
          , N''
        )
        + N'
      WHERE R.[Row:Action] IN (''I'', ''U'')

      INSERT INTO @PeriodicFields([Field_Id], [GUId])
      SELECT
        PF.[Field_Id],
        PF.[GUId]
      FROM (SELECT [GUId] = ' + QuoteName(IsNull(@GUIdField, 'Periodic:GUId')) + N', [Fields] = [Row:Fields], [Age] = [Periodic:Age] FROM @Records WHERE [Row:Action] IN (''I'', ''U'')) R
      INNER JOIN (SELECT [Field_Id], [GUId], [Age] = Min([Date]) FROM @Periodic GROUP BY [Field_Id], [GUId]) PF ON R.[GUId] = PF.[GUId]
      INNER JOIN (VALUES ' + @Values_IdAndName + N') F([Id], [Name]) ON PF.[Field_Id] = F.[Id]
      WHERE [System].[Raise Error]
            (
              @@PROCID,
              CASE
                WHEN R.[Age] <> PF.[Age] THEN ''Abstract error: Возраст записи «'' + Convert(VarChar(10), R.[Age], 120) + ''» не совпадает с датой «'' + Convert(VarChar(10), PF.[Age], 120) + ''» первой периодики поля «'' + F.[Name] + ''»''
              END
            ) IS NULL'

        + N'
    END'

        +
        CASE
          WHEN @Translate = 1 THEN N'

    SET @Data_T_ID =
    (
      SELECT
        [ACTION]                  = R.[Row:Action]'
            +
            CASE
              WHEN @KeyFieldIdentity = 1 THEN N',
        [INDEX]                   = R.[Row:Index]'
              ELSE N''
            END
            + N',
        [FIELDS]                  = R.[Row:Fields]'
            +
            CASE
              WHEN @Translate_Fields_PIDs IS NULL THEN N',
        [LANGUAGE]                = R.[Translate:Language]'
              ELSE N''
            END
            +
            [Pub].[Concat]
            (
              CASE
                WHEN SF.[PeriodicFieldKind] IS NULL THEN
                  N',
        ' + [SQL].[Shift](QuoteName(SF.[Name]), 26) + N'= R.' + QuoteName(SF.[Name])
              END
              , N''
            )
            +
            CASE
              WHEN @Translate_Fields_PIDs IS NOT NULL THEN N',
        (
          SELECT
            [NAME]  = CASE PTF.[Field_Id]'
                +
                [Pub].[Concat]
                (
                  CASE
                    WHEN SF.[TranslateField_Id] IS NOT NULL AND SF.[PeriodicField_Id] IS NOT NULL THEN
                      N'
                        WHEN ' + Cast(SF.[PeriodicField_Id] AS NVarChar) + N' THEN ' + [Pub].[Quote String](SF.[Name])
                  END
                  , N''
                )
                + N'
                      END,
            (
              SELECT
                [LANGUAGE]  = PTV.[Translate:Language],
                [VALUE]     = PTV.[Value]
              FROM @Periodic_T PTV
              WHERE R.' + QuoteName(IsNull(@GUIdField, 'Periodic:GUId')) + N' = PTV.[GUId] AND PTF.[Field_Id] = PTV.[Field_Id] AND PTF.[Date] = PTV.[Date] AND PTV.[Value] IS NOT NULL
              FOR XML RAW(''TRANSLATE''), TYPE
            )
          FROM
          (
            SELECT
              [Field_Id]  = PTF.[Field_Id],
              [Date]      = MAX(PTF.[Date])
            FROM @Periodic_T PTF
            WHERE R.[Row:Action] = ''I'' AND R.' + QuoteName(IsNull(@GUIdField, 'Periodic:GUId')) + N' = PTF.[GUId] AND PTF.[Field_Id] IN (' + @Translate_Fields_PIDs + ') AND PTF.[Date] <= @Today
            GROUP BY PTF.[Field_Id]
          ) PTF
          FOR XML RAW(''FIELD''), TYPE
        )'
                +
                IsNull
                (
                  N',
        (
          SELECT
            [NAME]      = CASE TF.[Field_Id]'
                  +
                  [Pub].[Concat]
                  (
                    CASE
                      WHEN SF.[TranslateField_Id] IS NOT NULL AND SF.[PeriodicField_Id] IS NULL THEN N'
                            WHEN -' + Cast(SF.[TranslateField_Id] AS NVarChar) + N' THEN ' + [Pub].[Quote String](SF.[Name])
                    END
                    , N''
                  )
                  + N'
                          END,
            (
              SELECT
                [LANGUAGE]  = TV.[Language],
                [VALUE]     = TV.[Value]
              FROM @Translate TV
              WHERE R.[GUId] = TV.[GUId] AND TF.[Field_Id] = TV.[Field_Id] AND TV.[Value] IS NOT NULL
              FOR XML RAW(''TRANSLATE''), TYPE
            )
          FROM
          (
            SELECT DISTINCT [Field_Id] FROM @Translate T WHERE R.[Row:Action] = ''I'' AND T.[Field_Id] < 0 AND T.[Value] IS NOT NULL
          ) TF
          FOR XML RAW(''FIELD''), TYPE
        )'
                  , N''
                )
              ELSE N',
        CASE R.[Row:Version]
          WHEN 2 THEN (SELECT [NAME]  = I.Node.value(''@NAME[1]'', ''sysname''), I.Node.query(''TRANSLATE'') FROM R.[Row:Data].nodes(''FIELD'') I(Node) FOR XML RAW(''FIELD''), TYPE)
          WHEN 1 THEN R.[Row:Data].query(''TRANSLATE'')
        END'
            END
            -- EOC / WHEN @Translate_Fields_PIDs IS NOT NULL

            + N'
      FROM @Records R
      WHERE R.[Row:Action] IN (''I'', ''D'')
      FOR XML RAW(''RECORD''), TYPE
    )'

            +
            CASE
              WHEN @Translate_Fields_PIDs IS NULL THEN N'

    SET @Data_T_U =
    (
      SELECT
        [ACTION]                  = R.[Row:Action],
        [FIELDS]                  = R.[Row:Fields],
        [LANGUAGE]                = R.[Translate:Language]'
                    +
                    [Pub].[Concat]
                    (
                      CASE
                        WHEN SF.[PeriodicFieldKind] IS NULL THEN N',
        '
                        + [SQL].[Shift](QuoteName(SF.[Name]), 26) + N'= '
                        + N'R.' + QuoteName(SF.[Name])
                      END,
                      N''
                    )
                    + N',
        CASE R.[Row:Version]
          WHEN 2 THEN (SELECT [NAME]  = I.Node.value(''@NAME[1]'', ''sysname''), I.Node.query(''TRANSLATE'') FROM R.[Row:Data].nodes(''FIELD'') I(Node) FOR XML RAW(''FIELD''), TYPE)
          WHEN 1 THEN R.[Row:Data].query(''TRANSLATE'')
        END
      FROM @Records R
      WHERE R.[Row:Action] IN (''U'')
      FOR XML RAW(''RECORD''), TYPE
    )'
              ELSE N''
            END
          ELSE N''
        END
        -- EOC / WHEN @Translate = 1

        + N'

    SET @TranCount = @@TranCount
    SET @Retry = CASE WHEN @TranCount = 0 THEN 5 ELSE 1 END

    WHILE (@Retry > 0)
    BEGIN TRY
      IF @TranCount > 0
        SAVE TRAN PS_TRAN
      ELSE
        BEGIN TRAN'
        +
        CASE
          WHEN @Logging = 1 THEN N'

      EXEC [System].[Log@Begin]'
          ELSE N''
        END
        +
        CASE
          WHEN @Translate = 0 THEN N'

      IF EXISTS(SELECT TOP 1 1 FROM @Records WHERE [Row:Action] = ''D'') BEGIN
        DELETE T
        FROM @Records NP
        INNER LOOP JOIN ' + @Object_Name + ' T ON NP.' + QuoteName(@KeyField) + ' = T.' + QuoteName(@KeyField) + '
        WHERE NP.[Row:Action] = ''D''
        OPTION (FORCE ORDER, MAXDOP 1)

        DELETE @Records WHERE [Row:Action] = ''D''
      END'
          ELSE N''
        END

        + CASE
            WHEN @Translate = 0 THEN '

      IF EXISTS(SELECT TOP 1 1 FROM @Records WHERE [Row:Action] = ''I'') BEGIN
        MERGE ' + @Object_Name + ' T
        USING
        (
          SELECT'
              +
              CASE
                WHEN @KeyFieldIdentity = 1 THEN N'
            NP.[Row:Index],'
                ELSE N''
              END
              + N'
            NP.[Row:Fields],'
              +
              CASE
                WHEN @GUIdField IS NULL THEN N'
            NP.[Periodic:GUId],'
                ELSE N''
              END
              +
              [Pub].[ConCat]
              (
                CASE
                  WHEN SF.[IsIdentityOrComputed] = 0 THEN
                    N'
            '
                    + [SQL].[Shift](QuoteName(SF.[Name]), 26)
                    + N'= '
                    +
                    CASE
                      WHEN SF.[PeriodicField_Id] IS NULL THEN 'NP.' + QuoteName(SF.[Name])
                      ELSE 'Cast(P'
                        + Cast(SF.[PeriodicField_Id] AS NVarChar(10))
                        + '.[Value] AS '
                        + SF.[Type_Full]
                        + ')'
                    END
                END,
                ','
              )
              + N'
          FROM @Records NP'
              + [Pub].[ConCat]
                (
                  N'
          OUTER APPLY (SELECT TOP 1 P.[Value] FROM @Periodic P WHERE NP.' + QuoteName(IsNull(@GUIdField, 'Periodic:GUId')) + ' = P.[GUId] AND P.[Field_Id] = ' + Cast(SF.[PeriodicField_Id] AS NVarChar(10)) + ' AND P.[Date] <= @Today ORDER BY P.[Date] DESC) P' + Cast(SF.[PeriodicField_Id] AS NVarChar(10)),
                  ''
                )
              + '
          WHERE NP.[Row:Action] = ''I''
        ) I ON 1 = 0
        WHEN NOT MATCHED BY TARGET THEN INSERT ('
              +
              [Pub].[Concat]
              (
                CASE
                  WHEN SF.[IsIdentityOrComputed] = 0 THEN QuoteName(SF.[Name])
                END,
                ', '
              )

              + N')
        VALUES ('
              + [Pub].[Concat]
                (
                  CASE
                    WHEN SF.[IsIdentityOrComputed] = 0 THEN 'I.' + QuoteName(SF.[Name])
                  END,
                  ', '
                )
              + ')'

              +
              CASE
                WHEN @KeyFieldIdentity = 1 THEN '
        OUTPUT I.[Row:Index], Inserted.' + QuoteName(@KeyField) + ', I.' + QuoteName(IsNull(@GUIdField, 'Periodic:GUId')) + ' INTO @Inserted([Index], [Identity], [GUId]);

        IF @@ROWCOUNT > 0
          UPDATE NP SET
            ' + QuoteName(@KeyField) + ' = I.[Identity]
          FROM @Inserted I
          INNER JOIN @Records NP ON I.[GUId] = NP.' + QuoteName(IsNull(@GUIdField, 'Periodic:GUId')) + N' AND NP.[Row:Action] = ''I''

        INSERT INTO [System].[Scope Identities]([Identity], [Index]' + CASE WHEN @GUIdField IS NOT NULL THEN ', [GUId]' ELSE '' END + ')
        SELECT
          [Identity]  = [Identity],
          [Index]     = [Index]'
                    +
                    CASE
                      WHEN @GUIdField IS NOT NULL THEN N',
          [GUId]      = [GUId]'
                      ELSE ''
                    END

                    + N'
        FROM @Inserted'
                ELSE ';'
              END

            ELSE N'

      IF EXISTS(SELECT TOP 1 1 FROM @Records WHERE [Row:Action] IN (''I'', ''D'')) BEGIN
        EXEC [System].' + QuoteName(@Name + '(Translate Set)') + N' @Data = @Data_T_ID'
              +
              CASE
                WHEN @KeyFieldIdentity = 1 THEN N'

        IF [System].[Row Count]() > 0
          UPDATE NP SET
            ' + QuoteName(@KeyField) + N' = I.[Identity]
          FROM [System].[Scope Identities] I
          INNER JOIN @Records NP ON I.'
                  +
                  CASE
                    WHEN @GUIdField IS NOT NULL THEN '[GUId] = NP.' + QuoteName(@GUIdField)
                    ELSE '[Index] = NP.[Row:Index]'
                  END

                  + N' AND NP.[Row:Action] = ''I''

        INSERT INTO [System].[Scope Identities]([Identity], [Index]' + CASE WHEN @GUIdField IS NOT NULL THEN ', [GUId]' ELSE '' END + ')
        SELECT
          [Identity]  = [Identity],
          [Index]     = [Index]'
                  +
                  CASE
                    WHEN @GUIdField IS NOT NULL THEN N',
          [GUId]      = [GUId]'
                    ELSE N''
                  END
                  + N'
        FROM [System].[Scope Identities]'
                ELSE N''
              END

              +
              CASE
                WHEN @Translate_Fields_PIDs IS NOT NULL THEN N'

        DELETE V
        FROM @Records NP
        CROSS JOIN (VALUES ' + @Values_Id + N') F([Id])
        INNER LOOP JOIN [System].[Periodic:Values:Translate] V ON F.[Id] = V.[Field_Id] AND NP.' + QuoteName(@KeyField) + N' = V.[Key]
        LEFT JOIN @Periodic_T T ON V.[Field_Id] = T.[Field_Id] AND NP.' + QuoteName(IsNull(@GUIdField, 'Periodic:GUId')) + N' = T.[GUId] AND V.[Date] = T.[Date] AND V.[Language] = T.[Translate:Language]
        WHERE NP.[Row:Action] = ''I'' AND T.[Field_Id] IS NULL
        OPTION (FORCE ORDER, MAXDOP 1)'
                ELSE N''
              END
          END

        + N'
      END ELSE
        INSERT INTO [System].[Scope Identities]([Identity], [Index]) SELECT TOP 0 NULL, NULL

      MERGE [System].[Periodic:Values] V
      USING
      (
        SELECT
          [Field_Id]        = V.[Field_Id],
          [Key]             = V.[Key],
          [Age]             = NP.[Periodic:Age],
          [Date]            = V.[Date],
          [NextDate]        = V.[NextDate]'
        +
        CASE
          WHEN @ActiveMethod IS NOT NULL AND @PeriodicFieldCount > 1 THEN N',
          [Inactive:Index]  = CASE WHEN V.[Date] <= NP.[Periodic:Active:Age] THEN ROW_NUMBER() OVER (PARTITION BY V.[Key], V.[Field_Id], CASE WHEN V.[Date] <= NP.[Periodic:Active:Age] THEN 0 ELSE 1 END ORDER BY V.[Date] DESC) END'
          ELSE N''
        END

        + N'
        FROM @Records NP
        CROSS APPLY (SELECT * FROM [System].[Periodic:Row@Info](' + Cast(@Table_Id AS NVarChar) + ', NP.' + QuoteName(@KeyField) + ', Default) RI WHERE NP.[Periodic:Age] <> RI.[Age]) RI
        CROSS JOIN (VALUES ' + @Values_Id + N') F([Id])
        LEFT JOIN @PeriodicFields PFU ON NP.' + QuoteName(IsNull(@GUIdField, 'Periodic:GUId')) + ' = PFU.[GUId] AND F.[Id] = PFU.[Field_Id]
        INNER LOOP JOIN [System].[Periodic:Values] V ON F.[Id] = V.[Field_Id] AND NP.' + QuoteName(@KeyField) + ' = V.[Key] AND RI.[Age] = V.[Date]
        WHERE PFU.[Field_Id] IS NULL
              AND
              [System].[Raise Error]
              (
                @@PROCID,
                CASE
                  WHEN PFU.[Field_Id] IS NULL AND V.[NextDate] IS NOT NULL AND NP.[Periodic:Age] >= V.[NextDate] THEN ''Первичная запись в периодике должна быть меньше даты первого изменения.''
                END
              ) IS NULL
      ) P ON P.[Field_Id] = V.[Field_Id] AND P.[Key] = V.[Key]
                AND (P.[Date] = V.[Date] OR P.[NextDate] IS NOT NULL AND P.[NextDate] = V.[Date])'
        +
        CASE
          WHEN @ActiveMethod IS NOT NULL AND @PeriodicFieldCount > 1 THEN N'
      WHEN MATCHED AND P.[Inactive:Index] > 1 THEN DELETE'
          ELSE N''
        END

        + N'
      WHEN MATCHED THEN UPDATE SET
        [Date]      = CASE WHEN V.[PriorDate] IS NULL     THEN P.[Age] ELSE V.[Date] END,
        [PriorDate] = CASE WHEN V.[PriorDate] IS NOT NULL THEN P.[Age] END
      OPTION (FORCE ORDER, MAXDOP 1)
      ;

      IF @RowCount_P > 0 BEGIN
        UPDATE V SET
          [PriorDate] = NULL,
          [NextDate]  = NULL
        FROM @Records NP
        INNER JOIN @PeriodicFields PF ON NP.' + QuoteName(IsNull(@GUIdField, 'Periodic:GUId')) + ' = PF.[GUId]
        INNER JOIN [System].[Periodic:Values] V ON PF.[Field_Id] = V.[Field_Id] AND NP.' + QuoteName(@KeyField) + ' = V.[Key]

        DELETE V
        FROM @Records NP
        INNER JOIN @PeriodicFields PF ON NP.' + QuoteName(IsNull(@GUIdField, 'Periodic:GUId')) + ' = PF.[GUId]
        INNER JOIN [System].[Periodic:Values] V ON PF.[Field_Id] = V.[Field_Id] AND NP.' + QuoteName(@KeyField) + ' = V.[Key]
        LEFT JOIN @Periodic P ON PF.[Field_Id] = P.[Field_Id] AND PF.[GUId] = P.[GUId] AND V.[Date] = P.[Date]
        WHERE P.[GUId] IS NULL

        MERGE [System].[Periodic:Values] V
        USING
        (
          SELECT
            P.[Field_Id], P.[Date], P.[Value], P.[PriorDate], P.[NextDate],
            [Key]                       = NP.' + QuoteName(@KeyField) + ',
            [InsertedFirstSingleValue]  = Cast(CASE WHEN NP.[Row:Action] = ''I'' AND P.[PriorDate] IS NULL AND P.[NextDate] IS NULL THEN 1 ELSE 0 END AS Bit)
          FROM @Periodic P
          INNER JOIN @Records NP ON P.[GUId] = NP.' + QuoteName(IsNull(@GUIdField, N'Periodic:GUId'))
      +
      CASE
        WHEN @ListFieldsExists = 1 THEN N'
          WHERE P.[Field_Id] NOT IN ('
          +
          [Pub].[Concat]
          (
            CASE
              WHEN SF.[PeriodicFieldKind] = 'L' THEN Cast(SF.[PeriodicField_Id] AS NVarChar)
            END,
            N', '
          )
          + N')'
        ELSE N''
      END

      + N'
        ) P
          ON V.[Field_Id] = P.[Field_Id] AND V.[Key] = P.[Key] AND V.[Date] = P.[Date]
        WHEN MATCHED THEN UPDATE SET
          [Value] = CASE WHEN P.[InsertedFirstSingleValue] = 0' + CASE WHEN @Translate_Fields_PIDs IS NOT NULL THEN N' AND P.[Field_Id] NOT IN (' + @Translate_Fields_PIDs + ')' ELSE N'' END + N' THEN P.[Value] ELSE V.[Value] END, [PriorDate] = P.[PriorDate], [NextDate] = P.[NextDate]
        WHEN NOT MATCHED BY TARGET THEN INSERT
          ([Key], [Field_Id], [Date], [Value], [PriorDate], [NextDate])
        VALUES
          (P.[Key], P.[Field_Id], P.[Date], P.[Value], P.[PriorDate], P.[NextDate]);'

      +
      CASE
        WHEN @Translate_Fields_PIDs IS NOT NULL THEN N'

        MERGE [System].[Periodic:Values:Translate] V
        USING
        (
          SELECT
            P.[Field_Id], P.[Date], PT.[Value],
            [Key]                 = NP.' + QuoteName(@KeyField) + N',
            [Translate:Language]  = PT.[Translate:Language]
          FROM @Periodic P
          INNER JOIN @Periodic_T PT ON PT.[GUId] = P.[GUId] AND PT.[Field_Id] = P.[Field_Id] AND PT.[Date] = P.[Date]
          INNER JOIN @Records NP ON PT.[GUId] = NP.' + QuoteName(IsNull(@GUIdField, 'Periodic:GUId')) + N'
          WHERE P.[Field_Id] IN (' + @Translate_Fields_PIDs + N')
        ) P ON V.[Field_Id] = P.[Field_Id] AND V.[Key] = P.[Key] AND V.[Date] = P.[Date] AND V.[Language] = P.[Translate:Language]
        WHEN MATCHED AND P.[Value] IS NULL THEN DELETE
        WHEN MATCHED THEN UPDATE SET
          [Value] = Cast(P.[Value] AS NVarChar(4000))
        WHEN NOT MATCHED BY TARGET AND P.[Value] IS NOT NULL THEN INSERT
          ([Key], [Field_Id], [Date], [Language], [Value])
        VALUES
          (P.[Key], P.[Field_Id], P.[Date], P.[Translate:Language], Cast(P.[Value] AS NVarChar(4000)));'

        ELSE N''
      END

      + N'
      END'

      +
      CASE
        WHEN @Translate = 0 THEN N'

      UPDATE T SET'
          +
          [Pub].[ConCat]
          (
            CASE
              WHEN SF.[Name] <> @KeyField THEN
                N'
        '
                + [SQL].[Shift](QuoteName(SF.[Name]), 26)
                + N'= '
                +
                CASE
                  WHEN SF.[PeriodicField_Id] IS NULL THEN
                    N'CASE WHEN Priv.' + QuoteName(SF.[Name]) + N' = 1 THEN NP.'
                    + QuoteName(SF.[Name])
                    + N' ELSE T.' + QuoteName(SF.[Name])
                    + N' END'
                  ELSE
                    N'P.' + QuoteName(SF.[Name])
                END
            END,
            N','
          )

          + N'
      FROM @Records NP'
          +
          IsNull
          (
            N'
      CROSS APPLY'
            +
            [SQL].[Generate?Field Test]
            (
              [Pub].[ConCat](CASE WHEN SF.[Name] <> @KeyField AND SF.[PeriodicField_Id] IS NULL THEN SF.[Name] END, N','),
              N'NP.[Row:Fields]',
              3,
              Default
            )
            + N' Priv'
            , N''
          )
          + N'
      INNER JOIN [System].' + QuoteName(@Name) + ' T ON NP.' + QuoteName(@KeyField) + ' = T.' + QuoteName(@KeyField) + '
      INNER JOIN [System].' + QuoteName(@Name + '@Periodic') + '(@Today) P ON NP.' + QuoteName(@KeyField) + ' = P.' + QuoteName(@KeyField) + N'
      WHERE NP.[Row:Action] = ''U'''
        ELSE N'

      IF EXISTS(SELECT TOP 1 1 FROM @Records WHERE [Row:Action] IN (''U''))'
          +
          CASE
            WHEN @Translate_Fields_PIDs IS NOT NULL THEN N' BEGIN
        SET @Data_T_U =
        (
          SELECT
            [ACTION]                  = R.[Row:Action],
            [FIELDS]                  = R.[Row:Fields]'
              +
              [Pub].[Concat]
              (
                CASE
                  WHEN SF.[TranslateField_Id] IS NULL AND SF.[PeriodicFieldKind] IS NULL THEN N',
            ' + [SQL].[Shift](QuoteName(SF.[Name]), 26) + N'= R.' + QuoteName(SF.[Name])
                END,
                N''
              )

              + N',
            (
              SELECT
                [NAME]  = CASE PTF.[Field_Id]'
              +
              [Pub].[Concat]
              (
                CASE
                  WHEN SF.[TranslateField_Id] IS NOT NULL AND SF.[PeriodicField_Id] IS NOT NULL AND SF.[PeriodicFieldKind] IS NULL THEN N'
                      WHEN ' + Cast(SF.[PeriodicField_Id] AS NVarChar) + N' THEN ' + [Pub].[Quote String](SF.[Name])
                END,
                N''
              )

              + N'
                          END,
                (
                  SELECT
                    [LANGUAGE]  = L.[Language],
                    [VALUE]     = PVT.[Value]
                  FROM
                  (
                    SELECT DISTINCT
                      PVT.[Language]
                    FROM [System].[Periodic:Values:Translate] PVT
                    WHERE A.[Periodic:Field_Id] = PVT.[Field_Id] AND R.' + QuoteName(@KeyField) + N' = PVT.[Key] AND PVT.[Date] = PTF.[Date]
                      UNION
                    SELECT DISTINCT
                      TV.[Language]
                    FROM [System].[Translate:Values] TV
                    WHERE A.[Translate:Field_Id] = TV.[Field_Id] AND R.' + QuoteName(@KeyField) + N' = TV.[Key]
                  ) L
                  LEFT JOIN [System].[Periodic:Values:Translate] PVT ON R.' + QuoteName(@KeyField) + N' = PVT.[Key] AND PTF.[Field_Id] = PVT.[Field_Id] AND PTF.[Date] = PVT.[Date] AND L.[Language] = PVT.[Language]
                  FOR XML RAW(''TRANSLATE''), TYPE
                )
              FROM
              (
                SELECT
                  [Field_Id]  = PV.[Field_Id],
                  [Date]      = MAX(PV.[Date])
                FROM @Periodic PV
                WHERE R.' + QuoteName(IsNull(@GUIdField, 'Periodic:GUId')) + N' = PV.[GUId] AND PV.[Field_Id] IN (' + @Translate_Fields_PIDs + ') AND PV.[Date] <= @Today
                GROUP BY PV.[Field_Id]
              ) PTF
              INNER JOIN [System].[Periodic->Fields$#Translating] A WITH (NOEXPAND) ON PTF.[Field_Id] = A.[Periodic:Field_Id]
              FOR XML RAW(''FIELD''), TYPE
            )'
              +
              IsNull
              (
                N',
            (
              SELECT
                [NAME]      = CASE TF.[Field_Id]'
                +
                [Pub].[Concat]
                (
                  CASE
                    WHEN SF.[TranslateField_Id] IS NOT NULL AND SF.[PeriodicField_Id] IS NULL AND SF.[PeriodicFieldKind] IS NULL THEN N'
                                WHEN -' + Cast(SF.[TranslateField_Id] AS NVarChar) + N' THEN ' + [Pub].[Quote String](SF.[Name])
                  END,
                  N''
                )

                + N'
                              END,
                (
                  SELECT
                    [LANGUAGE]  = TV.[Language],
                    [VALUE]     = TV.[Value]
                  FROM @Translate TV
                  WHERE R.[GUId] = TV.[GUId] AND TF.[Field_Id] = TV.[Field_Id]
                  FOR XML RAW(''TRANSLATE''), TYPE
                )
              FROM
              (
                SELECT DISTINCT [Field_Id] FROM @Translate WHERE [Field_Id] < 0
              ) TF
              FOR XML RAW(''FIELD''), TYPE
            )'
                , N''
              )

              + N'
          FROM @Records R
          WHERE R.[Row:Action] IN (''U'')
          FOR XML RAW(''RECORD''), TYPE
        )
      END'
              ELSE N''
            END

            + N'
      EXEC [System].' + QuoteName(@Name + '(Translate Set)') + N' @Data = @Data_T_U'
      END

      +
      CASE
        WHEN @ListFieldsExists = 1 THEN
          [Pub].[Concat]
          (
            CASE
              WHEN SF.[PeriodicFieldKind] = 'L' THEN N'

      SET @SubData =
        (
          SELECT
            [ACTION]        = IsNull(Diff.[ACTION], ''U''),
            [INDEX]         = CASE WHEN Diff.[ACTION] = ''I'' THEN ROW_NUMBER() OVER(ORDER BY Diff.' + QuoteName(SF.[ForeignIdentity]) + N', Diff.' + QuoteName(SF.[ForeignList]) + N') END,
            [AGE]           = CASE WHEN Diff.[ACTION] = ''D'' THEN NULL ELSE R.[Periodic:Age] END,
            ' + [SQL].[Shift](QuoteName(SF.[ForeignIdentity]), 26)
              + N'= IsNull(Diff.' + QuoteName(SF.[ForeignIdentity]) + N', ST.' + QuoteName(SF.[ForeignIdentity]) + N')'
              +
              REPLACE
              (
                REPLACE
                (
                  REPLACE
                  (
                    SF.[ForeignLinks],
                    N'<%SOURCE%>.',
                    N',
            '
                  ),
                  N'<%TARGET%>',
                  N'CASE WHEN Diff.[ACTION] = ''I'' THEN R'
                ),
                N'<%SEPARATOR%>',
                N' END'
              )

              + N' END,
            ' + [SQL].[Shift](QuoteName(SF.[ForeignList]), 16) + N'= CASE WHEN Diff.[ACTION] = ''I'' THEN Diff.' + QuoteName(SF.[ForeignList]) + N' END,
            [FIELDS]        = CASE Diff.[ACTION] WHEN ''I'' THEN N'
              + [Pub].[Quote String]('AGE,' + SF.[ForeignKeys] + N',' + SF.[ForeignList] + N',' + SF.[ForeignValue])
              + N' WHEN ''U'' THEN N' + [Pub].[Quote String]('AGE,' + SF.[ForeignValue]) + N' WHEN ''D'' THEN NULL ELSE '''
              + CASE WHEN @DateFirstNullAble = 0 THEN @DateFirstField ELSE N'AGE' END
              + N''' END,
            (
              SELECT
                [DATE]    = P.[Date],
                ' + QuoteName(SF.[ForeignValue]) + N' = CASE WHEN P' + Cast(SF.[PeriodicField_Id] AS NVarChar) + N'.' + QuoteName(SF.[ForeignList]) + N' IS NULL THEN 1 END
              FROM @Periodic P
              LEFT JOIN @Periodic' + Cast(SF.[PeriodicField_Id] AS NVarChar)
                                            + N' P' + Cast(SF.[PeriodicField_Id] AS NVarChar)
                                            + N' ON Diff.[Row:GUId] = P' + Cast(SF.[PeriodicField_Id] AS NVarChar) + N'.[Row:GUId] AND Diff.' + QuoteName(SF.[ForeignList]) + N' = P' + Cast(SF.[PeriodicField_Id] AS NVarChar) + N'.' + QuoteName(SF.[ForeignList]) + N' AND P.[Date] = P' + Cast(SF.[PeriodicField_Id] AS NVarChar) + N'.[Periodic:Date]
              WHERE Diff.[ACTION] <> ''D'' AND P.[GUId] = Diff.[Row:GUId] AND P.[Field_Id] = ' + Cast(SF.[PeriodicField_Id] AS NVarChar) + N'
              FOR XML RAW(''PERIODIC''), TYPE
            )
          FROM @Records R
          CROSS APPLY (VALUES([Pub].[Array Test](R.[Row:Fields], N' + [Pub].[Quote String](SF.[Name] + N',' + CASE WHEN @DateFirstNullAble = 0 THEN @DateFirstField ELSE N'AGE' END) + N', N'',''))) RF([Fields])
          LEFT JOIN ' + QuoteName(SF.[ForeignTableSchema]) + N'.' + QuoteName(SF.[ForeignTableName]) + N' ST ON RF.[Fields] = 2 AND '
              + REPLACE(REPLACE(REPLACE(SF.[ForeignLinks], N'<%SOURCE%>', N'R'), N'<%TARGET%>', N'ST'), N'<%SEPARATOR%>', N' AND ')

              + N'
          OUTER APPLY (SELECT FP.[Age] FROM [Base].[Periodic:Row@Info](' + Cast(SF.[ForeignTablePeriodic_Id] AS NVarChar) + N', ST.' + QuoteName(SF.[ForeignIdentity]) + N', Default) FP WHERE ST.' + QuoteName(SF.[ForeignIdentity]) + N' IS NOT NULL) RFP
          LEFT JOIN
          (
            SELECT
              [ACTION]        = CASE WHEN New.[Row:GUId] IS NULL THEN ''D'' WHEN Old.[Row:GUId] IS NULL THEN ''I'' ELSE ''U'' END,
              ' + [SQL].[Shift](QuoteName(SF.[ForeignIdentity]), 14) + N'= Old.' + QuoteName(SF.[ForeignIdentity]) + N',
              [Row:GUId]      = IsNull(Old.[Row:GUId], New.[Row:GUId]),
              ' + [SQL].[Shift](QuoteName(SF.[ForeignList]), 14) + N'= IsNull(Old.' + QuoteName(SF.[ForeignList]) + N', New.' + QuoteName(SF.[ForeignList]) + N')
            FROM
            (
              -- Все, которые были
              SELECT
                R' + Cast(SF.[PeriodicField_Id] AS NVarChar) + N'.[Row:GUId],
                T.' + QuoteName(SF.[ForeignList]) + N',
                T.' + QuoteName(SF.[ForeignIdentity]) + N'
              FROM
              (
                SELECT DISTINCT
                  [Row:GUId] = [GUId]
                FROM @Periodic
                WHERE [Field_Id] = ' + Cast(SF.[PeriodicField_Id] AS NVarChar) + N'
              ) R' + Cast(SF.[PeriodicField_Id] AS NVarChar) + N'
              INNER JOIN @Records R ON R' + Cast(SF.[PeriodicField_Id] AS NVarChar) + N'.[Row:GUId] = R.[GUId]
              INNER JOIN ' + QuoteName(SF.[ForeignTableSchema]) + N'.' + QuoteName(SF.[ForeignTableName]) + N' T ON '
              + REPLACE(REPLACE(REPLACE(SF.[ForeignLinks], N'<%SOURCE%>', N'R'), N'<%TARGET%>', N'T'), N'<%SEPARATOR%>', N' AND ')
              + N'
            ) Old
            FULL OUTER JOIN
            (
              -- Все, кто будет
              SELECT DISTINCT
                [Row:GUId],
                ' + QuoteName(SF.[ForeignList]) + N'
              FROM @Periodic' + Cast(SF.[PeriodicField_Id] AS NVarChar) + N'
            ) New ON Old.[Row:GUId] = New.[Row:GUId] AND Old.' + QuoteName(SF.[ForeignList]) + N' = New.' + QuoteName(SF.[ForeignList]) + N'
          ) Diff ON Diff.[Row:GUId] = R.[GUId]
          WHERE R.[Row:Action] <> ''D''
              AND
              (
                RF.[Fields] & 1 <> 0
                OR
                RF.[Fields] = 2 AND R.[Periodic:Age] <> R.[Periodic:Age:Old] AND R.[Periodic:Age:Old] = RFP.[Age]
              )
              AND
              [System].[Raise Error]
              (
                @@PROCID,
                CASE
                  WHEN RF.[Fields] = 2 AND R.[Periodic:Age] <> R.[Periodic:Age:Old] AND R.[Periodic:Age:Old] < RFP.[Age] AND R.[Periodic:Age] >= RFP.[Age] THEN
                    N''Дата «'' + Convert(NVarChar, RFP.[Age], 104) + N''» первой периодики поля «' + SF.[Name] + N'» не позволяет скорректировать возраст записи''
                END
              ) IS NULL
          FOR XML RAW(''RECORD''), TYPE
        )

      EXEC ' + QuoteName(SF.[ForeignTableSchema]) + N'.' + QuoteName(SF.[ForeignTableName] + N'(Periodic Set)') + N' @Data = @SubData'
            END
            , N''
          )
        ELSE N''
      END

      +
      CASE
        WHEN @Logging = 1 THEN N'

      EXEC [System].[Log@Commit]'
        ELSE N''
      END

      + N'

      WHILE @@TranCount > @TranCount COMMIT TRAN
      SET @Retry = 0
    END TRY
    BEGIN CATCH
      SET @ErrorNumber = ERROR_NUMBER()
      IF @ErrorNumber IN (1205, 51205) BEGIN -- DEAD LOCK OR USER DEAD LOCK
        SET @ErrorNumber = 51205
        SET @Retry = @Retry - 1
      END ELSE
        SET @Retry = 0

      IF XACT_STATE() <> 0
        IF XACT_STATE() = -1 OR @@TRANCOUNT > @TranCount
          ROLLBACK TRAN
        ELSE IF @@TRANCOUNT = @TranCount
          ROLLBACK TRAN PS_TRAN

      IF @@TranCount > 0 OR @Retry = 0
        EXEC [System].[ReRaise Error] @ErrorNumber = @ErrorNumber, @ProcedureId = @@PROCID
      ELSE BEGIN
        WAITFOR DELAY ''00:00:00.500'''
      +
      CASE
        WHEN @KeyFieldIdentity = 1 THEN N'

        DELETE @Inserted'
        ELSE N''
      END
      + N'
      END
    END CATCH

OK_EXIT:
    RETURN 1
  END TRY
  BEGIN CATCH
    EXEC [System].[ReRaise Error] @ErrorNumber = @ErrorNumber, @ProcedureId = @@PROCID
  END CATCH'

          FROM (SELECT TOP 1000000 * FROM @AllFields ORDER BY IsNull([Column_Id], 1000000), [PeriodicField_Id]) SF
          WHERE (SF.[IsIdentityOrComputed] = 0 OR SF.[Name] = @KeyField)
            AND SF.[IsService] = 0
            AND SF.[Name] NOT LIKE '%[^0-9A-Z_]%'
        )

        EXEC [SQL].[Debug Exec] @SQL = @SQL, @RaiseIfEmpty = 'Interface Procedure :: Set', @Debug = @Debug
    END ELSE IF OBJECT_ID(@Object) IS NOT NULL BEGIN
      SET @SQL = 'DROP PROC ' + @Object
      EXEC [SQL].[Debug Exec] @SQL = @SQL, @Debug = @Debug
    END

    PRINT '  Periodic structure for table «[System].' + QuoteName(@Name) + '» has been ' + CASE WHEN @Release = 0 THEN 'updated' ELSE 'cleaned' END + '.'

    RETURN 1
  END TRY
  BEGIN CATCH
    EXEC [System].[ReRaise Error] @ProcedureId = @@PROCID
  END CATCH