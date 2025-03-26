--/* ===================================== */
--/* Step 5: Rollback - Remove Permissions */
--/* ===================================== */

DECLARE db_cursor CURSOR FOR
SELECT name 
FROM sys.databases 
WHERE state = 0
  AND name NOT IN ('master', 'tempdb', 'model', 'msdb') -- Exclude system databases

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @DatabaseName

WHILE @@FETCH_STATUS = 0
BEGIN  
    /* Revoke EXECUTE permissions */
    SET @SQL = 'USE [' + @DatabaseName + ']; 
    IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''dbusers_Execute'') 
    BEGIN
        REVOKE EXECUTE TO [dbusers_Execute]; 
        PRINT ''EXECUTE permission revoked from [dbusers_Execute] in database: ' + @DatabaseName + '''; 
    END'
    
    EXEC sp_executesql @SQL
    FETCH NEXT FROM db_cursor INTO @DatabaseName
END  

CLOSE db_cursor  
DEALLOCATE db_cursor


--/* ======================================== */
--/* Step 5.1: Rollback - Remove Users from Role */
--/* ======================================== */

DECLARE db_cursor CURSOR FOR
SELECT name 
FROM sys.databases 
WHERE state = 0
  AND name NOT IN ('master', 'tempdb', 'model', 'msdb') -- Exclude system databases

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @DatabaseName

WHILE @@FETCH_STATUS = 0
BEGIN  
    /* Remove all users from the dbuser_Execute role */
    SET @SQL = 'USE [' + @DatabaseName + ']; 
    DECLARE @UserName NVARCHAR(255)

    DECLARE user_cursor CURSOR FOR 
    SELECT m.name 
    FROM sys.database_principals r
    INNER JOIN sys.database_role_members rm ON r.principal_id = rm.role_principal_id
    INNER JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
    WHERE r.name = ''dbuser_Execute''

    OPEN user_cursor  
    FETCH NEXT FROM user_cursor INTO @UserName

    WHILE @@FETCH_STATUS = 0
    BEGIN  
        EXEC(''ALTER ROLE [dbuser_Execute] DROP MEMBER ['' + @UserName + '']'');
        PRINT ''User ['' + @UserName + ''] removed from [dbuser_Execute] in database: ' + @DatabaseName + '''; 
        FETCH NEXT FROM user_cursor INTO @UserName
    END  

    CLOSE user_cursor  
    DEALLOCATE user_cursor'
    
    EXEC sp_executesql @SQL
    FETCH NEXT FROM db_cursor INTO @DatabaseName
END  

CLOSE db_cursor  
DEALLOCATE db_cursor


/* ======================================== */
/* Step 5.2: Rollback - Drop Role */
/* ======================================== */

DECLARE db_cursor CURSOR FOR
SELECT name 
FROM sys.databases 
WHERE state = 0
  AND name NOT IN ('master', 'tempdb', 'model', 'msdb') -- Exclude system databases

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @DatabaseName

WHILE @@FETCH_STATUS = 0
BEGIN  
    /* Drop the dbuser_Execute role if it exists */
    SET @SQL = 'USE [' + @DatabaseName + ']; 
    IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''dbuser_Execute'') 
    BEGIN
        DROP ROLE [dbuser_Execute];
        PRINT ''Role [dbuser_Execute] dropped in database: ' + @DatabaseName + '''; 
    END'
    
    EXEC sp_executesql @SQL
    FETCH NEXT FROM db_cursor INTO @DatabaseName
-END  

CLOSE db_cursor  
DEALLOCATE db_cursor
