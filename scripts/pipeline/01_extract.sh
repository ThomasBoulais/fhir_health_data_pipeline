#!/bin/bash

set -e

DATA_DIR="data/raw"

if [ -d "$DATA_DIR" ]; then
    rm -rf "$DATA_DIR"
fi

mkdir -p "$DATA_DIR"
cd "$DATA_DIR"

if git clone https://github.com/hl7au/au-fhir-test-data; then # repo simulant des données FHIR australiennes
    echo "Clone successful"
else
    echo "Clone failed"
    exit 1
fi

mv au-fhir-test-data/au-fhir-test-data-set au-fhir-test-data-set
rm -rf au-fhir-test-data
rm -rf au-fhir-test-data-set/au-base

echo "Extract complete: $(pwd)"