USE InstacartDW;
GO


IF EXISTS (SELECT *
           FROM   sys.tables
           WHERE  NAME = 'dim_date')
  DROP TABLE dim_date;

CREATE TABLE dim_date(
    date_key INT PRIMARY KEY,
    full_date DATE,
    day_of_week INT,
    day_name VARCHAR(10),
    day_of_month INT,
    day_of_year INT,
    week_of_year INT,
    month_name VARCHAR(10),
    month_of_year INT,
    quarter INT,
    year INT
);