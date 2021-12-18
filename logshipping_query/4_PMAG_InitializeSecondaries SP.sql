CREATE OR ALTER PROCEDURE dbo.PMAG_InitializeSecondaries
  @dbname SYSNAME,
  @fn     VARCHAR(512)
AS
BEGIN
  SET NOCOUNT ON;
 
  -- clear out existing history/settings (since this may be a re-init)
  DELETE dbo.PMAG_LogBackupHistory  WHERE DatabaseName = @dbname;
  DELETE dbo.PMAG_LogRestoreHistory WHERE DatabaseName = @dbname;
  UPDATE dbo.PMAG_Secondaries SET IsCurrentStandby = 0
    WHERE DatabaseName = @dbname;
 
  DECLARE @sql   NVARCHAR(MAX) = N'',
          @files NVARCHAR(MAX) = N'';
 
  -- need to know the logical file names - may be more than two
  SET @sql = N'SELECT @files = (SELECT N'', MOVE N'''''' + name 
    + '''''' TO N''''$'' + CASE [type] WHEN 0 THEN N''df''
      WHEN 1 THEN N''lf'' END + ''$''''''
    FROM ' + QUOTENAME(@dbname) + '.sys.database_files
    WHERE [type] IN (0,1)
    FOR XML PATH, TYPE).value(N''.[1]'',N''nvarchar(max)'');';
 
  EXEC master.sys.sp_executesql @sql,
    N'@files NVARCHAR(MAX) OUTPUT', 
    @files = @files OUTPUT;
 
  SET @sql = N'';
 
  -- restore - need physical paths of data/log files for WITH MOVE
  -- this can fail, obviously, if those path+names already exist for another db
  SELECT @sql += N'EXEC ' + QUOTENAME(ServerInstance) 
    + N'.master.sys.sp_executesql N''RESTORE DATABASE ' + QUOTENAME(@dbname) 
    + N' FROM DISK = N''''' + CommonFolder + @fn + N'''''' + N' WITH REPLACE, 
      NORECOVERY' + REPLACE(REPLACE(REPLACE(@files, N'$df$', DataFolder 
    + @dbname + N'.mdf'), N'$lf$', LogFolder + @dbname + N'.ldf'), N'''', N'''''') 
    + N';'';' + CHAR(13) + CHAR(10)
  FROM dbo.PMAG_Secondaries
  WHERE DatabaseName = @dbname;
 
  EXEC [master].sys.sp_executesql @sql;
 
  -- backup a log for this database
  EXEC dbo.PMAG_Backup @dbname = @dbname, @type = 'trn';
 
  -- restore logs
  EXEC dbo.PMAG_RestoreLogs @dbname = @dbname, @PrepareAll = 1;
END