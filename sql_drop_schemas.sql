Declare @DROP_SCHEMA varchar(max)
select @DROP_SCHEMA = isNull(@DROP_SCHEMA + '
', '') + 'DROP SCHEMA [' + name + ']' 
from sys.schemas 
where name not in (
'dbo','guest','INFORMATION_SCHEMA','sys'
,'BackOffice', 'FrontOffice', 'Depositary', 'SpecialDepositary', 'SpecialRegistrator', 'Cash', 'Staff', 'LANG', 'PIF'
, 'ECards', 'Reports', 'Import', 'Export', 'Replication'
)
EXEC(@DROP_SCHEMA)
