select 'GRANT ' + SP.permission_name + ' TO ' + QuoteName(L.name) COLLATE DATABASE_DEFAULT
from sys.server_permissions SP
INNER JOIN sys.server_principals L ON SP.grantee_principal_id = L.principal_id
                                        AND L.name NOT LIKE '##%'
WHERE SP.permission_name NOT IN ('CONNECT', 'CONNECT SQL') AND SP.grantor_principal_id = 1
