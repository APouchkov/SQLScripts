CREATE PROCEDURE [dbo].[sp_help_revlogin] 
  @login_name sysname = NULL
AS
  SET NOCOUNT ON
  
  DECLARE
    @SID_varbinary    varbinary(85),
    @name             varchar(255),
    @default_database varchar(256),
    @type             char(1),
    @Disabled         Bit,
    @Deny             Bit,
    @CheckPolicy      Bit,
    @CheckExpiration  Bit,
    @binpwd           varbinary(256),
    
    @txtpwd           varchar(255),
    @tmpstr           varchar(256),
    @SID_string       varchar(256)

  DECLARE login_curs CURSOR FOR
  SELECT
    SP.sid,
    SP.name,
    SP.default_database_name,
    SP.type,
    SP.is_disabled,
    [DenyLogin] = Cast(CASE WHEN PR.[state] = 'D' THEN 1 ELSE 0 END AS Bit),
    SL.is_policy_checked,
    SL.is_expiration_checked,
    SL.password_hash
  FROM sys.server_principals SP
  LEFT MERGE JOIN sys.sql_logins SL ON SP.principal_id = SL.principal_id
  LEFT LOOP JOIN sys.server_permissions PR ON SP.principal_id = PR.grantee_principal_id AND PR.[type] = 'COSQ' AND PR.[state] = 'D'
  WHERE SP.type IN ('S', 'U', 'G') AND SP.[name] NOT IN ('sa') AND (@login_name IS NULL OR @login_name = SP.[name])
  ORDER BY CASE SP.type WHEN 'U' THEN 1 WHEN 'G' THEN 2 ELSE 3 END, SP.name
  OPTION (FORCE ORDER, MAXDOP 1)

  OPEN login_curs 

  FETCH NEXT FROM login_curs 
  INTO @SID_varbinary, @name, @default_database, @type, @Disabled, @Deny, @CheckPolicy, @CheckExpiration, @binpwd

  IF (@@fetch_status = -1)
  BEGIN
    PRINT 'No login(s) found.'
    CLOSE login_curs 
    DEALLOCATE login_curs 
    RETURN -1
  END

  SET @tmpstr = '/* sp_help_revlogin script ' 
  PRINT @tmpstr
  SET @tmpstr = '** Generated ' 
    + CONVERT (varchar, GETDATE()) + ' on ' + @@ServerNAME + ' */'
  PRINT @tmpstr

  WHILE (@@fetch_status <> -1) BEGIN
    IF (@@fetch_status <> -2) BEGIN
      PRINT ''
      SET @tmpstr = '-- Login: ' + @name
      PRINT @tmpstr 

          IF @binpwd IS NOT NULL
            EXEC sp_hexadecimal @binpwd, @txtpwd OUT

          EXEC sp_hexadecimal @SID_varbinary, @SID_string OUT

          SET @tmpstr = 
              'CREATE LOGIN ' 
                + QuoteName(@name)
                + CASE 
                    WHEN @type IN ('U', 'G') 
                      THEN ' FROM WINDOWS WITH '
                    WHEN @binpwd IS NOT NULL
                      THEN ' WITH PASSWORD = '
                            + @txtpwd 
                            + ' HASHED, SID = ' 
                            + @SID_string 
                            + ', CHECK_EXPIRATION = ' 
                            + CASE WHEN @CheckExpiration = 1 THEN 'ON' ELSE 'OFF' END 
                            + ', CHECK_POLICY = ' + CASE WHEN @CheckPolicy = 1 THEN 'ON' ELSE 'OFF' END
                            + ', '
                    ELSE
                      ''
                    END
                + 'DEFAULT_DATABASE = ' + QuoteName(@default_database)
                + CASE WHEN @Disabled = 1 THEN char(13) + char(10) + 'ALTER LOGIN ' + QuoteName(@name) + ' DISABLE' ELSE '' END
                + CASE WHEN @Deny = 1 THEN char(13) + char(10) + 'DENY CONNECT SQL TO ' + QuoteName(@name) ELSE '' END
          
      PRINT @tmpstr 
      FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @default_database, @type, @Disabled, @Deny, @CheckPolicy, @CheckExpiration, @binpwd
    END
  END

  CLOSE login_curs 
  DEALLOCATE login_curs 
  RETURN 0
GO

/****** Object:  StoredProcedure [dbo].[sp_hexadecimal]    Script Date: 04/21/2009 20:11:08 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_hexadecimal]
  @binvalue varbinary(256),
  @hexvalue varchar(256) OUTPUT
AS
  SET NOCOUNT ON

  DECLARE @charvalue varchar(256)
  DECLARE @i int
  DECLARE @length int
  DECLARE @hexstring char(16)
  SELECT @charvalue = '0x'
  SELECT @i = 1
  SELECT @length = DATALENGTH (@binvalue)
  SELECT @hexstring = '0123456789ABCDEF'
  WHILE (@i <= @length)
  BEGIN
    DECLARE @tempint int
    DECLARE @firstint int
    DECLARE @secondint int
    SELECT @tempint = CONVERT(int, SUBSTRING(@binvalue,@i,1))
    SELECT @firstint = FLOOR(@tempint/16)
    SELECT @secondint = @tempint - (@firstint*16)
    SELECT @charvalue = @charvalue +
      SUBSTRING(@hexstring, @firstint+1, 1) +
      SUBSTRING(@hexstring, @secondint+1, 1)
    SELECT @i = @i + 1
  END

  SELECT @hexvalue = @charvalue
GO
