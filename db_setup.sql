
-- Create database
CREATE DATABASE fhir_db;

-- Create user 
CREATE USER fhir_user WITH PASSWORD 'fhir_db_pass';

-- Connect to fhir_db for the rest of the setup
\c fhir_db

-- Grant privileges on the schema first
GRANT USAGE, CREATE ON SCHEMA public TO fhir_user;

-- Set default privileges so future tables are owned by fhir_user
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO fhir_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO fhir_user;

-- Create the tables as postgres (which will set ownership correctly going forward)
CREATE TABLE IF NOT EXISTS patients (
    id SERIAL PRIMARY KEY,
    fhir_id VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    gender VARCHAR(50),
    birth_date DATE,
    raw_json JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS identifiers (
    id SERIAL PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    identifier_type VARCHAR(255),
    identifier_value VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transfer ownership to fhir_user
ALTER TABLE patients OWNER TO fhir_user;
ALTER TABLE identifiers OWNER TO fhir_user;

-- Grant explicit privileges
GRANT ALL PRIVILEGES ON patients, identifiers TO fhir_user;
GRANT USAGE ON SEQUENCE patients_id_seq, identifiers_id_seq TO fhir_user;

-- -- Revoke schema privileges
-- REVOKE ALL PRIVILEGES ON SCHEMA public FROM fhir_user;

-- -- Revoke default privileges (schema level)
-- ALTER DEFAULT PRIVILEGES FOR USER postgres IN SCHEMA public REVOKE ALL ON TABLES FROM fhir_user;
-- ALTER DEFAULT PRIVILEGES FOR USER postgres IN SCHEMA public REVOKE ALL ON SEQUENCES FROM fhir_user;

-- -- Now drop the user
-- DROP USER fhir_user;