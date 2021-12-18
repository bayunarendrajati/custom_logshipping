CREATE OR ALTER PROCEDURE dbo.PMAG_CleanupHistory
  @dbname   SYSNAME,
  @DaysOld  INT = 7
AS
BEGIN
  SET NOCOUNT ON;
 
  DECLARE @cutoff INT;
 
  -- this assumes that a log backup either 
  -- succeeded or failed on all secondaries 
  SELECT @cutoff = MAX(BackupSetID)
    FROM dbo.PMAG_LogBackupHistory AS bh
    WHERE DatabaseName = @dbname
    AND BackupTime < DATEADD(DAY, -@DaysOld, SYSDATETIME())
    AND EXISTS
    (
      SELECT 1 
        FROM dbo.PMAG_LogRestoreHistory AS rh
        WHERE BackupSetID = bh.BackupSetID
          AND DatabaseName = @dbname
          AND ServerInstance = bh.ServerInstance
    );
 
  DELETE dbo.PMAG_LogRestoreHistory
    WHERE DatabaseName = @dbname
    AND BackupSetID <= @cutoff;
 
  DELETE dbo.PMAG_LogBackupHistory 
    WHERE DatabaseName = @dbname
    AND BackupSetID <= @cutoff;
END
GO