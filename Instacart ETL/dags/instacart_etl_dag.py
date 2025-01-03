from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
import pandas as pd
import pyodbc

default_args = {
    'start_date': datetime(2024, 11, 28),
    'owner': 'airflow',
}

dag = DAG(
    'instacart_etl',
    default_args=default_args,  
    schedule_interval=None 
)

def get_pyodbc_cursor():
    connection_string = ( 'DRIVER={ODBC Driver 18 for SQL Server};'
                        'PORT=1433;'
                        'DATABASE=InstacartDW;'
                        'SERVER=sqlserver;'
                        'UID=sa;' 'PWD=Your_password123;'
                        'TrustServerCertificate=yes;')
    conn = pyodbc.connect(connection_string)
    cursor = conn.cursor() 
    cursor.fast_executemany = True 
    return conn, cursor

def lookup_foreign_keys(cursor, fk_mappings):
    fk_map = {}
    for fk_column, (source_fk_column, dimension_table) in fk_mappings.items():
        cursor.execute(f"""
            SELECT {source_fk_column}, {fk_column}
            FROM {dimension_table}
            WHERE is_current = 1
        """)
        for row in cursor.fetchall():
            fk_map[row[0]] = row[1]
    return fk_map

def populate_dim_date():
    conn, cursor = get_pyodbc_cursor()
    cursor.execute("EXEC populate_dim_date @start_date='2021-01-01', @end_date='2023-12-31'")
    conn.commit()
    cursor.close()
    conn.close()


def etl_dim_table(file_path, table_name, id_column, name_column, fk_mappings=None):
    conn, cursor = get_pyodbc_cursor()
    # Extract the data
    df = pd.read_csv(file_path)
    df[name_column] = df[name_column].str.strip()  
    df[name_column] = df[name_column].str.lower() 
    df = df.drop_duplicates(subset=[id_column, name_column])  
    df[name_column] = df[name_column].fillna('Unknown')  
    df = df[df[id_column] > 0] 

    # Map foreign keys if provided
    if fk_mappings:
        fk_map = lookup_foreign_keys(cursor, fk_mappings)
        for fk_column in fk_mappings:
            df[fk_column] = df[fk_mappings[fk_column][0]].map(fk_map).fillna(-1).astype(int)  

    data_to_insert = []
    for _, row in df.iterrows():
        id_value = row[id_column]
        name_value = row[name_column]
        fk_values = {fk: row[fk] for fk in fk_mappings.keys()} if fk_mappings else {}

        # Check if a current record exists
        cursor.execute(f"""
            SELECT {id_column}, {name_column}, is_current
            FROM {table_name}
            WHERE {id_column} = ? AND is_current = 1
        """, (id_value,))
        existing_record = cursor.fetchone()

        if existing_record:
            if name_value != existing_record[1]:
                cursor.execute(f"""
                    UPDATE {table_name}
                    SET valid_to = ?, is_current = 0
                    WHERE {id_column} = ? AND is_current = 1
                """, (datetime.now(), id_value))
                data_to_insert.append((id_value, name_value, *fk_values.values(), datetime.now(), None, 1))
        else:
            # Insert new record
            data_to_insert.append((id_value, name_value, *fk_values.values(), datetime.now(), None, 1))
    columns = [id_column, name_column, *fk_values.keys(), 'valid_from', 'valid_to', 'is_current']
    cursor.executemany(f"""
        INSERT INTO {table_name} ({', '.join(columns)})
        VALUES ({', '.join(['?'] * len(columns))})
    """, data_to_insert)
    conn.commit()
    cursor.close()
    conn.close()
    
def etl_dim_user(file_path, table_name, id_column):
    conn, cursor = get_pyodbc_cursor()
    df = pd.read_csv(file_path)
    df = df.drop_duplicates(subset=[id_column]) 
    df[id_column] = df[id_column].fillna(-1).astype(int) 
    
    data_to_insert=[]
    for _, row in df.iterrows():
        id_value = row[id_column]
        cursor.execute(f"""
            SELECT {id_column}, is_current
            FROM {table_name}
            WHERE {id_column} = ? AND is_current = 1
        """, (id_value,))
        existing_record = cursor.fetchone()
        if existing_record:
            # Update existing record
            cursor.execute(f"""
                UPDATE {table_name}
                SET valid_to = ?, is_current = 0
                WHERE {id_column} = ? AND is_current = 1
            """, (datetime.now(), id_value))
        data_to_insert.append((id_value, datetime.now(), None, 1))
    cursor.executemany(f"""
        INSERT INTO {table_name} (user_id, valid_from, valid_to, is_current)
        VALUES (?, ?, ?, ?)
    """, data_to_insert)
    
    conn.commit()
    cursor.close()
    conn.close()
    
def etl_dim_orders(file_path, table_name, id_column, fk_mappings=None):
    conn, cursor = get_pyodbc_cursor()
    df = pd.read_csv(file_path)
    df = df.drop_duplicates(subset=[id_column])
    df[id_column] = df[id_column].fillna(-1).astype(int)
    df = df.fillna(-1)
    
    base_date = datetime(2021, 1, 1)  # Adjust the base date as needed
    df['cumulative_days'] = df.groupby('user_id')['days_since_prior_order'].cumsum()
    df['order_date'] = base_date + pd.to_timedelta(df['cumulative_days'], unit='D')
    
    if fk_mappings:
        fk_map = lookup_foreign_keys(cursor, fk_mappings)
        for fk_column in fk_mappings:
            df[fk_column] = df[fk_mappings[fk_column][0]].map(fk_map).fillna(-1).astype(int)
    data_to_insert = []
    for _, row in df.iterrows():
        order_id = row['order_id']
        user_key = row['user_key']
        order_number = row['order_number']
        order_hour_of_day = row['order_hour_of_day']
        days_since_prior_order = row['days_since_prior_order']
        order_date = row['order_date']
        
        # Check existing record
        cursor.execute(f"""
            SELECT order_id, is_current
            FROM {table_name}
            WHERE order_id = ? AND is_current = 1
        """, (order_id,))
        existing_record = cursor.fetchone()
        
        if existing_record:
            cursor.execute(f"""
                UPDATE {table_name}
                SET valid_to = ?, is_current = 0
                WHERE order_id = ? AND is_current = 1
            """, (datetime.now(), order_id))
        
        data_to_insert.append((
            order_id, user_key, order_number,
            order_hour_of_day, days_since_prior_order,order_date,
            datetime.now(), None, 1
        ))
    
    batch_size = 500
    for i in range(0, len(data_to_insert), batch_size):
        batch = data_to_insert[i:i + batch_size]
        cursor.executemany(f"""
            INSERT INTO {table_name}
            (order_id, user_key, order_number, order_hour_of_day,
            days_since_prior_order,order_date,valid_from, valid_to, is_current)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?,?)
        """, batch)  
    conn.commit()
    cursor.close()
    conn.close()

def etl_dim_order_products(file_path, table_name, fk_mappings=None):
    conn, cursor = get_pyodbc_cursor()
    
    df = pd.read_csv(file_path)
    df = df.drop_duplicates(subset=['order_id', 'product_id'])
    df = df.fillna(-1).astype(int)
    if fk_mappings:
        fk_map = {}
        for fk_column, (source_fk_column, dimension_table) in fk_mappings.items():
            cursor.execute(f""" 
                SELECT {source_fk_column}, {fk_column}
                FROM {dimension_table}
                WHERE is_current = 1 
            """)
            for row in cursor.fetchall():
                fk_map[row[0]] = row[1]
            df[fk_column] = df[fk_mappings[fk_column][0]].map(fk_map).fillna(-1).astype(int)
    data_to_insert = []
    for _, row in df.iterrows():
        order_key = int(row['order_id'])
        product_key = int(row['product_id'])
        add_to_cart_order = int(row['add_to_cart_order'])
        reordered = int(row['reordered'])
        
        cursor.execute(f""" 
            SELECT order_key, product_key, is_current 
            FROM {table_name}
            WHERE order_key = ? AND product_key = ? AND is_current = 1 
        """, (order_key, product_key))
        existing_record = cursor.fetchone()
        
        if existing_record:
            cursor.execute(f""" 
                UPDATE {table_name} 
                SET valid_to = ?, is_current = 0
                WHERE order_key = ? AND product_key = ? AND is_current = 1 
            """, (datetime.now(), order_key, product_key))
        data_to_insert.append((
            order_key, product_key, add_to_cart_order, 
            reordered, datetime.now(), None, 1
        ))
    batch_size = 500
    for i in range(0, len(data_to_insert), batch_size):
        batch = data_to_insert[i:i + batch_size]
        cursor.executemany(f""" 
            INSERT INTO {table_name}
            (order_key, product_key, add_to_cart_order, reordered,
            valid_from, valid_to, is_current)
            VALUES (?, ?, ?, ?, ?, ?, ?) 
        """, batch)
    conn.commit()
    cursor.close()
    conn.close()

def etl_fact_instacart():
    conn, cursor = get_pyodbc_cursor()
    
    cursor.execute("TRUNCATE TABLE fact_instacart")
    
    cursor.execute("""
        INSERT INTO fact_instacart (
            date_key,
            product_key,
            user_key,
            department_key,
            aisle_key,
            order_key,
            order_products_key,
            product_quantity,
            total_orders_per_user,
            product_reorder_rate
        )
        SELECT 
            d.date_key,
            dp.product_key,
            du.user_key,
            dp.department_key,
            dp.aisle_key,
            do.order_key,
            dop.order_products_key,
            COUNT(*) OVER (PARTITION BY dop.product_key) AS product_quantity,
            COUNT(*) OVER (PARTITION BY do.user_key) AS total_orders_per_user,
            ROUND(CAST(SUM(CASE WHEN dop.reordered = 1 THEN 1 ELSE 0 END) OVER (PARTITION BY dop.product_key) AS FLOAT) / 
            CAST(COUNT(*) OVER (PARTITION BY dop.product_key) AS FLOAT), 2) AS product_reorder_rate
        FROM dim_orders do
        JOIN dim_date d ON CAST(do.order_date AS DATE) = d.full_date
        JOIN dim_user du ON do.user_key = du.user_key
        JOIN dim_order_products dop ON do.order_key = dop.order_key
        JOIN dim_products dp ON dop.product_key = dp.product_key
        WHERE do.is_current = 1
            AND du.is_current = 1
            AND dop.is_current = 1
            AND dp.is_current = 1
    """)
    
    conn.commit()
    cursor.close()
    conn.close()


dim_date_task = PythonOperator(
    task_id = "generate_dim_date",
    python_callable = populate_dim_date,
    dag = dag 
)
dim_department_task = PythonOperator(
    task_id='etl_dim_department',
    python_callable=etl_dim_table,
    op_args=['/opt/airflow/data/departments.csv/departments.csv', 'dim_department', 'department_id', 'department'],
    dag=dag
)

dim_aisle_task = PythonOperator(
    task_id='etl_dim_aisle',
    python_callable=etl_dim_table,
    op_args=['/opt/airflow/data/aisles.csv/aisles.csv', 'dim_aisle', 'aisle_id', 'aisle'],
    dag=dag
)

dim_product_task = PythonOperator(
    task_id='etl_dim_product',
    python_callable=etl_dim_table,
    op_args=['/opt/airflow/data/products.csv/products.csv', 'dim_products', 'product_id', 'product_name',
            {'aisle_key': ('aisle_id', 'dim_aisle'), 'department_key': ('department_id', 'dim_department')}],
    dag=dag
)
dim_user_task = PythonOperator(
    task_id='etl_dim_user',
    python_callable=etl_dim_user,
    op_args=['/opt/airflow/data/orders.csv/orders.csv', 'dim_user', 'user_id'],
    dag=dag
)
dim_orders_task = PythonOperator(
    task_id='etl_dim_orders',
    python_callable=etl_dim_orders,
    op_args=['/opt/airflow/data/orders.csv/orders.csv', 'dim_orders', 'order_id', 
            {'user_key': ('user_id', 'dim_user')}],
    dag=dag
)
dim_order_products_task = PythonOperator(
    task_id='etl_dim_order_products',
    python_callable=etl_dim_order_products,
    op_args=['/opt/airflow/data/order_products.csv/order_products.csv', 'dim_order_products', 
            {'order_key': ('order_id', 'dim_orders'),'product_key': ('product_id', 'dim_products')}],
    dag=dag
)
fact_instacart_task = PythonOperator(
    task_id='etl_fact_instacart',
    python_callable=etl_fact_instacart,
    dag=dag
)

dim_date_task >> [dim_department_task, dim_aisle_task, dim_user_task]
[dim_department_task, dim_aisle_task] >> dim_product_task
dim_user_task >> dim_orders_task
[dim_product_task, dim_orders_task] >> dim_order_products_task
[dim_order_products_task, dim_orders_task, dim_product_task,
dim_user_task, dim_department_task, dim_aisle_task,dim_date_task] >> fact_instacart_task


