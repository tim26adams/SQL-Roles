/* ======================================================================== */
/*  Step 1: Create the dbuser_monitor Role                                  */
/* ======================================================================== */

/* Create Database Role */

DECLARE @DatabaseName NVARCHAR(255)
DECLARE @SQL NVARCHAR(MAX)

DECLARE db_cursor CURSOR FOR
/* Return Online databases that are not system dbs*/
SELECT name 
FROM sys.databases 
WHERE state = 0
  AND name NOT IN ('master', 'tempdb', 'model', 'msdb')

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @DatabaseName

WHILE @@FETCH_STATUS = 0
BEGIN  
    SET @SQL = 'USE [' + @DatabaseName + ']; CREATE ROLE [dbuser_monitor];'
    EXEC sp_executesql @SQL
    PRINT 'Role [dbuser_monitor] created in database: ' + @DatabaseName
    FETCH NEXT FROM db_cursor INTO @DatabaseName
END  

CLOSE db_cursor  
DEALLOCATE db_cursor


/* Create Server Role */

BEGIN
   CREATE SERVER ROLE [sysadmin_monitor]
GO;


/*
### SHOWPLAN
The SHOWPLAN permission allows users to view execution plans for queries without actually executing them. This is crucial for query performance analysis. Users with this permission can use:
- SHOWPLAN_XML
- SHOWPLAN_ALL
- SHOWPLAN_TEXT
- STATISTICS XML
- STATISTICS PROFILE

This helps DBAs and developers optimize queries by examining how SQL Server would execute them without affecting production data.

### VIEW SERVER STATE
The VIEW SERVER STATE permission allows users to:
- Access Dynamic Management Views (DMVs) and Dynamic Management Functions (DMFs)
- View server-wide state information
- Monitor SQL Server performance metrics, resource usage, and connection information
- See information about currently executing queries
- Access wait statistics and other performance troubleshooting data

This is essential for monitoring and troubleshooting server performance.

### ALTER ANY CONNECTION
The ALTER ANY CONNECTION permission allows users to:
- Terminate user connections and sessions
- View all connections to the SQL Server instance
- Use the KILL command to end problematic sessions
- Manage user connections for maintenance or troubleshooting

*/