/* ======================================================================== */
/* Step 1: Verification Script dbuser_monitor */
/* ======================================================================== */

/* Verify User by database within the dbuser_monitor role */

DECLARE @DatabaseName NVARCHAR(255)
DECLARE @SQL NVARCHAR(MAX)

DECLARE db_cursor CURSOR FOR
SELECT name 
FROM sys.databases 
WHERE state = 0
  AND name NOT IN ('master', 'tempdb', 'model', 'msdb') -- Exclude system databases

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @DatabaseName

WHILE @@FETCH_STATUS = 0
BEGIN  
    /* Check if the sp_Monitor role exists */
    SET @SQL = 'USE [' + @DatabaseName + '];
    SELECT DB_NAME() AS DatabaseName, r.name AS RoleName, m.name AS MemberName 
    FROM sys.database_principals r
    LEFT JOIN sys.database_role_members rm ON r.principal_id = rm.role_principal_id
    LEFT JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
    WHERE r.name = ''dbuser_monitor'';'
    
    PRINT 'Verifying [dbuser_monitor] role in database: ' + @DatabaseName
    EXEC sp_executesql @SQL

    FETCH NEXT FROM db_cursor INTO @DatabaseName
END  

CLOSE db_cursor  
DEALLOCATE db_cursor


/* ======================================================================== */
/* Step 2: Verify Server-Level Permissions sysadmin_monitor */
/* ======================================================================== */

/* Check sysadmin_monitor role exists */

SELECT name, type_desc, create_date
FROM sys.server_principals
WHERE name = 'sysadmin_monitor';


/* Check sysadmin_monitor Role Created */

PRINT 'Checking server-level permissions for [sp_Monitor] in master database...'

USE master;
SELECT dp.name AS PrincipalName, dpe.permission_name
FROM sys.server_permissions dpe
JOIN sys.server_principals dp ON dpe.grantee_principal_id = dp.principal_id
WHERE dp.name = 'sysadmin_monitor';


/* ======================================================================== */
/* -- Check membership of the sysadmin_monitor role */
/* ======================================================================== */

/* Verify  Users membership of sysadmin_monitor role */

SELECT 
    rm.role_principal_id,
    role_name = r.name,
    rm.member_principal_id,
    member_name = m.name
FROM sys.server_role_members rm
JOIN sys.server_principals r ON rm.role_principal_id = r.principal_id
JOIN sys.server_principals m ON rm.member_principal_id = m.principal_id
WHERE r.name = 'sysadmin_monitor';

/* ======================================================================== */
/* -- Check  permissions granted sysadmin_monitor role */
/* ======================================================================== */



SELECT 
    sp.name AS RoleName,
    sp.type_desc AS RoleType,
    spe.permission_name,
    spe.state_desc
FROM sys.server_principals AS sp
JOIN sys.server_permissions AS spe 
ON sp.principal_id = spe.grantee_principal_id
WHERE sp.name = 'sysadmin_monitor'
ORDER BY spe.permission_name;




/* ======================================================================== */
/* -- Check SHOWPLAN has been GRANTED  */
/* ======================================================================== */

/* Verfiy User membership of SHOWPLAN */

DECLARE @DatabaseName NVARCHAR(255)
DECLARE @SQL NVARCHAR(MAX)
DECLARE db_cursor CURSOR FOR
SELECT name 
FROM sys.databases 
WHERE state = 0
  AND name NOT IN ('master', 'tempdb', 'model', 'msdb')

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @DatabaseName

WHILE @@FETCH_STATUS = 0
BEGIN  
    SET @SQL = N'USE ' + QUOTENAME(@DatabaseName) + N';
                SELECT 
                    DB_NAME() AS DatabaseName,
                    prin.name AS UserName,
                    perm.permission_name,
                    perm.state_desc
                FROM sys.database_permissions perm
                JOIN sys.database_principals prin ON perm.grantee_principal_id = prin.principal_id
                WHERE prin.name = ''dbuser_monitor''
                AND perm.permission_name = ''SHOWPLAN'';'
    
    EXEC sp_executesql @SQL
    
    FETCH NEXT FROM db_cursor INTO @DatabaseName
END  

CLOSE db_cursor  
DEALLOCATE db_cursor
