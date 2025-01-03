USE InstacartDW;
GO

-- Drop existing foreign keys if they exist
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'fk_fact_instacart_product')
    ALTER TABLE fact_instacart DROP CONSTRAINT fk_fact_instacart_product;
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'fk_fact_instacart_user')
    ALTER TABLE fact_instacart DROP CONSTRAINT fk_fact_instacart_user;
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'fk_fact_instacart_date')
    ALTER TABLE fact_instacart DROP CONSTRAINT fk_fact_instacart_date;
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'fk_fact_instacart_department')
    ALTER TABLE fact_instacart DROP CONSTRAINT fk_fact_instacart_department;
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'fk_fact_instacart_aisle')
    ALTER TABLE fact_instacart DROP CONSTRAINT fk_fact_instacart_aisle;
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'fk_fact_instacart_order_product')
    ALTER TABLE fact_instacart DROP CONSTRAINT fk_fact_instacart_order_product;
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'fk_fact_instacart_orders')
    ALTER TABLE fact_instacart DROP CONSTRAINT fk_fact_instacart_orders;

-- Drop the existing table if it exists
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'fact_instacart')
    DROP TABLE fact_instacart;
GO

-- Create the fact table
CREATE TABLE fact_instacart (
    Instacart_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    date_key INT NOT NULL,
    product_key INT NOT NULL,
    user_key INT NOT NULL,
    department_key INT NOT NULL,
    aisle_key INT NOT NULL,
    order_key INT NOT NULL,
    order_products_key INT NOT NULL,        
    product_quantity INT NOT NULL DEFAULT 1,      -- The total quantity of each product ordered                                                           
    total_orders_per_user INT,                    --the total number of orders placed by a specific user
    product_reorder_rate FLOAT, -- The product reorder rate
    
    CONSTRAINT fk_fact_instacart_date 
        FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    CONSTRAINT fk_fact_instacart_product 
        FOREIGN KEY (product_key) REFERENCES dim_products(product_key),
    CONSTRAINT fk_fact_instacart_user 
        FOREIGN KEY (user_key) REFERENCES dim_user(user_key),
    CONSTRAINT fk_fact_instacart_department 
        FOREIGN KEY (department_key) REFERENCES dim_department(department_key),
    CONSTRAINT fk_fact_instacart_aisle 
        FOREIGN KEY (aisle_key) REFERENCES dim_aisle(aisle_key),
    CONSTRAINT fk_fact_instacart_order_product
        FOREIGN KEY (order_products_key) REFERENCES dim_order_products(order_products_key),
    CONSTRAINT fk_fact_instacart_orders
        FOREIGN KEY (order_key) REFERENCES dim_orders(order_key)
);
GO

-- Drop and recreate indexes for the fact_instacart table
IF EXISTS (SELECT * FROM sys.indexes WHERE NAME = 'idx_fact_instacart_date' AND object_id = OBJECT_ID('fact_instacart'))
    DROP INDEX idx_fact_instacart_date ON fact_instacart;
GO

CREATE INDEX idx_fact_instacart_date 
    ON fact_instacart(date_key);
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_fact_instacart_product' AND object_id = OBJECT_ID('fact_instacart'))
    DROP INDEX idx_fact_instacart_product ON fact_instacart;
GO

CREATE INDEX idx_fact_instacart_product 
    ON fact_instacart(product_key);
GO  

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_fact_instacart_user' AND object_id = OBJECT_ID('fact_instacart'))
    DROP INDEX idx_fact_instacart_user ON fact_instacart;
GO

CREATE INDEX idx_fact_instacart_user 
    ON fact_instacart(user_key);
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_fact_instacart_department' AND object_id = OBJECT_ID('fact_instacart'))
    DROP INDEX idx_fact_instacart_department ON fact_instacart;
GO

CREATE INDEX idx_fact_instacart_department 
    ON fact_instacart(department_key);
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_fact_instacart_aisle' AND object_id = OBJECT_ID('fact_instacart'))
    DROP INDEX idx_fact_instacart_aisle ON fact_instacart;
GO

CREATE INDEX idx_fact_instacart_aisle 
    ON fact_instacart(aisle_key);
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_fact_instacart_order_products' AND object_id = OBJECT_ID('fact_instacart'))
    DROP INDEX idx_fact_instacart_order_products ON fact_instacart;
GO

CREATE INDEX idx_fact_instacart_order_products 
    ON fact_instacart(order_products_key);
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_fact_instacart_orders' AND object_id = OBJECT_ID('fact_instacart'))
    DROP INDEX idx_fact_instacart_orders ON fact_instacart;
GO

CREATE INDEX idx_fact_instacart_orders 
    ON fact_instacart(order_key);
GO
