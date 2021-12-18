USE [master];
GO
DECLARE @s NVARCHAR(128) = N'NARENDRA\NARENDRASCND',
        @t NVARCHAR(128) = N'true';
EXEC [master].dbo.sp_addlinkedserver   @server     = @s, @srvproduct = N'SQL Server';
EXEC [master].dbo.sp_addlinkedsrvlogin @rmtsrvname = @s, @useself = @t;
EXEC [master].dbo.sp_serveroption      @server     = @s, @optname = N'collation compatible', @optvalue = @t;
EXEC [master].dbo.sp_serveroption      @server     = @s, @optname = N'data access',          @optvalue = @t;
EXEC [master].dbo.sp_serveroption      @server     = @s, @optname = N'rpc',                  @optvalue = @t;
EXEC [master].dbo.sp_serveroption      @server     = @s, @optname = N'rpc out',              @optvalue = @t;