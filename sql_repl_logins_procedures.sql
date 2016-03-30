USE [BackOffice]
GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_Repl_sysxlogins]    Script Date: 07/11/2007 18:43:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_MSins_Repl_sysxlogins]
	@c1 varbinary(85),
	@c2 nvarchar(128),
	@c3 varbinary(256),
	@c4 tinyint
AS
	set implicit_transactions off
	-- MS SQL Server 2005
	declare @SQL varchar(1000)

		if not exists(select 1 from master..syslogins (nolock) where [name] = @c2) begin
			-- MS SQL Server 2000 and low
			-- exec master..sp_addlogin @loginame = @c2, @passwd = @c3, @sid = @c1, @encryptopt = 'skip_encryption' 
			-- MS SQL Server 2005
			set @SQL = 'CREATE LOGIN [' + @c2 + '] WITH PASSWORD = ' + BackOffice.dbo.hp_VarBinaryToVarChar(@c3) + ' HASHED, SID = ' + BackOffice.dbo.hp_VarBinaryToVarChar(@c1) + ', CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF'
			exec(@SQL)
		end

		if not exists(select 1 from BackOffice..sysusers (nolock) where [name] = @c2) begin
			-- MS SQL Server 2000 and low
			-- exec sp_grantdbaccess @loginame = @c2, @name_in_db = @c2
			-- MS SQL Server 2005
			set @SQL = 'USE BackOffice CREATE USER [' + @c2 + ']'
			exec(@SQL)
		end else begin
			-- MS SQL Server 2000 and low
			-- exec BackOffice..sp_change_users_login @Action = 'Update_One', @UserNamePattern = @c2, @LoginName = @c2
			-- MS SQL Server 2005
			set @SQL = 'USE BackOffice DROP USER [' + @c2 + '] CREATE USER [' + @c2 + ']'
			exec(@SQL)
		end

		if @c4 = 1 exec sp_addrolemember @rolename = 'Access_To_Report_Server', @membername = @c2

		if not exists(select 1 from FinamDepo..sysusers (nolock) where [name] = @c2) begin
			-- MS SQL Server 2000 and low
			-- exec FinamDepo..sp_grantdbaccess @loginame = @c2, @name_in_db = @c2
			-- MS SQL Server 2005
			set @SQL = 'USE FinamDepo CREATE USER [' + @c2 + ']'
			exec(@SQL)
		end else begin
			-- MS SQL Server 2000 and low
			-- exec FinamDepo..sp_change_users_login @Action = 'Update_One', @UserNamePattern = @c2, @LoginName = @c2
			-- MS SQL Server 2005
			set @SQL = 'USE FinamDepo DROP USER [' + @c2 + '] CREATE USER [' + @c2 + ']'
			exec(@SQL)
		end
GO
ALTER PROCEDURE [dbo].[sp_MSupd_Repl_sysxlogins]
 	@c1 varbinary(85),
	@c2 nvarchar(128),
	@c3 varbinary(256),
	@c4 tinyint,
	@pkc1 varbinary(85),
	@bitmap binary(1)
as
	set implicit_transactions off

	select
		@c1 = case @bitmap & 1 when 1 then @c1 else @pkc1 end,
		@c2 = case @bitmap & 2 when 2 then @c2 else [name] end,
		@c3 = case @bitmap & 4 when 4 then @c3 else cast([password] as varbinary(256)) end,
		@c4 = case @bitmap & 8 when 8 then @c4 else (select top 1 1 from BackOffice.dbo.sysusers (nolock) Where sid = @pkc1) end
	from master..syslogins (nolock) 
	where [sid] = @pkc1

	if @@rowcount = 0 or @bitmap & 3 <> 0 begin
		exec sp_MSdel_Repl_sysxlogins @pkc1 = @pkc1
		if @c1 is not null and @c2 is not null and @c3 is not null and @c4 is not null
			exec sp_MSins_Repl_sysxlogins @c1 = @c1, @c2 = @c2, @c3 = @c3, @c4 = @c4
	end else begin
		if @bitmap & 4 = 4
			-- MS SQL Server 2000 and low ...
			-- update master..sysxlogins set [password] = @c3 where sid = @pkc1
			-- MS SQL Server 2005
		begin
			declare @SQL varchar(1000)
			set @SQL = 'ALTER LOGIN [' + @c2 + '] WITH PASSWORD = ' + BackOffice.dbo.hp_VarBinaryToVarChar(@c3) + ' HASHED, CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF'
			exec(@SQL)
		end
		if @bitmap & 8 = 8 begin
			if @c4 = 1 exec sp_addrolemember 'Access_To_Report_Server', @c2
			else exec sp_droprolemember 'Access_To_Report_Server', @c2
		end
	end
GO
ALTER PROCEDURE [dbo].[sp_MSdel_Repl_sysxlogins]
	@pkc1 varbinary(85)
as
	set implicit_transactions off
	-- MS SQL Server 2005
	declare @SQL varchar(1000)

	declare @name sysname

	select @name = [name] from BackOffice.dbo.sysusers (nolock) where sid = @pkc1
	if @@rowcount > 0 begin
		-- MS SQL Server 2000 and low
		-- exec BackOffice.dbo.sp_dropuser @name_in_db = @name
		-- MS SQL Server 2005
		set @SQL = 'USE BackOffice DROP USER [' + @name + ']'
		exec(@SQL)
	end

	select @name = [name] from FinamDepo.dbo.sysusers (nolock) where sid = @pkc1
	if @@rowcount > 0 begin 
		-- MS SQL Server 2000 and low
		-- exec FinamDepo.dbo.sp_dropuser @name_in_db = @name
		-- MS SQL Server 2005
		set @SQL = 'USE FinamDepo DROP USER [' + @name + ']'
		exec(@SQL)
	end

	select @name = [name] from master.dbo.syslogins (nolock) where sid = @pkc1
	if @@rowcount > 0 begin
		-- MS SQL Server 2000 and low
		-- exec sp_droplogin @loginame = @name
		-- MS SQL Server 2005
		set @SQL = 'USE FinamDepo DROP LOGIN [' + @name + ']'
		exec(@SQL)
	end
GO
