/****** Object:  LinkedServer [WBOGATE]    Script Date: 07/09/2007 19:57:24 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'WBOGATE', @srvproduct=N'SQL Server'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBOGATE',@useself=N'False',@locallogin=NULL,@rmtuser=N'BackOffice',@rmtpassword='########'

GO
EXEC master.dbo.sp_serveroption @server=N'WBOGATE', @optname=N'collation compatible', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOGATE', @optname=N'data access', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOGATE', @optname=N'dist', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOGATE', @optname=N'pub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOGATE', @optname=N'rpc', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOGATE', @optname=N'rpc out', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOGATE', @optname=N'sub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOGATE', @optname=N'connect timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOGATE', @optname=N'collation name', @optvalue=null
GO
EXEC master.dbo.sp_serveroption @server=N'WBOGATE', @optname=N'lazy schema validation', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOGATE', @optname=N'query timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOGATE', @optname=N'use remote collation', @optvalue=N'true'


/****** Object:  LinkedServer [WBOREPORT1]    Script Date: 07/09/2007 19:57:29 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'WBOREPORT1', @srvproduct=N'SQL Server'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBOREPORT1',@useself=N'True',@locallogin=NULL,@rmtuser=NULL,@rmtpassword=NULL

GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT1', @optname=N'collation compatible', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT1', @optname=N'data access', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT1', @optname=N'dist', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT1', @optname=N'pub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT1', @optname=N'rpc', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT1', @optname=N'rpc out', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT1', @optname=N'sub', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT1', @optname=N'connect timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT1', @optname=N'collation name', @optvalue=null
GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT1', @optname=N'lazy schema validation', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT1', @optname=N'query timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT1', @optname=N'use remote collation', @optvalue=N'true'


/****** Object:  LinkedServer [WBOREPORT2]    Script Date: 07/09/2007 19:57:37 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'WBOREPORT2', @srvproduct=N'SQL Server'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBOREPORT2',@useself=N'True',@locallogin=NULL,@rmtuser=NULL,@rmtpassword=NULL

GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT2', @optname=N'collation compatible', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT2', @optname=N'data access', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT2', @optname=N'dist', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT2', @optname=N'pub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT2', @optname=N'rpc', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT2', @optname=N'rpc out', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT2', @optname=N'sub', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT2', @optname=N'connect timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT2', @optname=N'collation name', @optvalue=null
GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT2', @optname=N'lazy schema validation', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT2', @optname=N'query timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=N'WBOREPORT2', @optname=N'use remote collation', @optvalue=N'true'




/****** Object:  LinkedServer [WBORISK]    Script Date: 07/09/2007 19:57:47 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'WBORISK', @srvproduct=N'SQL Server'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBORISK',@useself=N'False',@locallogin=NULL,@rmtuser=N'BackOffice',@rmtpassword='########'

GO
EXEC master.dbo.sp_serveroption @server=N'WBORISK', @optname=N'collation compatible', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'WBORISK', @optname=N'data access', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'WBORISK', @optname=N'dist', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'WBORISK', @optname=N'pub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'WBORISK', @optname=N'rpc', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'WBORISK', @optname=N'rpc out', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'WBORISK', @optname=N'sub', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'WBORISK', @optname=N'connect timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=N'WBORISK', @optname=N'collation name', @optvalue=null
GO
EXEC master.dbo.sp_serveroption @server=N'WBORISK', @optname=N'lazy schema validation', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'WBORISK', @optname=N'query timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=N'WBORISK', @optname=N'use remote collation', @optvalue=N'true'



/****** Object:  LinkedServer [XENON]    Script Date: 07/09/2007 19:58:01 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'XENON', @srvproduct=N'SQL Server'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'XENON',@useself=N'False',@locallogin=NULL,@rmtuser=N'BackOffice',@rmtpassword='########'

GO
EXEC master.dbo.sp_serveroption @server=N'XENON', @optname=N'collation compatible', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'XENON', @optname=N'data access', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'XENON', @optname=N'dist', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'XENON', @optname=N'pub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'XENON', @optname=N'rpc', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'XENON', @optname=N'rpc out', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'XENON', @optname=N'sub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'XENON', @optname=N'connect timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=N'XENON', @optname=N'collation name', @optvalue=null
GO
EXEC master.dbo.sp_serveroption @server=N'XENON', @optname=N'lazy schema validation', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'XENON', @optname=N'query timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=N'XENON', @optname=N'use remote collation', @optvalue=N'true'


