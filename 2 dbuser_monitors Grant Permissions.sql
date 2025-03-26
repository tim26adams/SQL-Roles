/* ======================================================================= */
/*  Step 2: Grant Database-Level Permissions to the dbuser_monitor Role    */
/* ======================================================================= */

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
                GRANT SHOWPLAN TO [dbuser_monitor];'  

    EXEC sp_executesql @SQL
    PRINT N'[SUCCESS] GRANT SHOWPLAN in database: ' + QUOTENAME(@DatabaseName) 

    FETCH NEXT FROM db_cursor INTO @DatabaseName
END  

CLOSE db_cursor  
DEALLOCATE db_cursor
GO

/* ======================================================================== */
/*  Step 3: Grant Server-Level Permissions in master  */
/* ======================================================================== */


USE [master];
GO

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'sysadmin_monitor' AND type = 'R')
BEGIN
    --CREATE SERVER ROLE [sysadmin_monitor];
    
    GRANT VIEW SERVER STATE TO [sysadmin_monitor];
    GRANT ALTER ANY CONNECTION TO [sysadmin_monitor];
    
    PRINT 'Server role [sysadmin_monitor] created and permissions granted';
END
ELSE
    PRINT 'Server role [sysadmin_monitor] already exists';
GO