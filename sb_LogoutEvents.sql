--CREATE QUEUE [System].[Logout]
--CREATE SERVICE [System:Logout] ON QUEUE [System].[Logout]([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification])
--GO
CREATE EVENT NOTIFICATION [CIS:Audit:Logout] ON SERVER FOR Audit_Logout TO SERVICE 'System:Logout', 'current database'
DROP EVENT NOTIFICATION [CIS:Audit:Logout] ON SERVER

SELECT * FROM sys.server_event_notifications
