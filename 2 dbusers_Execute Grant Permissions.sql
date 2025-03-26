/* ====================================================================	*/
/*  Step 2: Grant Database-Level Permissions to the dbuser_Execute Role	*/
/* Grant Execute Permissions											*/
/* ==================================================================	*/

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
    SET @SQL = 'USE [' + @DatabaseName + ']; GRANT EXECUTE TO [dbuser_Execute];'
    EXEC sp_executesql @SQL
    PRINT 'EXECUTE permissions granted to [dbuser_Execute] in database: ' + @DatabaseName
    FETCH NEXT FROM db_cursor INTO @DatabaseName
END  

CLOSE db_cursor  
DEALLOCATE db_cursor
