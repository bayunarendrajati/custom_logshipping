USE [logshipped];
GO

CREATE TABLE dbo.PMAG_Databases
(
  DatabaseName               SYSNAME,
  LogBackupFrequency_Minutes SMALLINT NOT NULL DEFAULT (15),
  CONSTRAINT PK_DBS PRIMARY KEY(DatabaseName)
);
GO

CREATE TABLE dbo.PMAG_Secondaries
(
  DatabaseName     SYSNAME,
  ServerInstance   SYSNAME,
  CommonFolder     VARCHAR(512) NOT NULL,
  DataFolder       VARCHAR(512) NOT NULL,
  LogFolder        VARCHAR(512) NOT NULL,
  StandByLocation  VARCHAR(512) NOT NULL,
  IsCurrentStandby BIT NOT NULL DEFAULT 0,
  CONSTRAINT PK_Sec PRIMARY KEY(DatabaseName, ServerInstance),
  CONSTRAINT FK_Sec_DBs FOREIGN KEY(DatabaseName)
    REFERENCES dbo.PMAG_Databases(DatabaseName)
);
GO

CREATE TABLE dbo.PMAG_LogBackupHistory
(
  DatabaseName   SYSNAME,
  ServerInstance SYSNAME,
  BackupSetID    INT NOT NULL,
  Location       VARCHAR(2000) NOT NULL,
  BackupTime     DATETIME NOT NULL DEFAULT SYSDATETIME(),
  CONSTRAINT PK_LBH PRIMARY KEY(DatabaseName, ServerInstance, BackupSetID),
  CONSTRAINT FK_LBH_DBs FOREIGN KEY(DatabaseName)
    REFERENCES dbo.PMAG_Databases(DatabaseName),
  CONSTRAINT FK_LBH_Sec FOREIGN KEY(DatabaseName, ServerInstance)
    REFERENCES dbo.PMAG_Secondaries(DatabaseName, ServerInstance)
);
GO

CREATE TABLE dbo.PMAG_LogRestoreHistory
(
  DatabaseName   SYSNAME,
  ServerInstance SYSNAME,
  BackupSetID    INT,
  RestoreTime    DATETIME,
  CONSTRAINT PK_LRH PRIMARY KEY(DatabaseName, ServerInstance, BackupSetID),
  CONSTRAINT FK_LRH_DBs FOREIGN KEY(DatabaseName)
    REFERENCES dbo.PMAG_Databases(DatabaseName),
  CONSTRAINT FK_LRH_Sec FOREIGN KEY(DatabaseName, ServerInstance)
    REFERENCES dbo.PMAG_Secondaries(DatabaseName, ServerInstance)
);
GO