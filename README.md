## Making a Postgres DB with Fake Australian FHIR Health Data

## Overview

### Goal
The goal of the project is to do a Data Pipeline on fake Australian FHIR Health Data, extracting from a github repo to a Postgres Database.

The repo has the following structure : 
```
.
├── config
│   ├── data.yaml
│   └── fhir_resources.yaml
├── data
│   ├── processed
│   ├── raw
│   └── schema
├── docs
│   ├── ARCHITECTURE.md
│   ├── SCHEMA.md
│   ├── SETUP.md
│   └── TROUBLESHOOTING.md
├── exploration
│   └── au_fhir_exploration.sh
├── get_postgres_data.py
├── Makefile
├── README.md
├── requirements.txt
├── scripts
│   ├── pipeline
│   │   ├── 01_extract.sh
│   │   ├── 02_sort.sh
│   │   └── 03_load.py
│   └── setup
│       └── db_setup.sql
├── src
│   ├── db_client.py
│   ├── fhir_parser.py
│   ├── __init__.py
│   ├── logger.py
│   ├── utils.py
│   └── validators.py
├── test_api.py
└── tests
    ├── __init__.py
    ├── integration
    │   └── test_pipeline.py
    └── unit
        ├── test_fhir_parser.py
        └── test_validators.py

15 directories, 26 files
```

### Prerequisites & system requirements
The project is using `Python 3.14.4` and `Postgres `

## Quick Start
### First-time setup
After cloning the repo, all the setups commands (virtualenv initialization + requirements + DB setup) can be executed using the `make setup` command : 
```bash
make setup
```


## Detailed Setup
### PostgreSQL installation & configuration
Once all required libraries are installed, run the following command to install and run Postgres service :

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
### Database & User creation
To create the Posgres Database, run the following script : 
```bash
# Run db_setup.sql file while connected as root to create Database & User
sudo -u postgres psql -f db_setup.sql
```
### ETL pipeline execution
The Data Source is a github repo that contains fake Australian FHIR Health Data.  

#### 1. The first step is to get the data from the repo
```bash
bash au_fhir_extract.sh
```

#### 2. Sort the extracted files to improve navigation
The source contains 3 folders, each containing unordered JSONs with names that starts with the type of entity of the file.  
```bash
bash au_fhir_sort_files.sh
```

#### 3. The data can be loaded using the python script
```bash
python load_fhir_to_postgres.py
```
## Verification
### Validation queries
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


### Expected results
\[INSERT RESULTS]
### Data quality checks

## Troubleshooting
### Common errors & solutions
### Connection issues
### Performance tips

## Project Structure
- Explanation of each script
- Data schema overview

## Cleanup & Reset
- How to reset the database
