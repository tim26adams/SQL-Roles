/* ======================================================================== */
/*    Step 3: Add Users to the dbuser_monitor Role   */
/* ======================================================================== */

DECLARE @DatabaseName NVARCHAR(255)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @UserName NVARCHAR(255) = 'YourUserName'

DECLARE db_cursor CURSOR FOR
SELECT name 
FROM sys.databases 
WHERE state = 0
  AND name NOT IN ('master', 'tempdb', 'model', 'msdb')

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @DatabaseName

WHILE @@FETCH_STATUS = 0
BEGIN  
    SET @SQL = 'USE [' + @DatabaseName + ']; ALTER ROLE [dbuser_monitor] ADD MEMBER [' + @UserName + '];'
    EXEC sp_executesql @SQL
    PRINT 'User [' + @UserName + '] added to [dbuser_monitor] in database: ' + @DatabaseName
    FETCH NEXT FROM db_cursor INTO @DatabaseName
END  

CLOSE db_cursor  
DEALLOCATE db_cursor
