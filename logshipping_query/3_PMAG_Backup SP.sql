CREATE OR ALTER PROCEDURE [dbo].[PMAG_Backup]
  @dbname SYSNAME,
  @type   CHAR(3) = 'bak', -- or 'trn'
  @init   BIT     = 0 -- only used with 'bak'
AS
BEGIN
  SET NOCOUNT ON;
 
  -- generate a filename pattern
  DECLARE @now DATETIME = SYSDATETIME();
  DECLARE @fn NVARCHAR(256) = @dbname + N'_' + CONVERT(CHAR(8), @now, 112) 
    + RIGHT(REPLICATE('0',6) + CONVERT(VARCHAR(32), DATEDIFF(SECOND, 
      CONVERT(DATE, @now), @now)), 6) + N'.' + @type;
 
  -- generate a backup command with MIRROR TO for each distinct CommonFolder
  DECLARE @sql NVARCHAR(MAX) = N'BACKUP' 
    + CASE @type WHEN 'bak' THEN N' DATABASE ' ELSE N' LOG ' END
    + QUOTENAME(@dbname) + ' 
    ' + STUFF(
        (SELECT DISTINCT CHAR(13) + CHAR(10) + N' MIRROR TO DISK = ''' 
           + s.CommonFolder + @fn + ''''
         FROM dbo.PMAG_Secondaries AS s 
         WHERE s.DatabaseName = @dbname 
         FOR XML PATH(''), TYPE).value(N'.[1]',N'nvarchar(max)'),1,9,N'') + N' 
        WITH NAME = N''' + @dbname + CASE @type 
        WHEN 'bak' THEN N'_PMAGFull' ELSE N'_PMAGLog' END 
        + ''', INIT, FORMAT' + CASE WHEN LEFT(CONVERT(NVARCHAR(128), 
        SERVERPROPERTY(N'Edition')), 3) IN (N'Dev', N'Ent')
        THEN N', COMPRESSION;' ELSE N';' END;
 
  EXEC [master].sys.sp_executesql @sql;
 
  IF @type = 'bak' AND @init = 1  -- initialize log shipping
  BEGIN
    EXEC dbo.PMAG_InitializeSecondaries @dbname = @dbname, @fn = @fn;
  END
 
  IF @type = 'trn'
  BEGIN
    -- record the fact that we backed up a log
    INSERT dbo.PMAG_LogBackupHistory
    (
      DatabaseName, 
      ServerInstance, 
      BackupSetID, 
      Location
    )
    SELECT 
      DatabaseName = @dbname, 
      ServerInstance = s.ServerInstance, 
      BackupSetID = MAX(b.backup_set_id), 
      Location = s.CommonFolder + @fn
    FROM msdb.dbo.backupset AS b
    CROSS JOIN dbo.PMAG_Secondaries AS s
    WHERE b.name = @dbname + N'_PMAGLog'
      AND s.DatabaseName = @dbname
    GROUP BY s.ServerInstance, s.CommonFolder + @fn;
 
    -- once we've backed up logs, 
    -- restore them on the next secondary
    EXEC dbo.PMAG_RestoreLogs @dbname = @dbname;
  END
END