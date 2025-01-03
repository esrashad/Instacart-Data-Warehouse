USE InstacartDW;
GO


IF EXISTS (SELECT *
           FROM   sys.tables
           WHERE  NAME = 'dim_user')
  DROP TABLE dim_user;
GO

CREATE TABLE dim_user
(
    user_key INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
	valid_from DATETIME2,                       
    valid_to DATETIME2,                             
    is_current BIT ,
	CONSTRAINT uk_user UNIQUE (user_id,valid_from)
);

IF EXISTS (SELECT * FROM sys.indexes
			WHERE NAME = 'idx_dim_user_user_id'
			AND object_id = OBJECT_ID('dim_user'))
    DROP INDEX idx_dim_user_user_id ON dim_user;
GO

CREATE INDEX idx_dim_user_user_id ON dim_user(user_id);
GO