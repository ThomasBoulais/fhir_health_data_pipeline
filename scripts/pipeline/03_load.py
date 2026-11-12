import hashlib
import json
import os
from datetime import date
from pathlib import Path

import psycopg2
from psycopg2.extras import Json
from dotenv import load_dotenv


CHILD_TABLES = [
    "fhir.patient_profile",
    "fhir.patient_name",
    "fhir.patient_telecom",
    "fhir.patient_address",
    "fhir.patient_identifier",
    "fhir.patient_extension",
]

RAW_INSERT = """
INSERT INTO raw.resource_load
    (bundle_id, source_file, resource_type, resource_id, resource_json,
     meta_version_id, meta_last_updated, checksum_sha256)
VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
ON CONFLICT (resource_type, resource_id, checksum_sha256) DO NOTHING
RETURNING resource_load_id;
"""

PATIENT_UPSERT = """
INSERT INTO fhir.patient
    (patient_id, resource_load_id, active, gender,
     birth_date_raw, birth_date, birth_date_precision)
VALUES (%s, %s, %s, %s, %s, %s, %s)
ON CONFLICT (patient_id) DO UPDATE SET
    resource_load_id     = EXCLUDED.resource_load_id,
    active               = EXCLUDED.active,
    gender               = EXCLUDED.gender,
    birth_date_raw       = EXCLUDED.birth_date_raw,
    birth_date           = EXCLUDED.birth_date,
    birth_date_precision = EXCLUDED.birth_date_precision;
"""



def canonical_checksum(resource: dict) -> str:
    """SHA-256 over canonical JSON, identical to the rule used earlier."""
    canonical = json.dumps(resource, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def parse_fhir_date(value):
    """Return (raw, parsed date, precision). Partial dates are padded to the first day."""
    if not value:
        return None, None, None
    if len(value) == 4:
        return value, date(int(value), 1, 1), "year"
    if len(value) == 7:
        year, month = value.split("-")
        return value, date(int(year), int(month), 1), "month"
    return value, date.fromisoformat(value), "day"


def first(items):
    """Return the first element of a list, or an empty dict."""
    return items[0] if items else {}


def rebuild_patient(cur, patient: dict, resource_load_id: int):
    patient_id = patient["id"]
    raw_bd, parsed_bd, precision = parse_fhir_date(patient.get("birthDate"))

    cur.execute(PATIENT_UPSERT, (
        patient_id,
        resource_load_id,
        patient.get("active"),
        patient.get("gender"),
        raw_bd,
        parsed_bd,
        precision,
    ))

    # Replace child rows so a changed resource never leaves stale values behind
    for table in CHILD_TABLES:
        cur.execute(f"DELETE FROM {table} WHERE patient_id = %s;", (patient_id,))

    for pos, profile in enumerate(patient.get("meta", {}).get("profile", [])):
        cur.execute(
            "INSERT INTO fhir.patient_profile (patient_id, position, profile_url) VALUES (%s, %s, %s);",
            (patient_id, pos, profile),
        )

    for pos, name in enumerate(patient.get("name", [])):
        cur.execute("""
            INSERT INTO fhir.patient_name
                (patient_id, position, use, text_value, family, given, prefix, suffix)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s);
        """, (
            patient_id, pos, name.get("use"), name.get("text"), name.get("family"),
            name.get("given"), name.get("prefix"), name.get("suffix"),
        ))

    for pos, telecom in enumerate(patient.get("telecom", [])):
        cur.execute("""
            INSERT INTO fhir.patient_telecom (patient_id, position, system, value, use)
            VALUES (%s, %s, %s, %s, %s);
        """, (patient_id, pos, telecom.get("system"), telecom.get("value"), telecom.get("use")))

    for pos, addr in enumerate(patient.get("address", [])):
        cur.execute("""
            INSERT INTO fhir.patient_address
                (patient_id, position, use, type, line, city, state, postal_code, country)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s);
        """, (
            patient_id, pos, addr.get("use"), addr.get("type"), addr.get("line"),
            addr.get("city"), addr.get("state"), addr.get("postalCode"), addr.get("country"),
        ))

    for pos, ident in enumerate(patient.get("identifier", [])):
        coding = first(ident.get("type", {}).get("coding", []))
        cur.execute("""
            INSERT INTO fhir.patient_identifier
                (patient_id, position, system, value, type_code, type_system, type_text, extension_json)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s);
        """, (
            patient_id, pos, ident.get("system"), ident.get("value"),
            coding.get("code"), coding.get("system"), ident.get("type", {}).get("text"),
            Json(ident["extension"]) if "extension" in ident else None,
        ))

    for pos, ext in enumerate(patient.get("extension", [])):
        cur.execute("""
            INSERT INTO fhir.patient_extension (patient_id, position, url, extension_json)
            VALUES (%s, %s, %s, %s);
        """, (patient_id, pos, ext.get("url"), Json(ext)))


def load_one(cur, path: Path) -> str:
    with open(path, encoding="utf-8") as f:
        resource = json.load(f)

    if resource.get("resourceType") != "Patient":
        raise ValueError(f"{path.name} is not a Patient resource")

    meta = resource.get("meta", {})
    cur.execute(RAW_INSERT, (
        None,                                  # bundle_id: individual files, not bundles
        path.name,
        "Patient",
        resource["id"],
        Json(resource),
        meta.get("versionId"),
        meta.get("lastUpdated"),
        canonical_checksum(resource),
    ))

    row = cur.fetchone()
    if row is None:
        return "skipped"  # identical content already stored in raw

    resource_load_id = row[0]
    rebuild_patient(cur, resource, resource_load_id)
    return "loaded"


def load_patients_to_db(data_dir, db_config):
    files = sorted(Path(data_dir).glob("Patient-*.json"))
    counts = {"loaded": 0, "skipped": 0, "failed": 0}

    conn = psycopg2.connect(**db_config)
    try:
        with conn.cursor() as cur:
            for path in files:
                try:
                    counts[load_one(cur, path)] += 1
                    conn.commit()
                except Exception as e:
                    conn.rollback()
                    counts["failed"] += 1
                    print(f"✗ {path.name}: {e}")
    finally:
        conn.close()

    print(f"✓ Files found:        {len(files)}")
    print(f"✓ Loaded (new/changed): {counts['loaded']}")
    print(f"✓ Skipped (unchanged):  {counts['skipped']}")
    print(f"✗ Failed:             {counts['failed']}")
    return counts


if __name__ == "__main__":
    load_dotenv()

    db_config = {
        "host": os.getenv("DB_HOST"),
        "port": int(os.getenv("DB_PORT", "5432")),
        "database": os.getenv("DB_NAME"),
        "user": os.getenv("DB_USER"),
        "password": os.getenv("DB_PASSWORD"),
    }

    load_patients_to_db("data/processed/sorted-au-core/Patient", db_config)
