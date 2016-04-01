    SELECT
    Sum
    (
      [Pub].[Char Count](I.[definition], Char(13))
    )
    FROM
    (
      SELECT
        [object_name]     = QuoteName(schema_name(SO.[schema_id])) + '.' + QuoteName(object_name(SO.[object_id])),
        [definition]      = OBJECT_DEFINITION(so.[object_id], SC.[number]),
        [object_version]  = SC.[number]
      FROM sys.objects SO (NOLOCK)
      CROSS APPLY
      (
        SELECT DISTINCT
          SC.[number]
        FROM sys.syscomments SC (NOLOCK)
        WHERE sc.[id] = so.[object_id]
        GROUP BY SC.[number]
      ) SC
    ) I
