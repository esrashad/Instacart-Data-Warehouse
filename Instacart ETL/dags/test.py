import logging
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
import pyodbc

default_args = {
    'owner': 'airflow',
    'start_date': datetime(2023, 1, 1),
}

dag = DAG(
    'dim_date_dag',
    default_args=default_args,
    description='Populate dim_date table',
    schedule_interval=None,
)

def get_pyodbc_cursor():
    connection_string = ('DRIVER={ODBC Driver 18 for SQL Server};'
                         'PORT=1433;'
                         'DATABASE=InstacartDW;'
                         'SERVER=sqlserver;'
                         'UID=sa;' 'PWD=Your_password123;'
                         'TrustServerCertificate=yes;')
    conn = pyodbc.connect(connection_string)
    cursor = conn.cursor()
    cursor.fast_executemany = True
    return conn, cursor

def populate_dim_date():
    conn, cursor = get_pyodbc_cursor()
    cursor.execute("EXEC populate_dim_date @start_date='2021-01-01', @end_date='2023-12-31'")
    conn.commit()
    cursor.close()
    conn.close()

dim_date_task = PythonOperator(
    task_id='generate_dim_date',
    python_callable=populate_dim_date,
    dag=dag,
)

dim_date_task
