USE InstacartDW;
GO


IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'fk_order_products_orders'
			AND parent_object_id = OBJECT_ID('dbo.dim_order_products'))
BEGIN
    ALTER TABLE dbo.dim_order_products
    DROP CONSTRAINT fk_order_products_orders;
END;
GO

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'fk_order_products_products'
			AND parent_object_id = OBJECT_ID('dbo.dim_order_products'))
BEGIN
    ALTER TABLE dbo.dim_order_products
    DROP CONSTRAINT fk_order_products_products;
END;
GO

IF EXISTS (SELECT * FROM sys.tables WHERE NAME = 'dim_order_products')
    DROP TABLE dim_order_products;
GO


CREATE TABLE dim_order_products (
    order_products_key INT IDENTITY(1,1) PRIMARY KEY,     
    order_key INT NOT NULL ,                               
    product_key INT NOT NULL,                                                           
    add_to_cart_order INT,                               -- Position in which the product was added to the cart
    reordered BIT,  
    valid_from DATETIME2 NOT NULL,                       
    valid_to DATETIME2 NULL,                             
    is_current BIT NOT NULL DEFAULT 1,                                      -- 1 if reordered, 0 if not                 
    
    
    CONSTRAINT fk_order_products_orders FOREIGN KEY (order_key) REFERENCES dim_orders(order_key),
    CONSTRAINT fk_order_products_products FOREIGN KEY (product_key) REFERENCES dim_products(product_key)
);

IF EXISTS (SELECT * FROM sys.indexes WHERE NAME = 'idx_dim_order_products_order_key' AND object_id = OBJECT_ID('dim_order_products'))
    DROP INDEX idx_dim_order_products_order_key ON dim_order_products;
GO

CREATE INDEX idx_dim_order_products_order_key ON dim_order_products(order_key);
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE NAME = 'idx_dim_order_products_product_key' AND object_id = OBJECT_ID('dim_order_products'))
    DROP INDEX idx_dim_order_products_product_key ON dim_order_products;
GO

CREATE INDEX idx_dim_order_products_product_key ON dim_order_products(product_key);
GO

IF EXISTS (SELECT * FROM sys.indexes 
           WHERE NAME = 'idx_dim_order_products_composite' 
           AND object_id = OBJECT_ID('dim_order_products'))
BEGIN
    DROP INDEX idx_dim_order_products_composite ON dim_order_products;
END;
GO

CREATE INDEX idx_dim_order_products_composite ON dim_order_products(order_key, product_key);
GO



