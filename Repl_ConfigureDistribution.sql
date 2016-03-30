/****** Scripting replication configuration for server WBASE. Script Date: 18.07.2007 15:47:30 ******/
/****** Please Note: For security reasons, all password parameters were scripted with either NULL or an empty string. ******/

/****** Installing the server WBASE as a Distributor. Script Date: 18.07.2007 15:47:30 ******/
use master
exec sp_adddistributor @distributor = N'WBASE', @password = N''
GO
exec sp_adddistributiondb @database = N'distribution', @data_folder = N'D:\MSSQL\DataBases', @log_folder = N'D:\MSSQL\DataBases', @log_file_size = 2, @min_distretention = 0, @max_distretention = 72, @history_retention = 48, @security_mode = 1
GO

use [distribution] 
if (not exists (select * from sysobjects where name = 'UIProperties' and type = 'U ')) 
	create table UIProperties(id int) 
if (exists (select * from ::fn_listextendedproperty('SnapshotFolder', 'user', 'dbo', 'table', 'UIProperties', null, null))) 
	EXEC sp_updateextendedproperty N'SnapshotFolder', N'D:\MSSQL\REPLDATA', 'user', dbo, 'table', 'UIProperties' 
else 
	EXEC sp_addextendedproperty N'SnapshotFolder', 'D:\MSSQL\REPLDATA', 'user', dbo, 'table', 'UIProperties'
GO

exec sp_adddistpublisher @publisher = N'wbase', @distribution_db = N'distribution', @security_mode = 1, @working_directory = N'D:\MSSQL\REPLDATA', @trusted = N'false', @thirdparty_flag = 0, @publisher_type = N'MSSQLSERVER'
GO
