USE InstacartDW;
GO

IF EXISTS (SELECT * 
           FROM sys.foreign_keys 
           WHERE name = 'fk_product_aisle' 
                 AND parent_object_id = OBJECT_ID('dbo.dim_products'))
BEGIN
    ALTER TABLE dbo.dim_products
    DROP CONSTRAINT fk_product_aisle;
END;
GO

IF EXISTS (SELECT * 
           FROM sys.foreign_keys 
           WHERE name = 'fk_product_department' 
                 AND parent_object_id = OBJECT_ID('dbo.dim_products'))
BEGIN
    ALTER TABLE dbo.dim_products
    DROP CONSTRAINT fk_product_department;
END;
GO


IF OBJECT_ID('dbo.dim_products', 'U') IS NOT NULL
    DROP TABLE dbo.dim_products;
GO


CREATE TABLE dbo.dim_products (
    product_key INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT NOT NULL,
    product_name VARCHAR(200),
    aisle_key INT NOT NULL,
    department_key INT NOT NULL,
    valid_from DATETIME2,
    valid_to DATETIME2,
    is_current BIT DEFAULT 1,
    CONSTRAINT fk_product_aisle FOREIGN KEY (aisle_key) REFERENCES dim_aisle(aisle_key),
    CONSTRAINT fk_product_department FOREIGN KEY (department_key) REFERENCES dim_department(department_key),
    CONSTRAINT uk_product UNIQUE (product_id, valid_from)
);
GO


IF EXISTS (SELECT * FROM sys.indexes
            WHERE NAME = 'idx_dim_department_department_id'
            AND object_id = OBJECT_ID('dim_department'))
    DROP INDEX idx_dim_department_department_id ON dim_department;
GO

CREATE INDEX idx_dim_department_department_id ON dim_department(department_id);
GO
--create index
IF EXISTS (SELECT * FROM sys.indexes
            WHERE NAME = 'idx_dim_products_product_id'
            AND object_id = OBJECT_ID('dim_products'))
    DROP INDEX idx_dim_products_product_id ON dim_products;
GO

CREATE INDEX idx_dim_products_product_id ON dim_products(product_id);
GO

IF EXISTS (SELECT * FROM sys.indexes
            WHERE NAME = 'idx_dim_products_aisle_key'
            AND object_id = OBJECT_ID('dim_products'))
    DROP INDEX idx_dim_products_aisle_key ON dim_products;
GO

CREATE INDEX idx_dim_products_aisle_key ON dim_products(aisle_key);
GO

IF EXISTS (SELECT * FROM sys.indexes
            WHERE NAME = 'idx_dim_products_department_key'
            AND object_id = OBJECT_ID('dim_products'))
    DROP INDEX idx_dim_products_department_key ON dim_products;
GO

CREATE INDEX idx_dim_products_department_key ON dim_products(department_key);
GO
