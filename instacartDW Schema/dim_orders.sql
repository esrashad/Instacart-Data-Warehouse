USE InstacartDW;
GO

-- Drop existing foreign key if exists
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'fk_order_user' AND parent_object_id = OBJECT_ID('dbo.dim_orders'))
BEGIN
    ALTER TABLE dbo.dim_orders DROP CONSTRAINT fk_order_user;
END;
GO

-- Drop the dim_orders table if exists
IF EXISTS (SELECT * FROM sys.tables WHERE NAME = 'dim_orders')
    DROP TABLE dim_orders;
GO

-- Create the dim_orders table
CREATE TABLE dim_orders (
    order_key INT IDENTITY(1,1) PRIMARY KEY,     
    order_id INT NOT NULL,                               
    user_key INT NOT NULL,                                 
    order_number INT,                                                                                               
    order_hour_of_day TINYINT,                           -- Hour of the day the order was placed
    days_since_prior_order INT, 
    order_date DATE,                          -- Days since the prior order                          
    valid_from DATETIME2 NOT NULL,                        
    valid_to DATETIME2 NULL,                              
    is_current BIT NOT NULL DEFAULT 1,                    
    
    CONSTRAINT uk_order_products UNIQUE (order_id, user_key, valid_from),
    CONSTRAINT fk_order_products_user FOREIGN KEY (user_key) REFERENCES dim_user(user_key)  -- Ensure correct FK mapping
);
GO

-- Drop existing indexes and recreate them
IF EXISTS (SELECT * FROM sys.indexes WHERE NAME = 'idx_dim_orders_order_id' AND object_id = OBJECT_ID('dim_orders'))
    DROP INDEX idx_dim_orders_order_id ON dim_orders;
GO

CREATE INDEX idx_dim_orders_order_id ON dim_orders(order_id);
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE NAME = 'idx_dim_orders_user_key' AND object_id = OBJECT_ID('dim_orders'))
    DROP INDEX idx_dim_orders_user_key ON dim_orders;
GO

CREATE INDEX idx_dim_orders_user_key ON dim_orders(user_key);
GO
