import psycopg2
from dotenv import load_dotenv
import os
from pprint import pprint

load_dotenv()

db_config = {
        "host": os.getenv("DB_HOST"),
        "port": int(os.getenv("DB_PORT", 5342)),
        "database": os.getenv("DB_NAME"),
        "user": os.getenv("DB_USER"),
        "password": os.getenv("DB_PASSWORD")
    }

conn = psycopg2.connect(**db_config)
cur = conn.cursor()

cur.execute("""
SELECT id, fhir_id, first_name, last_name, gender, birth_date FROM patients LIMIT 10;
""")

result = cur.fetchall()
pprint(result)

cur.close()
conn.close()