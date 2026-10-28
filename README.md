## Making a Postgres DB with Fake Australian FHIR Health Data

## Overview

### Goal
The goal of the project is to do a Data Pipeline on fake Australian FHIR Health Data, extracting from a github repo to a Postgres Database.

The repo has the following structure : 
```
.
├── au_fhir_exploration.sh
├── au_fhir_extract.sh
├── au_fhir_sort_files.sh
├── db_setup.sql
├── get_postgres_data.py
├── load_fhir_to_postgres.py
├── README.md
└── requirements.txt

1 directory, 8 files
```

### Prerequisites & system requirements
The project is using `Python 3.14.4` and `Postgres `

## Quick Start
### Installation steps
The repo is public and can be cloned using the following command : 
```bash
git clone XXX
```

### First-time setup
After cloning the repo, a virtual environment should be created to limit dependencies breaking with global environment :
```bash
python -m venv fhir-pipeline-env
```
Then the `requirements.txt` should run in order to install required libraries in correct versions : 
```bash
python -m pip install -r requirements.txt
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
