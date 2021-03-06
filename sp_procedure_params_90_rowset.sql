USE mssqlsystemresource
GO
ALTER DATABASE [mssqlsystemresource] SET READ_WRITE WITH ROLLBACK IMMEDIATE
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [sys].[sp_procedure_params_90_rowset]
(
    @procedure_name     sysname,
    @group_number       int = 1,
    @procedure_schema   sysname = null,
    @parameter_name     sysname = null
)
as
    select
        PROCEDURE_CATALOG           = s_pp.PROCEDURE_CATALOG,
        PROCEDURE_SCHEMA            = s_pp.PROCEDURE_SCHEMA,
        PROCEDURE_NAME              = convert(nvarchar(134),
                                                s_pp.PROCEDURE_NAME +';'+ 
                                                ltrim(str(coalesce(s_pp.procedure_number,@group_number,1), 5))),
        PARAMETER_NAME              = s_pp.PARAMETER_NAME,
        ORDINAL_POSITION            = s_pp.ORDINAL_POSITION,
        PARAMETER_TYPE              = s_pp.PARAMETER_TYPE,
        PARAMETER_HASDEFAULT        = s_pp.PARAMETER_HASDEFAULT,
        PARAMETER_DEFAULT           = s_pp.PARAMETER_DEFAULT,
        IS_NULLABLE                 = s_pp.IS_NULLABLE,
        DATA_TYPE                   = s_pp.DATA_TYPE, -- Used by Yukon+ clients
        CHARACTER_MAXIMUM_LENGTH    = s_pp.CHARACTER_MAXIMUM_LENGTH,
        CHARACTER_OCTET_LENGTH      = s_pp.CHARACTER_OCTET_LENGTH,
        NUMERIC_PRECISION           = s_pp.NUMERIC_PRECISION,
        NUMERIC_SCALE               = s_pp.NUMERIC_SCALE,
        DESCRIPTION                 = s_pp.DESCRIPTION,
        TYPE_NAME                   = s_pp.TYPE_NAME,
        LOCAL_TYPE_NAME             = s_pp.LOCAL_TYPE_NAME,
        SS_XML_SCHEMACOLLECTION_CATALOGNAME = s_pp.SS_XML_SCHEMACOLLECTION_CATALOGNAME,
        SS_XML_SCHEMACOLLECTION_SCHEMANAME  = s_pp.SS_XML_SCHEMACOLLECTION_SCHEMANAME,
        SS_XML_SCHEMACOLLECTIONNAME = s_pp.SS_XML_SCHEMACOLLECTIONNAME,
        SS_UDT_CATALOGNAME          = s_pp.SS_UDT_CATALOGNAME,
        SS_UDT_SCHEMANAME           = s_pp.SS_UDT_SCHEMANAME,
        SS_UDT_NAME                 = s_pp.SS_UDT_NAME,
        SS_UDT_ASSEMBLY_TYPENAME    = s_pp.SS_UDT_ASSEMBLY_TYPENAME
    
    from
        sys.spt_procedure_params_view s_pp

    where
        (@procedure_schema is null and s_pp.PROCEDURE_NAME = @procedure_name)   
        and 
        (
            @group_number is null or
            (s_pp.procedure_number = @group_number and s_pp.type = 'P') or
            (s_pp.procedure_number = 0             and s_pp.type in ('FN', 'TF', 'IF'))
        ) 
        and
        (@parameter_name is null or @parameter_name = s_pp.PARAMETER_NAME)

    UNION ALL

    select
        PROCEDURE_CATALOG           = s_pp.PROCEDURE_CATALOG,
        PROCEDURE_SCHEMA            = s_pp.PROCEDURE_SCHEMA,
        PROCEDURE_NAME              = convert(nvarchar(134),
                                                s_pp.PROCEDURE_NAME +';'+ 
                                                ltrim(str(coalesce(s_pp.procedure_number,@group_number,1), 5))),
        PARAMETER_NAME              = s_pp.PARAMETER_NAME,
        ORDINAL_POSITION            = s_pp.ORDINAL_POSITION,
        PARAMETER_TYPE              = s_pp.PARAMETER_TYPE,
        PARAMETER_HASDEFAULT        = s_pp.PARAMETER_HASDEFAULT,
        PARAMETER_DEFAULT           = s_pp.PARAMETER_DEFAULT,
        IS_NULLABLE                 = s_pp.IS_NULLABLE,
        DATA_TYPE                   = s_pp.DATA_TYPE, -- Used by Yukon+ clients
        CHARACTER_MAXIMUM_LENGTH    = s_pp.CHARACTER_MAXIMUM_LENGTH,
        CHARACTER_OCTET_LENGTH      = s_pp.CHARACTER_OCTET_LENGTH,
        NUMERIC_PRECISION           = s_pp.NUMERIC_PRECISION,
        NUMERIC_SCALE               = s_pp.NUMERIC_SCALE,
        DESCRIPTION                 = s_pp.DESCRIPTION,
        TYPE_NAME                   = s_pp.TYPE_NAME,
        LOCAL_TYPE_NAME             = s_pp.LOCAL_TYPE_NAME,
        SS_XML_SCHEMACOLLECTION_CATALOGNAME = s_pp.SS_XML_SCHEMACOLLECTION_CATALOGNAME,
        SS_XML_SCHEMACOLLECTION_SCHEMANAME  = s_pp.SS_XML_SCHEMACOLLECTION_SCHEMANAME,
        SS_XML_SCHEMACOLLECTIONNAME = s_pp.SS_XML_SCHEMACOLLECTIONNAME,
        SS_UDT_CATALOGNAME          = s_pp.SS_UDT_CATALOGNAME,
        SS_UDT_SCHEMANAME           = s_pp.SS_UDT_SCHEMANAME,
        SS_UDT_NAME                 = s_pp.SS_UDT_NAME,
        SS_UDT_ASSEMBLY_TYPENAME    = s_pp.SS_UDT_ASSEMBLY_TYPENAME
    
    from
        sys.spt_procedure_params_view s_pp

    where
        (@procedure_schema is not null and s_pp.object_id = object_id(quotename(@procedure_schema) + '.' + quotename(@procedure_name)))    
        and 
        (
            @group_number is null or
            (s_pp.procedure_number = @group_number and s_pp.type = 'P') or
            (s_pp.procedure_number = 0             and s_pp.type in ('FN', 'TF', 'IF'))
        ) 
        and
        (@parameter_name is null or @parameter_name = s_pp.PARAMETER_NAME)

    UNION ALL

    select
        PROCEDURE_CATALOG           = s_pprv.PROCEDURE_CATALOG,
        PROCEDURE_SCHEMA            = s_pprv.PROCEDURE_SCHEMA,
        PROCEDURE_NAME              = convert(nvarchar(134),
                                                s_pprv.PROCEDURE_NAME +';'+ 
                                                ltrim(str(coalesce(s_pprv.procedure_number,@group_number,1), 5))),
        PARAMETER_NAME              = s_pprv.PARAMETER_NAME,
        ORDINAL_POSITION            = s_pprv.ORDINAL_POSITION,
        PARAMETER_TYPE              = s_pprv.PARAMETER_TYPE,
        PARAMETER_HASDEFAULT        = s_pprv.PARAMETER_HASDEFAULT,
        PARAMETER_DEFAULT           = s_pprv.PARAMETER_DEFAULT,
        IS_NULLABLE                 = s_pprv.IS_NULLABLE,
        DATA_TYPE                   = s_pprv.DATA_TYPE, -- Return value is either int or empty.
        CHARACTER_MAXIMUM_LENGTH    = s_pprv.CHARACTER_MAXIMUM_LENGTH,
        CHARACTER_OCTET_LENGTH      = s_pprv.CHARACTER_OCTET_LENGTH,
        NUMERIC_PRECISION           = s_pprv.NUMERIC_PRECISION,
        NUMERIC_SCALE               = s_pprv.NUMERIC_SCALE,
        DESCRIPTION                 = s_pprv.DESCRIPTION,
        TYPE_NAME                   = s_pprv.TYPE_NAME,
        LOCAL_TYPE_NAME             = s_pprv.LOCAL_TYPE_NAME,
        SS_XML_SCHEMACOLLECTION_CATALOGNAME = s_pprv.SS_XML_SCHEMACOLLECTION_CATALOGNAME,
        SS_XML_SCHEMACOLLECTION_SCHEMANAME  = s_pprv.SS_XML_SCHEMACOLLECTION_SCHEMANAME,
        SS_XML_SCHEMACOLLECTIONNAME = s_pprv.SS_XML_SCHEMACOLLECTIONNAME,
        SS_UDT_CATALOGNAME          = s_pprv.SS_UDT_CATALOGNAME,
        SS_UDT_SCHEMANAME           = s_pprv.SS_UDT_SCHEMANAME,
        SS_UDT_NAME                 = s_pprv.SS_UDT_NAME,
        SS_UDT_ASSEMBLY_TYPENAME    = s_pprv.SS_UDT_ASSEMBLY_TYPENAME

    from
        sys.spt_procedure_params_return_values_view s_pprv

    where
        (@procedure_schema is null and s_pprv.PROCEDURE_NAME = @procedure_name)
        and
        (
            @parameter_name is null or
            (@parameter_name = '@RETURN_VALUE' and s_pprv.type = 'P') or
            (@parameter_name = '@TABLE_RETURN_VALUE' and s_pprv.type <> 'P')
        )
		and 
		(
			@group_number is null or
            (s_pprv.procedure_number = 0             and s_pprv.type in ('FN', 'TF', 'IF')) or
            (isnull(s_pprv.procedure_number,1) = @group_number and s_pprv.type = 'P')
		)
    UNION ALL

    select
        PROCEDURE_CATALOG           = s_pprv.PROCEDURE_CATALOG,
        PROCEDURE_SCHEMA            = s_pprv.PROCEDURE_SCHEMA,
        PROCEDURE_NAME              = convert(nvarchar(134),
                                                s_pprv.PROCEDURE_NAME +';'+ 
                                                ltrim(str(coalesce(s_pprv.procedure_number,@group_number,1), 5))),
        PARAMETER_NAME              = s_pprv.PARAMETER_NAME,
        ORDINAL_POSITION            = s_pprv.ORDINAL_POSITION,
        PARAMETER_TYPE              = s_pprv.PARAMETER_TYPE,
        PARAMETER_HASDEFAULT        = s_pprv.PARAMETER_HASDEFAULT,
        PARAMETER_DEFAULT           = s_pprv.PARAMETER_DEFAULT,
        IS_NULLABLE                 = s_pprv.IS_NULLABLE,
        DATA_TYPE                   = s_pprv.DATA_TYPE, -- Return value is either int or empty.
        CHARACTER_MAXIMUM_LENGTH    = s_pprv.CHARACTER_MAXIMUM_LENGTH,
        CHARACTER_OCTET_LENGTH      = s_pprv.CHARACTER_OCTET_LENGTH,
        NUMERIC_PRECISION           = s_pprv.NUMERIC_PRECISION,
        NUMERIC_SCALE               = s_pprv.NUMERIC_SCALE,
        DESCRIPTION                 = s_pprv.DESCRIPTION,
        TYPE_NAME                   = s_pprv.TYPE_NAME,
        LOCAL_TYPE_NAME             = s_pprv.LOCAL_TYPE_NAME,
        SS_XML_SCHEMACOLLECTION_CATALOGNAME = s_pprv.SS_XML_SCHEMACOLLECTION_CATALOGNAME,
        SS_XML_SCHEMACOLLECTION_SCHEMANAME  = s_pprv.SS_XML_SCHEMACOLLECTION_SCHEMANAME,
        SS_XML_SCHEMACOLLECTIONNAME = s_pprv.SS_XML_SCHEMACOLLECTIONNAME,
        SS_UDT_CATALOGNAME          = s_pprv.SS_UDT_CATALOGNAME,
        SS_UDT_SCHEMANAME           = s_pprv.SS_UDT_SCHEMANAME,
        SS_UDT_NAME                 = s_pprv.SS_UDT_NAME,
        SS_UDT_ASSEMBLY_TYPENAME    = s_pprv.SS_UDT_ASSEMBLY_TYPENAME

    from
        sys.spt_procedure_params_return_values_view s_pprv

    where
        (@procedure_schema is not null and s_pprv.object_id = object_id(quotename(@procedure_schema) + '.' + quotename(@procedure_name)))
        and
        (
            @parameter_name is null or
            (@parameter_name = '@RETURN_VALUE' and s_pprv.type = 'P') or
            (@parameter_name = '@TABLE_RETURN_VALUE' and s_pprv.type <> 'P')
        )
		and 
		(
			@group_number is null or
            (s_pprv.procedure_number = 0             and s_pprv.type in ('FN', 'TF', 'IF')) or
            (isnull(s_pprv.procedure_number,1) = @group_number and s_pprv.type = 'P')
		)
    order by 2, 3, 5
    option (OPTIMIZE CORRELATED UNION ALL)
GO
ALTER procedure [sys].[sp_procedure_params_90_rowset2]
(
    @procedure_schema   sysname = null,
    @parameter_name     sysname = null
)
as
-------------------------------------------------------------------------------------------
-- copy & pasted from version 1 of the SProc and removed checks for 1st parameter !
-------------------------------------------------------------------------------------------
    select
        PROCEDURE_CATALOG           = s_pp.PROCEDURE_CATALOG,
        PROCEDURE_SCHEMA            = s_pp.PROCEDURE_SCHEMA,
        PROCEDURE_NAME              = convert(nvarchar(134),
						s_pp.PROCEDURE_NAME + case s_pp.procedure_number
							when 0 then '' 
							else ';' + isnull(cast(s_pp.procedure_number as varchar),'1')
						end),
        PARAMETER_NAME              = s_pp.PARAMETER_NAME,
        ORDINAL_POSITION            = s_pp.ORDINAL_POSITION,
        PARAMETER_TYPE              = s_pp.PARAMETER_TYPE,
        PARAMETER_HASDEFAULT        = s_pp.PARAMETER_HASDEFAULT,
        PARAMETER_DEFAULT           = s_pp.PARAMETER_DEFAULT,
        IS_NULLABLE                 = s_pp.IS_NULLABLE,
        DATA_TYPE                   = s_pp.DATA_TYPE, -- Used by Yukon+ clients
        CHARACTER_MAXIMUM_LENGTH    = s_pp.CHARACTER_MAXIMUM_LENGTH,
        CHARACTER_OCTET_LENGTH      = s_pp.CHARACTER_OCTET_LENGTH,
        NUMERIC_PRECISION           = s_pp.NUMERIC_PRECISION,
        NUMERIC_SCALE               = s_pp.NUMERIC_SCALE,
        DESCRIPTION                 = s_pp.DESCRIPTION,
        TYPE_NAME                   = s_pp.TYPE_NAME,
        LOCAL_TYPE_NAME             = s_pp.LOCAL_TYPE_NAME,
        SS_XML_SCHEMACOLLECTION_CATALOGNAME = s_pp.SS_XML_SCHEMACOLLECTION_CATALOGNAME,
        SS_XML_SCHEMACOLLECTION_SCHEMANAME  = s_pp.SS_XML_SCHEMACOLLECTION_SCHEMANAME,
        SS_XML_SCHEMACOLLECTIONNAME = s_pp.SS_XML_SCHEMACOLLECTIONNAME,
        SS_UDT_CATALOGNAME          = s_pp.SS_UDT_CATALOGNAME,
        SS_UDT_SCHEMANAME           = s_pp.SS_UDT_SCHEMANAME,
        SS_UDT_NAME                 = s_pp.SS_UDT_NAME,
        SS_UDT_ASSEMBLY_TYPENAME    = s_pp.SS_UDT_ASSEMBLY_TYPENAME

    from
        sys.spt_procedure_params_view s_pp

    where
        (@procedure_schema is null or schema_id(@procedure_schema) = s_pp.schema_id)
        and
        (
            (s_pp.type = 'P') or
            (s_pp.procedure_number = 0 and s_pp.type in ('FN', 'TF', 'IF'))
        ) and
        (@parameter_name is null or @parameter_name = s_pp.PARAMETER_NAME)

    UNION ALL

    select
        PROCEDURE_CATALOG           = s_pprv.PROCEDURE_CATALOG,
        PROCEDURE_SCHEMA            = s_pprv.PROCEDURE_SCHEMA,
        PROCEDURE_NAME              = convert(nvarchar(134),
						s_pprv.PROCEDURE_NAME + case s_pprv.procedure_number
							when 0 then '' 
							else ';' + isnull(cast(s_pprv.procedure_number as varchar),'1')
						end),
        PARAMETER_NAME              = s_pprv.PARAMETER_NAME,
        ORDINAL_POSITION            = s_pprv.ORDINAL_POSITION,
        PARAMETER_TYPE              = s_pprv.PARAMETER_TYPE,
        PARAMETER_HASDEFAULT        = s_pprv.PARAMETER_HASDEFAULT,
        PARAMETER_DEFAULT           = s_pprv.PARAMETER_DEFAULT,
        IS_NULLABLE                 = s_pprv.IS_NULLABLE,
        DATA_TYPE                   = s_pprv.DATA_TYPE, -- Return value is either int or empty.
        CHARACTER_MAXIMUM_LENGTH    = s_pprv.CHARACTER_MAXIMUM_LENGTH,
        CHARACTER_OCTET_LENGTH      = s_pprv.CHARACTER_OCTET_LENGTH,
        NUMERIC_PRECISION           = s_pprv.NUMERIC_PRECISION,
        NUMERIC_SCALE               = s_pprv.NUMERIC_SCALE,
        DESCRIPTION                 = s_pprv.DESCRIPTION,
        TYPE_NAME                   = s_pprv.TYPE_NAME,
        LOCAL_TYPE_NAME             = s_pprv.LOCAL_TYPE_NAME,
        SS_XML_SCHEMACOLLECTION_CATALOGNAME = s_pprv.SS_XML_SCHEMACOLLECTION_CATALOGNAME,
        SS_XML_SCHEMACOLLECTION_SCHEMANAME  = s_pprv.SS_XML_SCHEMACOLLECTION_SCHEMANAME,
        SS_XML_SCHEMACOLLECTIONNAME = s_pprv.SS_XML_SCHEMACOLLECTIONNAME,
        SS_UDT_CATALOGNAME          = s_pprv.SS_UDT_CATALOGNAME,
        SS_UDT_SCHEMANAME           = s_pprv.SS_UDT_SCHEMANAME,
        SS_UDT_NAME                 = s_pprv.SS_UDT_NAME,
        SS_UDT_ASSEMBLY_TYPENAME    = s_pprv.SS_UDT_ASSEMBLY_TYPENAME

    from
        sys.spt_procedure_params_return_values_view s_pprv

    where
        (@procedure_schema is null or schema_id(@procedure_schema) = s_pprv.schema_id) and
        (
            @parameter_name is null or
            (@parameter_name = '@RETURN_VALUE' and s_pprv.type = 'P') or
            (@parameter_name = '@TABLE_RETURN_VALUE' and s_pprv.type <> 'P')
        )

    order by 2, 3, 5
GO
ALTER procedure [sys].[sp_procedures_rowset2]
(
    @procedure_schema   sysname = null
)       
as
    select
        PROCEDURE_CATALOG       = db_name(),
        PROCEDURE_SCHEMA        = schema_name(pro.schema_id),
        PROCEDURE_NAME          = convert(nvarchar(134),pro.name + case when pro.procedure_number=0 then '' else ';' + cast(pro.procedure_number as varchar) end),
        PROCEDURE_TYPE          = convert(smallint, 3), -- DB_PT_FUNCTION
        PROCEDURE_DEFINITION    = convert(nvarchar(1),null),
        DESCRIPTION             = convert(nvarchar(1),null),
        DATE_CREATED            = pro.create_date,
        DATE_MODIFIED           = convert(datetime,null)
    from    
        sys.spt_all_procedures pro
    where
        (@procedure_schema is null or schema_id(@procedure_schema) = pro.schema_id)
    order by 2, 3
GO
ALTER DATABASE [mssqlsystemresource] SET READ_ONLY WITH ROLLBACK IMMEDIATE
GO
