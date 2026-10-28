.PHONY: setup install test run clean help

.ONESHELL:
VENV_DIR=.fhir-pipeline-env
ACTIVATE_VENV:=. $(VENV_DIR)/bin/activate

help:
	@echo "Available commands:"
	@echo "  make setup      - Install deps and initialize database"
	@echo "  make run        - Execute full pipeline"
	@echo "  make test       - Run test suite"
	@echo "  make clean      - Remove generated files"

setup:
	python3 -m venv $(VENV_DIR)
	$(ACTIVATE_VENV) && pip install -r requirements.txt
	sudo -u postgres psql -f scripts/setup/db_setup.sql

run:
	bash scripts/pipeline/01_extract.sh
	bash scripts/pipeline/02_sort.sh
	$(ACTIVATE_VENV) && python3 scripts/pipeline/03_load.py

test:
	pytest tests/ -v

clean:
	rm -rf data/raw/* data/processed/* logs/*
	find . -type d -name __pycache__ -exec rm -rf {} +
	sudo -u postgres psql -c "DROP DATABASE IF EXISTS fhir_db;"	
	sudo -u postgres psql -c "DROP USER IF EXISTS fhir_user;"
