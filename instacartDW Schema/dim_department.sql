USE InstacartDW;
GO


IF EXISTS (SELECT *
           FROM   sys.tables
           WHERE  NAME = 'dim_department')
  DROP TABLE dim_department;
GO


CREATE TABLE dim_department
(
    department_key INT IDENTITY(1,1) PRIMARY KEY,
    department_id INT NOT NULL,
    department VARCHAR(50),
    valid_from DATETIME2,
    valid_to DATETIME2,
    is_current BIT,
    CONSTRAINT uk_department UNIQUE (department_id, valid_from)
);

IF EXISTS (SELECT * FROM sys.indexes
			WHERE NAME = 'idx_dim_department_department_id'
			AND object_id = OBJECT_ID('dim_department'))
    DROP INDEX idx_dim_department_department_id ON dim_department;
GO

CREATE INDEX idx_dim_department_department_id ON dim_department(department_id);
GO