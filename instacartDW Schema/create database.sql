USE master;
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'InstacartDW')
BEGIN
    ALTER DATABASE InstacartDW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE InstacartDW;
END
GO

CREATE DATABASE InstacartDW;
GO


