CREATE OR ALTER PROCEDURE dbo.PMAG_RestoreLogs
  @dbname     SYSNAME,
  @PrepareAll BIT = 0
AS
BEGIN
  SET NOCOUNT ON;
 
  DECLARE @StandbyInstance SYSNAME,
          @CurrentInstance SYSNAME,
          @BackupSetID     INT, 
          @Location        VARCHAR(512),
          @StandByLocation VARCHAR(512),
          @sql             NVARCHAR(MAX),
          @rn              INT;
 
  -- get the "next" standby instance
  SELECT @StandbyInstance = MIN(ServerInstance)
    FROM dbo.PMAG_Secondaries
    WHERE IsCurrentStandby = 0
      AND ServerInstance > (SELECT ServerInstance
    FROM dbo.PMAG_Secondaries
    WHERE IsCurrentStandBy = 1);
 
  IF @StandbyInstance IS NULL -- either it was last or a re-init
  BEGIN
    SELECT @StandbyInstance = MIN(ServerInstance)
      FROM dbo.PMAG_Secondaries;
  END
 
  -- get that instance up and into STANDBY
  -- for each log in logbackuphistory not in logrestorehistory:
  -- restore, and insert it into logrestorehistory
  -- mark the last one as STANDBY
  -- if @prepareAll is true, mark all others as NORECOVERY
  -- in this case there should be only one, but just in case
 
  DECLARE c CURSOR LOCAL FAST_FORWARD FOR 
    SELECT bh.BackupSetID, s.ServerInstance, bh.Location, s.StandbyLocation,
      rn = ROW_NUMBER() OVER (PARTITION BY s.ServerInstance ORDER BY bh.BackupSetID DESC)
    FROM dbo.PMAG_LogBackupHistory AS bh
    INNER JOIN dbo.PMAG_Secondaries AS s
    ON bh.DatabaseName = s.DatabaseName
    AND bh.ServerInstance = s.ServerInstance
    WHERE s.DatabaseName = @dbname
    AND s.ServerInstance = CASE @PrepareAll 
	WHEN 1 THEN s.ServerInstance ELSE @StandbyInstance END
    AND NOT EXISTS
    (
      SELECT 1 FROM dbo.PMAG_LogRestoreHistory AS rh
        WHERE DatabaseName = @dbname
        AND ServerInstance = s.ServerInstance
        AND BackupSetID = bh.BackupSetID
    )
    ORDER BY CASE s.ServerInstance 
      WHEN @StandbyInstance THEN 1 ELSE 2 END, bh.BackupSetID;
 
  OPEN c;
 
  FETCH c INTO @BackupSetID, @CurrentInstance, @Location, @StandbyLocation, @rn;
 
  WHILE @@FETCH_STATUS != -1
  BEGIN
    -- kick users out - set to single_user then back to multi
    SET @sql = N'EXEC ' + QUOTENAME(@CurrentInstance) + N'.[master].sys.sp_executesql '
    + 'N''IF EXISTS (SELECT 1 FROM sys.databases WHERE name = N''''' 
	+ @dbname + ''''' AND [state]  1)
	  BEGIN
	    ALTER DATABASE ' + QUOTENAME(@dbname) + N' SET SINGLE_USER '
      +   N'WITH ROLLBACK IMMEDIATE;
	    ALTER DATABASE ' + QUOTENAME(@dbname) + N' SET MULTI_USER;
	  END;'';';
 
    EXEC [master].sys.sp_executesql @sql;
 
    -- restore the log (in STANDBY if it's the last one):
    SET @sql = N'EXEC ' + QUOTENAME(@CurrentInstance) 
      + N'.[master].sys.sp_executesql ' + N'N''RESTORE LOG ' + QUOTENAME(@dbname) 
      + N' FROM DISK = N''''' + @Location + N''''' WITH ' + CASE WHEN @rn = 1 
        AND (@CurrentInstance = @StandbyInstance OR @PrepareAll = 1) THEN 
        N'STANDBY = N''''' + @StandbyLocation + @dbname + N'.standby''''' ELSE 
        N'NORECOVERY' END + N';'';';
 
    EXEC [master].sys.sp_executesql @sql;
 
    -- record the fact that we've restored logs
    INSERT dbo.PMAG_LogRestoreHistory
      (DatabaseName, ServerInstance, BackupSetID, RestoreTime)
    SELECT @dbname, @CurrentInstance, @BackupSetID, SYSDATETIME();
 
    -- mark the new standby
    IF @rn = 1 AND @CurrentInstance = @StandbyInstance -- this is the new STANDBY
    BEGIN
        UPDATE dbo.PMAG_Secondaries 
          SET IsCurrentStandby = CASE ServerInstance
            WHEN @StandbyInstance THEN 1 ELSE 0 END 
          WHERE DatabaseName = @dbname;
    END
 
    FETCH c INTO @BackupSetID, @CurrentInstance, @Location, @StandbyLocation, @rn;
  END
 
  CLOSE c; DEALLOCATE c;
END