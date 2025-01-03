USE InstacartDW;
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'populate_dim_date')
BEGIN
    DROP PROCEDURE populate_dim_date;
END;
GO

CREATE PROCEDURE populate_dim_date
    @start_date DATE = '2021-01-01',
    @end_date DATE = '2024-12-31'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @date_key INT;
    DECLARE @full_date DATE;

    WHILE @start_date <= @end_date
    BEGIN
        SET @date_key = CONVERT(INT, CONVERT(VARCHAR, @start_date, 112));
        SET @full_date = @start_date;

        -- Insert date attributes into dim_date table
        INSERT INTO dim_date (
            date_key,
            full_date,
            day_of_week,
            day_name,
            day_of_month,
            day_of_year,
            week_of_year,
            month_name,
            month_of_year,
            quarter,
            year
        )
        SELECT
            @date_key, -- date_key
            @full_date, -- full_date
            DATEPART(WEEKDAY, @start_date), -- day_of_week
            DATENAME(WEEKDAY, @start_date), -- day_name
            DATEPART(DAY, @start_date), -- day_of_month
            DATEPART(DAYOFYEAR, @start_date), -- day_of_year
            DATEPART(WEEK, @start_date), -- week_of_year
            DATENAME(MONTH, @start_date), -- month_name
            DATEPART(MONTH, @start_date), -- month_of_year
            DATEPART(QUARTER, @start_date), -- quarter
            DATEPART(YEAR, @start_date); -- year

        -- Move to the next day
        SET @start_date = DATEADD(DAY, 1, @start_date);
    END;

    SET NOCOUNT OFF;
END;
GO
