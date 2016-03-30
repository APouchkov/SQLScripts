-- 1. Создадим юзеров

SELECT 
  'CREATE USER ' + QuoteName(name) 
FROM sys.sysusers 
WHERE name <> 'dbo' AND islogin = 1 AND isntgroup = 0 AND isntuser = 0 AND issqluser = 1 AND hasdbaccess = 1
ORDER BY 1

-- 2.  Создаём схемы

SELECT 
  'CREATE SCHEMA ' + QuoteName(name) + ' AUTHORIZATION ' + QuoteName(USER_NAME(principal_id))
FROM sys.schemas
WHERE name not in ('dbo', 'sys', 'guest', 'INFORMATION_SCHEMA')
ORDER BY 1

-- 2.1 Создаём Пользовательсткие типы и XML-коллекции

-- 3. Создадим роли

SELECT
  'CREATE ROLE ' + QuoteName(U.name) + ' AUTHORIZATION ' + QuoteName(USER_NAME(DP.owning_principal_id))
FROM sys.sysusers U
INNER JOIN sys.database_principals DP ON U.uid = DP.principal_id
WHERE U.issqlrole = 1 AND U.name not in ('public') AND U.name not like 'db_%'
ORDER BY 1

-- 4. Добавим в роли мемберов

SELECT 
  'EXEC sp_AddRoleMember ' + QuoteName(USER_NAME(groupuid)) + ', ' + QuoteName(USER_NAME(memberuid))
FROM sys.sysmembers
WHERE memberuid <> USER_ID('dbo')
ORDER BY 1

-- 5. Перельём таблицы (не забываем про калькулируемые поля)

SELECT
  'SELECT * INTO ' + QuoteName(SCHEMA_NAME(schema_id)) + '.' + QuoteName(name)
  + ' FROM ' + QuoteName(DB_NAME()) + '.' + QuoteName(SCHEMA_NAME(schema_id)) + '.' + QuoteName(name)
  
FROM sys.objects
WHERE type = 'U' AND name not like '=%'
ORDER BY 1

-- 6. Восстановим первичные ключи на таблицах

SELECT
  'ALTER TABLE ' + QuoteName(SCHEMA_NAME(SO.schema_id)) + '.' + QuoteName(SO.name) + ' ADD CONSTRAINT ' + QuoteName(PKC.name) + ' PRIMARY KEY ' + PKC.type_desc COLLATE Cyrillic_General_Bin + ' (' + PKC.[PK] + ') ON [PRIMARY]'
FROM sys.objects SO
CROSS APPLY
(
  SELECT
    I.name,
    type_desc = I.type_desc COLLATE Cyrillic_General_Bin,
    PKC.[PK]
  FROM sys.indexes I (nolock)
  CROSS APPLY
  (
    SELECT
      PK = [Pub].[Trim Right]([Pub].[Trim Right]([Pub].[ConCat](QuoteName(PKC.name) + ', '), ' '), ',')
    FROM
    (
      SELECT TOP 100
        IC.index_column_id, 
        C.name
      FROM sys.index_columns IC (nolock)
      INNER JOIN sys.columns C (nolock) ON C.[object_id] = SO.[object_id] AND IC.[column_id] = C.[column_id]
      WHERE IC.[object_id] = SO.[object_id] AND I.index_id = IC.index_id
      ORDER BY IC.index_column_id
    ) PKC
  ) PKC
  Where I.[object_id] = SO.[object_id] and I.is_primary_key = 1
) PKC
WHERE SO.type = 'U' AND SO.name not like '=%'
AND EXISTS(SELECT TOP 1 1 FROM [BackOffice_NEW].sys.objects SON WHERE SO.name = SON.name)
ORDER BY 1

-- 7. Копируем Вьюхи и индексы на них

-- 8. Копируем Синонимы

-- 9. Перельём скалярные ф-ии схемы [System], [Type] и [Pub]
/*

([System].[Connection_ID]())
([System].[Login Time](NULL))
([System].[Login_Persone_id]())

*/

-- 10. Восстановим прочие ключи, ссылки с помощью интерпрайза а также полномочия на них

-- 11. Копируем скалярные ф-ии

-- 12. Копируем табличные ф-ии

-- 13. Копируем процедуры

-- 14. триггера
