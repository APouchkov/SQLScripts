exec sp_configure 'show advanced options', 1
reconfigure with override

-- �� ��������� SQL Server �� ��������� �������������������� �������������� �������, ������������ ��������� OPENROWSET � OPENDATASOURCE
--exec sp_configure 'Ad Hoc Distributed Queries', 1
exec sp_configure 'Ad Hoc Distributed Queries', 0

-- ���� �������� ��� ��� ������������ � �������� ��������� sp_configure, ���� � SQL Server ������ ������� ����������. 
-- exec sp_configure 'allow updates', 0

exec sp_configure 'cross db ownership chaining', 0
exec sp_configure 'Database Mail XPs', 1

-- ������� ������� ������ ������� ������-���������� ��� ��������� xp_cmdshell.
exec sp_configure 'xp_cmdshell', 1

--exec sp_configure 'awe enabled', 1
--exec sp_configure 'min server memory (MB)', 1024
--exec sp_configure 'max server memory (MB)', 32768

exec sp_configure 'disallow results from triggers', 0
exec sp_configure 'max degree of parallelism', 1
exec sp_configure 'nested triggers', 1

-- exec sp_configure 'priority boost', 1 -- ��� �� ������������� �������
-- exec sp_configure 'Replication XPs', 1

exec sp_configure 'Replication XPs', 0

exec sp_configure 'server trigger recursion', 1
--exec sp_configure 'SQL Mail XPs', 1

-- ����������� �������� Agent XPs, ����� �������� ����������� �������� ��������� ������ SQL Server �� ���� �������. 
exec sp_configure 'Agent XPs', 1
exec sp_configure 'clr enabled', 1

-- C ������� ��������� Ole Automation Procedures ����� ������� ����������� �������� ����������� �������� OLE-������������� � ������� Transact-SQL. 
exec sp_configure 'Ole Automation Procedures', 1

exec sp_configure N'user options', N'5496'
--exec sp_configure N'user options', N'0'

exec sp_configure 'contained database authentication', 1

reconfigure with override
GO

use master
GO
GRANT VIEW SERVER STATE TO Public
GO

--- User Message 1205 up to 51205
  EXEC sp_addmessage @msgnum = 51205, @severity = 13, @msgtext = N'%s', @replace = 'replace', @lang = 'us_english'
--- User Message 229 up to 50229
  EXEC sp_addmessage @msgnum = 50229, @severity = 13, @msgtext = N'The %s Pseudo permission was denied on the object %s', @replace = 'replace', @lang = 'us_english'
--- User Message 547 up to 50547
  EXEC sp_addmessage @msgnum = 50547, @severity = 13, @msgtext = N'The %s statement conflicted with the %s constraint "%s". The conflict occurred in database "%s", table "%s"%s.', @replace = 'replace', @lang = 'us_english'
  EXEC sp_addmessage @msgnum = 50547, @severity = 13, @msgtext = N'�������� ���������� %s � ������������ %s "%s". �������� ��������� � ���� ������ "%s", ������� "%s"%s.', @replace = 'replace', @lang = 'Russian'
---
  EXEC sp_addmessage @msgnum = 52627, @severity = 14, @msgtext = N'Violation of %s constraint ''%s''. Cannot insert duplicate key in object ''%s''. The duplicate key value is %s.', @replace = 'replace', @lang = 'us_english'
  EXEC sp_addmessage @msgnum = 52627, @severity = 14, @msgtext = N'�������� "%s" ����������� %s. �� ������� �������� ������������� ���� � ������ "%s". ������������� �������� �����: %s.', @replace = 'replace', @lang = 'Russian'

  EXEC sp_addmessage @msgnum = 52601, @severity = 14, @msgtext = N'Cannot insert duplicate key row in object ''%s'' with unique index ''%s''. The duplicate key value is %s.', @replace = 'replace', @lang = 'us_english'
  EXEC sp_addmessage @msgnum = 52601, @severity = 14, @msgtext = N'�� ������� �������� ������������� ������ ����� � ������ "%s" � ���������� �������� "%s". ������������� �������� �����: %s.', @replace = 'replace', @lang = 'Russian'
---
