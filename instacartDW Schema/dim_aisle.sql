USE InstacartDW;
GO

IF EXISTS (SELECT * FROM sys.tables WHERE NAME = 'dim_aisle')
    DROP TABLE dim_aisle;
GO

CREATE TABLE dim_aisle
(
    aisle_key INT IDENTITY(1,1) PRIMARY KEY,
    aisle_id INT NOT NULL,
    aisle VARCHAR(100),
    valid_from DATETIME2,
    valid_to DATETIME2,
    is_current BIT DEFAULT 1,
    CONSTRAINT uk_aisle UNIQUE (aisle_id, valid_from)
);
GO


IF EXISTS (SELECT * FROM sys.indexes
			WHERE NAME = 'idx_dim_aisle_aisle_id'
			AND object_id = OBJECT_ID('dim_aisle'))
    DROP INDEX idx_dim_aisle_aisle_id ON dim_aisle;
GO

CREATE INDEX idx_dim_aisle_aisle_id ON dim_aisle(aisle_id);
GO
