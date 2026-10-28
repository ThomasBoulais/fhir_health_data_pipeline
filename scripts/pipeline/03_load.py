import psycopg2
from pathlib import Path
import json
from dotenv import load_dotenv
import os
from pprint import pprint

def load_patients_to_db(data_dir, db_config):
    """
    Load FHIR Patient JSON files into PostgreSQL.
    
    Args:
        data_dir: Path to directory containing Patient JSON files
        db_config: Dictionary with keys: host, port, database, user, password
    """
    conn = psycopg2.connect(**db_config)
    print(db_config)
    cur = conn.cursor()
    
    try:
        for json_file in Path(data_dir).glob("Patient-*.json"):
            with open(json_file) as f:
                patient = json.load(f)
                pprint(patient)

                cur.execute("""
                    INSERT INTO patients (fhir_id, first_name, last_name, gender, birth_date, raw_json)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    ON CONFLICT DO NOTHING;
                """, (
                    patient.get('id'),
                    patient.get('name', [{}])[0].get('given', [''])[0],
                    patient.get('name', [{}])[0].get('family'),
                    patient.get('gender'),
                    patient.get('birthDate'),
                    json.dumps(patient)  # Store raw JSON for reference
                ))

                result = cur.fetchone()
                if result:
                    patient_db_id = result[0]
                    
                    # Insert identifiers
                    for identifier in patient.get('identifier', []):
                        id_type = identifier.get('type', {}).get('coding', [{}])[0].get('code', 'UNKNOWN')
                        id_value = identifier.get('value')
                        
                        cur.execute("""
                            INSERT INTO identifiers (patient_id, identifier_type, identifier_value)
                            VALUES (%s, %s, %s)
                            ON CONFLICT DO NOTHING;
                        """, (patient_db_id, id_type, id_value))
        
        conn.commit()
        print(f"✓ Loaded {len(list(Path(data_dir).glob('Patient-*.json')))} patients")
        
    except Exception as e:
        conn.rollback()
        print(f"✗ Error loading data: {e}")
        raise
    
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    
    load_dotenv()
    
    db_config = {
        "host": os.getenv("DB_HOST"),
        "port": (os.getenv("DB_PORT", 5342)),
        "database": os.getenv("DB_NAME"),
        "user": os.getenv("DB_USER"),
        "password": os.getenv("DB_PASSWORD")
    }
    
    data_dir = "data/processed/sorted-au-core/Patient"
    load_patients_to_db(data_dir, db_config)
