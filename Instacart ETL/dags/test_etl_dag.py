from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
import pandas as pd
import pyodbc

# Define the DAG
default_args = {
    'start_date': datetime(2024, 11, 28),
    'owner': 'airflow',
}

# Define DAG instance
dag = DAG(
    'test',  # DAG ID
    default_args=default_args,  # Default arguments
    schedule_interval=None  # No automatic scheduling
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


