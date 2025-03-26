/* ======================================================================== */
/*  Step 1: Create the dbuser_Execute Role                                  */
/*  DB Role                                             */
/* ======================================================================== */


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
    SET @SQL = 'USE [' + @DatabaseName + ']; CREATE ROLE [dbuser_Execute];'
    EXEC sp_executesql @SQL
    PRINT 'Role [dbuser_Execute] created in database: ' + @DatabaseName
    FETCH NEXT FROM db_cursor INTO @DatabaseName
END  

CLOSE db_cursor  
DEALLOCATE db_cursor
