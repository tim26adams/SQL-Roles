
/* ===================================== */
/* Step 5: Rollback Script dbuser_monitor */
/* ===================================== */

/* ===================================== */
/* Remove users from role */
/* ===================================== */


DECLARE @UserName NVARCHAR(255) = N'YourUser';
DECLARE @DatabaseName NVARCHAR(255)
	,@SQL NVARCHAR(MAX);

DECLARE db_cursor CURSOR
FOR
SELECT name
FROM sys.databases
WHERE STATE = 0
	AND database_id > 4;

OPEN db_cursor;

FETCH NEXT
FROM db_cursor
INTO @DatabaseName;

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @SQL = N'USE ' + QUOTENAME(@DatabaseName) + N';
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (
            SELECT 1
            FROM sys.database_principals
            WHERE name = ''' + @UserName + N'''
        )
        BEGIN
            ALTER ROLE [dbuser_monitor] DROP MEMBER ' + QUOTENAME(@UserName) + N';
            PRINT ''[ROLLBACK] User removed from: '' + @DatabaseName + '''';
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END
        PRINT ' [ROLLBACK ERROR] User removal failed

	in: ' + @DatabaseName + ' : ' + ERROR_MESSAGE();
    END CATCH;';

	EXEC sp_executesql @SQL;

	FETCH NEXT
	FROM db_cursor
	INTO @DatabaseName;
END;

CLOSE db_cursor;

DEALLOCATE db_cursor;
GO

/* ===================================== */
/* Revoke SHOWPLAN and drop database role */
/* ===================================== */

DECLARE @DatabaseName NVARCHAR(255)
	,@SQL NVARCHAR(MAX);

DECLARE db_cursor CURSOR
FOR
SELECT name
FROM sys.databases
WHERE STATE = 0
	AND database_id > 4;

OPEN db_cursor;

FETCH NEXT
FROM db_cursor
INTO @DatabaseName;

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @SQL = N'USE ' + QUOTENAME(@DatabaseName) + N';
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (
            SELECT 1
            FROM sys.database_principals
            WHERE name = ''dbuser_monitor''
        )
        BEGIN
            REVOKE SHOWPLAN FROM [dbuser_monitor];
            DROP ROLE [dbuser_monitor];
            PRINT ''[ROLLBACK] Role removed from: '' + @DatabaseName + '''';
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END
        PRINT ' [ROLLBACK ERROR] ROLE removal failed

	in: ' + @DatabaseName + ' : ' + ERROR_MESSAGE();
    END CATCH;';

	EXEC sp_executesql @SQL;

	FETCH NEXT
	FROM db_cursor
	INTO @DatabaseName;
END;

CLOSE db_cursor;

DEALLOCATE db_cursor;
GO

/* ===================================== */
/* Drop server role (execute in [master]) */
/* ===================================== */

USE [master];
GO

BEGIN TRY
	BEGIN TRANSACTION;

	IF EXISTS (
			SELECT 1
			FROM sys.server_principals
			WHERE name = 'dbuser_monitor'
			)
	BEGIN
		DROP SERVER ROLE [dbuser_monitor];

		PRINT '[ROLLBACK] Server role [dbuser_monitor] dropped.';
	END

	COMMIT TRANSACTION;
END TRY

BEGIN CATCH
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRANSACTION;
	END

	PRINT '[ROLLBACK ERROR] Server role removal failed: ' + ERROR_MESSAGE();
END CATCH;
GO


