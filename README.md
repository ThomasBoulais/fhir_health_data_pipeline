# Making a Postgres DB with fake australian FHIR health data

The goal of the project is to create an ETL pipeline from a github repo and store it into a Postgres DataBase ready for analysis.

# FHIR Data

The source is the following github repo https://github.com/hl7au/au-fhir-test-data  
It contains 3 folders, each containing unordered JSONs with names that starts with the type of entity of the file.  

2 scripts have been made to extract the repo and sort the JSONs in subfolders named per entity type.
```bash
bash au_fhir_extract.sh
bash au_fhir_sort_files.sh
```

# Postgres DataBase

In order to store the data in a Postgres DataBase, it first has to be initiated : 

## 1. Installing & Starting PostgreSQL locally

```bash
# Installing postgresql if not already installed
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib

# Starting service
sudo systemctl start postgresql

# Enabling postgresql to start on boot (optional)
sudo systemctl enable postgresql

# Verifying if the service is running
sudo systemctl status postgresql 
```

## 2. Create a DataBase, User, and Schema

```bash
# Run db_setup.sql file while connected as a postgresql user
sudo -u postgres psql -f db_setup.sql
```

## 3. Running the ETL python script

```bash
python load_fhir_to_postgres.py
```

## 5. Verifying loaded data
```bash
# cmd
psql -h localhost -U fhir_user -d fhir_db -c "
SELECT 
    id, 
    fhir_id, 
    first_name, 
    last_name, 
    gender, 
    birth_date 
FROM 
    patients 
LIMIT 5;"

# python
python get_postgres_data.py
```

