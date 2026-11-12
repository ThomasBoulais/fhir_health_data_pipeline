-- Create database
CREATE DATABASE fhir_db;

-- Create user
CREATE USER fhir_user WITH PASSWORD 'fhir_db_pass';

-- Connect to fhir_db for the rest of the setup
\c fhir_db

-- Create the schemas used by the two-stage pipeline
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS fhir;

-- Grant privileges on the schemas first
GRANT USAGE, CREATE ON SCHEMA raw TO fhir_user;
GRANT USAGE, CREATE ON SCHEMA fhir TO fhir_user;

-- Set default privileges so future tables and sequences in these schemas are accessible to fhir_user
ALTER DEFAULT PRIVILEGES IN SCHEMA raw GRANT ALL ON TABLES TO fhir_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA raw GRANT ALL ON SEQUENCES TO fhir_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA fhir GRANT ALL ON TABLES TO fhir_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA fhir GRANT ALL ON SEQUENCES TO fhir_user;

-- Create the tables as postgres (which will set ownership correctly going forward)

-- Raw landing layer
CREATE TABLE IF NOT EXISTS raw.resource_load (
    resource_load_id  BIGSERIAL PRIMARY KEY,
    bundle_id         TEXT,
    source_file       TEXT NOT NULL,
    resource_type     TEXT NOT NULL,
    resource_id       TEXT NOT NULL,
    resource_json     JSONB NOT NULL,
    meta_version_id   TEXT,
    meta_last_updated TIMESTAMPTZ,
    checksum_sha256   CHAR(64) NOT NULL,
    loaded_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (resource_type, resource_id, checksum_sha256)
);

-- Typed Patient root
CREATE TABLE IF NOT EXISTS fhir.patient (
    patient_id           TEXT PRIMARY KEY,
    resource_load_id     BIGINT NOT NULL REFERENCES raw.resource_load (resource_load_id),
    active               BOOLEAN,
    gender               TEXT CHECK (gender IN ('male','female','other','unknown')),
    birth_date_raw       TEXT,
    birth_date           DATE,
    birth_date_precision TEXT CHECK (birth_date_precision IN ('year','month','day')),
    meta_version_id      TEXT,
    meta_last_updated    TIMESTAMPTZ,
    loaded_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Child tables
CREATE TABLE IF NOT EXISTS fhir.patient_profile (
    patient_id  TEXT NOT NULL REFERENCES fhir.patient (patient_id) ON DELETE CASCADE,
    position    INT NOT NULL,
    profile_url TEXT NOT NULL,
    PRIMARY KEY (patient_id, position)
);

CREATE TABLE IF NOT EXISTS fhir.patient_name (
    patient_name_id BIGSERIAL PRIMARY KEY,
    patient_id      TEXT NOT NULL REFERENCES fhir.patient (patient_id) ON DELETE CASCADE,
    position        INT NOT NULL,
    use             TEXT,
    text_value      TEXT,
    family          TEXT,
    given           TEXT[],
    prefix          TEXT[],
    suffix          TEXT[],
    UNIQUE (patient_id, position)
);

CREATE TABLE IF NOT EXISTS fhir.patient_telecom (
    patient_telecom_id BIGSERIAL PRIMARY KEY,
    patient_id         TEXT NOT NULL REFERENCES fhir.patient (patient_id) ON DELETE CASCADE,
    position           INT NOT NULL,
    system             TEXT,
    value              TEXT,
    use                TEXT,
    UNIQUE (patient_id, position)
);

CREATE TABLE IF NOT EXISTS fhir.patient_address (
    patient_address_id BIGSERIAL PRIMARY KEY,
    patient_id         TEXT NOT NULL REFERENCES fhir.patient (patient_id) ON DELETE CASCADE,
    position           INT NOT NULL,
    use                TEXT,
    type               TEXT,
    line               TEXT[],
    city               TEXT,
    state              TEXT,
    postal_code        TEXT,
    country            TEXT,
    UNIQUE (patient_id, position)
);

CREATE TABLE IF NOT EXISTS fhir.patient_identifier (
    patient_identifier_id BIGSERIAL PRIMARY KEY,
    patient_id            TEXT NOT NULL REFERENCES fhir.patient (patient_id) ON DELETE CASCADE,
    position              INT NOT NULL,
    system                TEXT,
    value                 TEXT,
    type_code             TEXT,
    type_system           TEXT,
    type_text             TEXT,
    extension_json        JSONB,
    UNIQUE (patient_id, position)
);

CREATE TABLE IF NOT EXISTS fhir.patient_extension (
    patient_extension_id BIGSERIAL PRIMARY KEY,
    patient_id           TEXT NOT NULL REFERENCES fhir.patient (patient_id) ON DELETE CASCADE,
    position             INT NOT NULL,
    url                  TEXT NOT NULL,
    extension_json       JSONB NOT NULL,
    UNIQUE (patient_id, position)
);

-- Indexes
CREATE UNIQUE INDEX IF NOT EXISTS ux_patient_identifier_system_value
    ON fhir.patient_identifier (system, value);
CREATE INDEX IF NOT EXISTS ix_patient_birth_date
    ON fhir.patient (birth_date);
CREATE INDEX IF NOT EXISTS ix_patient_name_family
    ON fhir.patient_name (family);
CREATE INDEX IF NOT EXISTS ix_patient_extension_url
    ON fhir.patient_extension (url);
CREATE INDEX IF NOT EXISTS ix_raw_resource_json
    ON raw.resource_load USING GIN (resource_json);

-- Transfer ownership to fhir_user
ALTER SCHEMA raw OWNER TO fhir_user;
ALTER SCHEMA fhir OWNER TO fhir_user;
ALTER TABLE raw.resource_load OWNER TO fhir_user;
ALTER TABLE fhir.patient OWNER TO fhir_user;
ALTER TABLE fhir.patient_profile OWNER TO fhir_user;
ALTER TABLE fhir.patient_name OWNER TO fhir_user;
ALTER TABLE fhir.patient_telecom OWNER TO fhir_user;
ALTER TABLE fhir.patient_address OWNER TO fhir_user;
ALTER TABLE fhir.patient_identifier OWNER TO fhir_user;
ALTER TABLE fhir.patient_extension OWNER TO fhir_user;

-- Grant explicit privileges on tables
GRANT ALL PRIVILEGES ON raw.resource_load TO fhir_user;
GRANT ALL PRIVILEGES ON fhir.patient, fhir.patient_profile, fhir.patient_name,
    fhir.patient_telecom, fhir.patient_address, fhir.patient_identifier,
    fhir.patient_extension TO fhir_user;

-- Grant sequence usage (BIGSERIAL columns create these sequences)
GRANT USAGE ON SEQUENCE raw.resource_load_resource_load_id_seq TO fhir_user;
GRANT USAGE ON SEQUENCE fhir.patient_name_patient_name_id_seq,
    fhir.patient_telecom_patient_telecom_id_seq,
    fhir.patient_address_patient_address_id_seq,
    fhir.patient_identifier_patient_identifier_id_seq,
    fhir.patient_extension_patient_extension_id_seq TO fhir_user;

-- -- Revoke schema privileges
-- REVOKE ALL PRIVILEGES ON SCHEMA raw FROM fhir_user;
-- REVOKE ALL PRIVILEGES ON SCHEMA fhir FROM fhir_user;

-- -- Revoke default privileges (schema level)
-- ALTER DEFAULT PRIVILEGES FOR USER postgres IN SCHEMA raw REVOKE ALL ON TABLES FROM fhir_user;
-- ALTER DEFAULT PRIVILEGES FOR USER postgres IN SCHEMA raw REVOKE ALL ON SEQUENCES FROM fhir_user;
-- ALTER DEFAULT PRIVILEGES FOR USER postgres IN SCHEMA fhir REVOKE ALL ON TABLES FROM fhir_user;
-- ALTER DEFAULT PRIVILEGES FOR USER postgres IN SCHEMA fhir REVOKE ALL ON SEQUENCES FROM fhir_user;

-- -- Now drop the user
-- DROP USER fhir_user;
