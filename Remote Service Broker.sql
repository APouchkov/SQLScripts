SET NOCOUNT ON
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

--USE [TestDB]
------------------------------------------------------
-- œ¿–¿Ã≈“–€. Ctrl+Shift+M
------------------------------------------------------
DECLARE
  @DoDrops                  Bit           = 1,
  @DoCreates                Bit           = 1,

  @DBName                   SysName       = N'<DBNAME, sysname, TestDB>',
  @MessageType              SysName       = N'<MessageType, sysname, Text>',
  @—ontractName             SysName       = N'<—ontractName, sysname, Contract>',
  @QueueName                SysName       = N'<QueueName, sysname, QueueName>',
  @ServiceName              SysName       = N'<ServiceName, sysname, ServiceName>',
  @RouteName                SysName       = N'<RouteName, sysname, RouteName>',
  @OtherBrokerInstanceGUID  NVarChar(50)  = N'<OtherBrokerInstanceGUID, SysName, 0CAB8F63-35F8-45C4-8063-3F40147CD1C9>',
                                            -- SELECT [service_broker_guid] FROM <OtherServer, SysName, OtherServer>.master.sys.databases WHERE [database_id] = DB_ID('<OtherDB, SysName, OtherDB>')

  @CertificateUserName      SysName       = N'<UserCertificateName, sysname, ServiceBrokerUser>',
  @Port                     Int           = 4022
DECLARE
  @Address                  NVarChar(512) = N'TCP://<OtherServer, SysName, OtherServer>:' + CAST(@Port AS NVarChar(20)),
  @MasterKeyPassword        NVarChar(32)  = N'Ddf.asg[0985tkjhdvfs',
  @PrivateKeyPassword       NVarChar(32)  = N'VDgmpjpoi43843fb5345',
  @CertificateName          SysName       = N'<EndPointCertificate, SysName, EndPointCertificate>',
  @ExpireDate               Date          = N'<ExpireDate, Date, 20160101>',
  @EndPointName             SysName       = N'<EndPointName, SysName, EndPointName>'

------------------------------------------------------

DECLARE
  @SQL                      NVarChar(Max),
  @FromChars                NVarChar(10)  = N'''',
  @ToChars                  NVarChar(10)  = N''''''

SET @DBName               = QUOTENAME(REPLACE(@DBName, @FromChars, @ToChars))
SET @EndPointName         = REPLACE(@EndPointName, @FromChars, @ToChars)
SET @MessageType          = REPLACE(@MessageType, @FromChars, @ToChars)
SET @—ontractName         = REPLACE(@—ontractName, @FromChars, @ToChars)
SET @QueueName            = REPLACE(@QueueName, @FromChars, @ToChars)
SET @QueueName            = IsNull(QuoteName(PARSENAME(@QueueName, 2)) + '.', '') + QuoteName(PARSENAME(@QueueName, 1))
SET @RouteName            = REPLACE(@RouteName, @FromChars, @ToChars)
SET @CertificateUserName  = REPLACE(@CertificateUserName, @FromChars, @ToChars)

SET @Address              = REPLACE(@Address, @FromChars, @ToChars)
SET @MasterKeyPassword    = REPLACE(@MasterKeyPassword, @FromChars, @ToChars)

------------------------------------------------------
-- <DROPS>
------------------------------------------------------
-- ROUTE
SET @SQL = N'
-- USE ' + @DBName + N'
DROP ROUTE ' + QuoteName(@RouteName) + N'
'
PRINT @SQL
IF    @DoDrops = 1 
  AND EXISTS(SELECT TOP (1) 1 FROM sys.routes WHERE [name] = @RouteName)
  EXEC(@SQL)

-- SERVICE
SET @SQL = '
-- USE ' + @DBName + N'
DROP SERVICE ' + @ServiceName + N'
'
PRINT @SQL
IF    @DoDrops = 1 
  AND EXISTS(SELECT TOP (1) 1 FROM sys.services WHERE [name] = @ServiceName)
  EXEC(@SQL)

-- QUEUE
SET @SQL = N'
-- USE ' + @DBName + N'
DROP QUEUE ' + @QueueName + N'
'
PRINT @SQL
IF    @DoDrops = 1
  AND OBJECT_ID(@QueueName) IS NOT NULL
  --AND EXISTS(SELECT TOP (1) 1 FROM sys.service_queues WHERE [is_ms_shipped] = 0 and [name] = @QueueName)
  EXEC(@SQL)

-- CONTRACT
SET @SQL = N'
-- USE ' + @DBName + N'
DROP CONTRACT ' + QuoteName(@—ontractName) + N'
'
PRINT @SQL
IF    @DoDrops = 1
  AND EXISTS(SELECT TOP (1) 1 FROM sys.service_contracts WHERE [name] = @—ontractName)
  EXEC(@SQL)

-- CERTIFICATE
SET @SQL = N'
DROP CERTIFICATE ' + @CertificateName + N'
'
PRINT @SQL
IF    @DoDrops = 1
  AND EXISTS(SELECT TOP (1) 1 FROM sys.certificates WHERE [name] = @CertificateName)
  EXEC(@SQL)

-- MESSAGE TYPE
SET @SQL = '
-- USE ' + @DBName + N'
DROP MESSAGE TYPE ' + QuoteName(@MessageType) + N'
'
PRINT @SQL
IF    @DoDrops = 1
  AND EXISTS(SELECT TOP (1) 1 FROM sys.service_message_types WHERE [name] = @MessageType)
  EXEC(@SQL)

-- USER
SET @SQL = N'
DROP USER ' + QuoteName(@CertificateUserName) + N'
'
PRINT @SQL
IF    @DoDrops = 1
  AND USER_ID(@CertificateUserName) IS NOT NULL
  EXEC(@SQL)

-- ENDPOINT
SET @SQL = N'
DROP ENDPOINT ' + QuoteName(@EndPointName) + N'
'
PRINT @SQL
IF    @DoDrops = 1
  AND EXISTS(SELECT TOP (1) 1 FROM sys.endpoints WHERE name = @EndPointName)
  EXEC(@SQL)

-- MASTER KEY
SET @SQL = N'
DROP MASTER KEY
-- SELECT * FROM sys.conversation_endpoints WHERE conversation_id = ''00000000-error-conversation-guid-000000000000''
-- END CONVERSATION ''00000000-error-conversation-handle-guid-000000000000'' WITH CLEANUP 
'
PRINT @SQL
IF    @DoDrops = 1
  AND EXISTS(SELECT TOP (1) 1 FROM sys.symmetric_keys WHERE [name] LIKE '%MasterKey%')
  EXEC(@SQL)

------------------------------------------------------
-- </DROPS>
------------------------------------------------------

------------------------------------------------------
-- <CREATES>
------------------------------------------------------
-- MASTER KEY
SET @SQL = N'
CREATE MASTER KEY ENCRYPTION BY PASSWORD = N''' + REPLACE(@MasterKeyPassword, @FromChars, @ToChars) + N''''
PRINT @SQL
IF @DoCreates = 1
  AND NOT EXISTS(SELECT TOP (1) 1 FROM sys.symmetric_keys WHERE [name] LIKE '%MasterKey%')
  EXEC(@SQL)

-- ENDPOINT
SET @SQL = N'
CREATE ENDPOINT ' + QuoteName(@EndPointName) + N'
STATE = STARTED
AS TCP (LISTENER_PORT = ' + CAST(@Port AS NVarChar(20)) + N')
FOR SERVICE_BROKER (AUTHENTICATION = WINDOWS)'
PRINT @SQL
IF @DoCreates = 1
  AND NOT EXISTS(SELECT TOP (1) 1 FROM sys.endpoints WHERE name = @EndPointName)
  EXEC(@SQL)

-- USER
SET @SQL = N'
CREATE USER ' + QuoteName(@CertificateUserName) + N' WITHOUT LOGIN'
PRINT @SQL
IF @DoCreates = 1 AND USER_ID(@CertificateUserName) IS NULL EXEC(@SQL)

-- CERTIFICATE
SET @SQL = N'
CREATE CERTIFICATE ' + QuoteName(@CertificateName) + N'
AUTHORIZATION ' + QuoteName(@CertificateUserName) + N'
WITH SUBJECT = ''Service Broker Certificate'', EXPIRY_DATE = N''' + CONVERT(NVarChar(20), @ExpireDate, 112) + N''''
PRINT @SQL
IF @DoCreates = 1
  AND NOT EXISTS(SELECT TOP (1) 1 FROM sys.certificates WHERE [name] = @CertificateName)
  EXEC(@SQL)

IF @DoCreates = 1
  SELECT
    [BinaryCertificate For Othre Server] = CERTENCODED(CERT_ID(@CertificateName)),
    [BinaryCertificate Private Key For Othre Server] = CERTPRIVATEKEY(CERT_ID(@CertificateName), @PrivateKeyPassword)

-- MESSAGE TYPE
SET @SQL = N'
-- USE ' + @DBName + N'
CREATE MESSAGE TYPE ' + QuoteName(@MessageType) + N' VALIDATION = NONE'
PRINT @SQL
IF @DoCreates = 1
  AND NOT EXISTS(SELECT TOP (1) 1 FROM sys.service_message_types WHERE [name] = @MessageType)
  EXEC(@SQL)

-- CONTRACT
SET @SQL = N'
-- USE ' + @DBName + N'
CREATE CONTRACT ' + QuoteName(@—ontractName) + N'
(' + QuoteName(@MessageType) + N' SENT BY ANY)
--(
--  SenderMessageType     SENT BY INITIATOR,
--  ReceiverMessageType   SENT BY TARGET
--)
'
PRINT @SQL
IF    @DoCreates = 1
  AND NOT EXISTS(SELECT TOP (1) 1 FROM sys.service_contracts WHERE [name] = @—ontractName)
  EXEC(@SQL)

-- QUEUE
SET @SQL = N'
-- USE ' + @DBName + N'
CREATE QUEUE ' + @QueueName + N' WITH STATUS = ON'
PRINT @SQL
IF    @DoCreates = 1
  AND OBJECT_ID(@QueueName) IS NULL
  --AND NOT EXISTS(SELECT TOP (1) 1 FROM sys.service_queues WHERE [is_ms_shipped] = 0 and [name] = @QueueName)
  EXEC(@SQL)

-- SERVICE
SET @SQL = N'
-- USE ' + @DBName + N'
CREATE SERVICE ' + @ServiceName + N'
ON QUEUE ' + @QueueName + N'(' + QuoteName(@—ontractName) + N')'
PRINT @SQL
IF    @DoCreates = 1
  AND NOT EXISTS(SELECT TOP (1) 1 FROM sys.services WHERE [name] = @ServiceName)
  EXEC(@SQL)

-- ROUTE
SET @SQL = N'
-- USE ' + @DBName + N'
CREATE ROUTE ' + QuoteName(@RouteName) + N'
WITH SERVICE_NAME = N''' + REPLACE(@ServiceName, @FromChars, @ToChars) + N''',
ADDRESS = N''' + REPLACE(@Address, @FromChars, @ToChars) + N'''
'
PRINT @SQL
IF @DoCreates = 1
  AND NOT EXISTS(SELECT TOP (1) 1 FROM sys.routes WHERE [name] = @RouteName)
  EXEC(@SQL)

-- TODO: ROUTE ‰Îˇ msdb?

--SET @Cmd = N'USE msdb
--CREATE ROUTE InstTargetRoute
--WITH SERVICE_NAME =
--        N''//TgtDB/2InstSample/TargetService'',
--     ADDRESS = N''LOCAL''';

--EXEC (@Cmd);

------------------------------------------------------
-- </CREATES>
------------------------------------------------------
GO

-- SELECT * FROM sys.conversation_endpoints WHERE conversation_id = 'B9C7FAD6-DE4C-43BC-A553-121880B1EE40'
-- END CONVERSATION 'E93848FE-A2D8-E411-9564-0050569751C6' WITH CLEANUP 
-- SELECT 'END CONVERSATION ''' + Cast(conversation_handle as nvarchar(50)) + ''' WITH CLEANUP ' FROM sys.conversation_endpoints
