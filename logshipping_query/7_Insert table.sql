USE logshipped;
GO
INSERT dbo.PMAG_Databases(DatabaseName) SELECT N'logshipped';

INSERT dbo.PMAG_Secondaries
(
  DatabaseName,
  ServerInstance, 
  CommonFolder, 
  DataFolder, 
  LogFolder, 
  StandByLocation
)
SELECT 
  DatabaseName = N'logshipped', 
  ServerInstance = name,
  CommonFolder = 'C:\SQL2019SCND\', 
  DataFolder = 'C:\Program Files\Microsoft SQL Server\MSSQL15.NARENDRASCND\MSSQL\DATA\',
  LogFolder  = 'C:\Program Files\Microsoft SQL Server\MSSQL15.NARENDRASCND\MSSQL\DATA\',
  StandByLocation = 'C:\SQL2019SCND\' 
FROM sys.servers 
WHERE name LIKE N'NARENDRA\NARENDRASCND';