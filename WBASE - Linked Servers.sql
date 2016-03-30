/****** Object:  LinkedServer [DIASOFT5NT]    Script Date: 04/21/2009 20:10:47 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'DIASOFT5NT', @srvproduct=N'SQL Server'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'DIASOFT5NT',@useself=N'False',@locallogin=NULL,@rmtuser=N'BackOffice',@rmtpassword='dsfBackLng548'

GO

EXEC master.dbo.sp_serveroption @server=N'DIASOFT5NT', @optname=N'collation compatible', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'DIASOFT5NT', @optname=N'data access', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'DIASOFT5NT', @optname=N'dist', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'DIASOFT5NT', @optname=N'pub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'DIASOFT5NT', @optname=N'rpc', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'DIASOFT5NT', @optname=N'rpc out', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'DIASOFT5NT', @optname=N'sub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'DIASOFT5NT', @optname=N'connect timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'DIASOFT5NT', @optname=N'collation name', @optvalue=null
GO

EXEC master.dbo.sp_serveroption @server=N'DIASOFT5NT', @optname=N'lazy schema validation', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'DIASOFT5NT', @optname=N'query timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'DIASOFT5NT', @optname=N'use remote collation', @optvalue=N'true'
GO

/****** Object:  LinkedServer [GALAXY]    Script Date: 04/21/2009 20:10:47 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'GALAXY', @srvproduct=N'SQL Server'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'GALAXY',@useself=N'False',@locallogin=NULL,@rmtuser=N'backoffice',@rmtpassword=',srjabc'

GO

EXEC master.dbo.sp_serveroption @server=N'GALAXY', @optname=N'collation compatible', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'GALAXY', @optname=N'data access', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'GALAXY', @optname=N'dist', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'GALAXY', @optname=N'pub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'GALAXY', @optname=N'rpc', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'GALAXY', @optname=N'rpc out', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'GALAXY', @optname=N'sub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'GALAXY', @optname=N'connect timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'GALAXY', @optname=N'collation name', @optvalue=null
GO

EXEC master.dbo.sp_serveroption @server=N'GALAXY', @optname=N'lazy schema validation', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'GALAXY', @optname=N'query timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'GALAXY', @optname=N'use remote collation', @optvalue=N'true'
GO

/****** Object:  LinkedServer [WBOGATE]    Script Date: 04/21/2009 20:10:47 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'WBOGATE', @srvproduct=N'SQL Server'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBOGATE',@useself=N'False',@locallogin=NULL,@rmtuser=N'BackOffice',@rmtpassword=',srjabc'
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBOGATE',@useself=N'False',@locallogin=N'Sys_Gate',@rmtuser=N'Sys_Gate',@rmtpassword='LJHFR7246ssb'
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBOGATE',@useself=N'False',@locallogin=N'Sys_Quik',@rmtuser=N'Sys_Quik',@rmtpassword='JFHd9w4hbF'
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBOGATE',@useself=N'False',@locallogin=N'Sys_Transaq',@rmtuser=N'Sys_Transaq',@rmtpassword='KMFnjh9784'

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
GO

/****** Object:  LinkedServer [WBOREPORT1]    Script Date: 04/21/2009 20:10:48 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'WBOREPORT1', @srvproduct=N'SQL Server'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBOREPORT1',@useself=N'True',@locallogin=NULL,@rmtuser=NULL,@rmtpassword=NULL
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBOREPORT1',@useself=N'False',@locallogin=N'Sys_BackOffice',@rmtuser=N'Sys_BackOffice',@rmtpassword='KhgfvlhbMns684'
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBOREPORT1',@useself=N'False',@locallogin=N'Sys_Repl',@rmtuser=N'Sys_Repl',@rmtpassword='JFHSD73tysba'

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
GO

/****** Object:  LinkedServer [WBOREPORT2]    Script Date: 04/21/2009 20:10:48 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'WBOREPORT2', @srvproduct=N'SQL Server'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBOREPORT2',@useself=N'True',@locallogin=NULL,@rmtuser=NULL,@rmtpassword=NULL
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBOREPORT2',@useself=N'False',@locallogin=N'Sys_BackOffice',@rmtuser=N'Sys_BackOffice',@rmtpassword='KhgfvlhbMns684'
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBOREPORT2',@useself=N'False',@locallogin=N'Sys_Repl',@rmtuser=N'Sys_Repl',@rmtpassword='JFHSD73tysba'

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
GO

/****** Object:  LinkedServer [WBOREPORT3]    Script Date: 04/21/2009 20:10:48 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'WBOREPORT3', @srvproduct=N'SQL Server'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBOREPORT3',@useself=N'True',@locallogin=NULL,@rmtuser=NULL,@rmtpassword=NULL
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBOREPORT3',@useself=N'False',@locallogin=N'Sys_BackOffice',@rmtuser=N'Sys_BackOffice',@rmtpassword='KhgfvlhbMns684'
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBOREPORT3',@useself=N'False',@locallogin=N'Sys_Repl',@rmtuser=N'Sys_Repl',@rmtpassword='JFHSD73tysba'

GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT3', @optname=N'collation compatible', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT3', @optname=N'data access', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT3', @optname=N'dist', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT3', @optname=N'pub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT3', @optname=N'rpc', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT3', @optname=N'rpc out', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT3', @optname=N'sub', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT3', @optname=N'connect timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT3', @optname=N'collation name', @optvalue=null
GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT3', @optname=N'lazy schema validation', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT3', @optname=N'query timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT3', @optname=N'use remote collation', @optvalue=N'true'
GO

/****** Object:  LinkedServer [WBOREPORT4]    Script Date: 04/21/2009 20:10:48 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'WBOREPORT4', @srvproduct=N'SQL Server'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBOREPORT4',@useself=N'True',@locallogin=NULL,@rmtuser=NULL,@rmtpassword=NULL
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBOREPORT4',@useself=N'False',@locallogin=N'Sys_BackOffice',@rmtuser=N'Sys_BackOffice',@rmtpassword='KhgfvlhbMns684'
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBOREPORT4',@useself=N'False',@locallogin=N'Sys_Repl',@rmtuser=N'Sys_Repl',@rmtpassword='JFHSD73tysba'

GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT4', @optname=N'collation compatible', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT4', @optname=N'data access', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT4', @optname=N'dist', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT4', @optname=N'pub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT4', @optname=N'rpc', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT4', @optname=N'rpc out', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT4', @optname=N'sub', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT4', @optname=N'connect timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT4', @optname=N'collation name', @optvalue=null
GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT4', @optname=N'lazy schema validation', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT4', @optname=N'query timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'WBOREPORT4', @optname=N'use remote collation', @optvalue=N'true'
GO

/****** Object:  LinkedServer [WBORISK]    Script Date: 04/21/2009 20:10:48 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'WBORISK', @srvproduct=N'SQL Server'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBORISK',@useself=N'False',@locallogin=NULL,@rmtuser=N'BackOffice',@rmtpassword=',srjabc'
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBORISK',@useself=N'False',@locallogin=N'Sys_Quik',@rmtuser=N'Sys_Quik',@rmtpassword='JFHd9w4hbF'
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBORISK',@useself=N'False',@locallogin=N'Sys_Risk',@rmtuser=N'BackOffice',@rmtpassword=',srjabc'
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WBORISK',@useself=N'False',@locallogin=N'Sys_Transaq',@rmtuser=N'Sys_Transaq',@rmtpassword='KMFnjh9784'

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
GO

/****** Object:  LinkedServer [WTRADE]    Script Date: 04/21/2009 20:10:48 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'WTRADE', @srvproduct=N'SQL Server'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WTRADE',@useself=N'False',@locallogin=NULL,@rmtuser=N'Export',@rmtpassword='123456'

GO

EXEC master.dbo.sp_serveroption @server=N'WTRADE', @optname=N'collation compatible', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WTRADE', @optname=N'data access', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'WTRADE', @optname=N'dist', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WTRADE', @optname=N'pub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WTRADE', @optname=N'rpc', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'WTRADE', @optname=N'rpc out', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'WTRADE', @optname=N'sub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WTRADE', @optname=N'connect timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'WTRADE', @optname=N'collation name', @optvalue=null
GO

EXEC master.dbo.sp_serveroption @server=N'WTRADE', @optname=N'lazy schema validation', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WTRADE', @optname=N'query timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'WTRADE', @optname=N'use remote collation', @optvalue=N'true'
GO

/****** Object:  LinkedServer [WTRADESQL]    Script Date: 04/21/2009 20:10:48 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'WTRADESQL', @srvproduct=N'SQL Server'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WTRADESQL',@useself=N'False',@locallogin=NULL,@rmtuser=N'Export',@rmtpassword='123456'
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WTRADESQL',@useself=N'False',@locallogin=N'Sys_Gate',@rmtuser=N'Export',@rmtpassword='123456'

GO

EXEC master.dbo.sp_serveroption @server=N'WTRADESQL', @optname=N'collation compatible', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WTRADESQL', @optname=N'data access', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'WTRADESQL', @optname=N'dist', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WTRADESQL', @optname=N'pub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WTRADESQL', @optname=N'rpc', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'WTRADESQL', @optname=N'rpc out', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'WTRADESQL', @optname=N'sub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WTRADESQL', @optname=N'connect timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'WTRADESQL', @optname=N'collation name', @optvalue=null
GO

EXEC master.dbo.sp_serveroption @server=N'WTRADESQL', @optname=N'lazy schema validation', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WTRADESQL', @optname=N'query timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'WTRADESQL', @optname=N'use remote collation', @optvalue=N'true'
GO

/****** Object:  LinkedServer [WUGLUSKR]    Script Date: 04/21/2009 20:10:48 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'WUGLUSKR', @srvproduct=N'SQL Server'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'WUGLUSKR',@useself=N'True',@locallogin=NULL,@rmtuser=NULL,@rmtpassword=NULL

GO

EXEC master.dbo.sp_serveroption @server=N'WUGLUSKR', @optname=N'collation compatible', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WUGLUSKR', @optname=N'data access', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WUGLUSKR', @optname=N'dist', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WUGLUSKR', @optname=N'pub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WUGLUSKR', @optname=N'rpc', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'WUGLUSKR', @optname=N'rpc out', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'WUGLUSKR', @optname=N'sub', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'WUGLUSKR', @optname=N'connect timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'WUGLUSKR', @optname=N'collation name', @optvalue=null
GO

EXEC master.dbo.sp_serveroption @server=N'WUGLUSKR', @optname=N'lazy schema validation', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'WUGLUSKR', @optname=N'query timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'WUGLUSKR', @optname=N'use remote collation', @optvalue=N'true'
GO

/****** Object:  LinkedServer [XENIAL2]    Script Date: 04/21/2009 20:10:48 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'XENIAL2', @srvproduct=N'SQL Server'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'XENIAL2',@useself=N'False',@locallogin=NULL,@rmtuser=N'BackOffice',@rmtpassword=',srjabc'

GO

EXEC master.dbo.sp_serveroption @server=N'XENIAL2', @optname=N'collation compatible', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'XENIAL2', @optname=N'data access', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'XENIAL2', @optname=N'dist', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'XENIAL2', @optname=N'pub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'XENIAL2', @optname=N'rpc', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'XENIAL2', @optname=N'rpc out', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'XENIAL2', @optname=N'sub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'XENIAL2', @optname=N'connect timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'XENIAL2', @optname=N'collation name', @optvalue=null
GO

EXEC master.dbo.sp_serveroption @server=N'XENIAL2', @optname=N'lazy schema validation', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'XENIAL2', @optname=N'query timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'XENIAL2', @optname=N'use remote collation', @optvalue=N'true'
GO

