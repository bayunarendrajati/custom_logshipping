sqlcmd -S NARENDRA\NARENDRASCND -d logshipped -E -Q "EXEC dbo.PMAG_Backup @dbname = N'logshipped', @type = 'trn';"
