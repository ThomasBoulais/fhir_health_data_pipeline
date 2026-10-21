#!/bin/bash

set -e

PATIENT_DIR="data/raw/au-fhir-test-data-set/sorted-au-core/Patient"

[ -d "$PATIENT_DIR" ] || { echo "Directory not found: $PATIENT_DIR"; exit 1; }

echo "Exploring FHIR Patient data..."
echo "================================================"

for patient_file in "$PATIENT_DIR"/Patient-*.json; do 
    [ -f "$patient_file" ] || continue

    echo "File: $(basename "$patient_file")"

    jq -r '
        "ID: \(.id)",
        "Gender: \(.gender)",
        "Birth Date: \(.birthDate)",
        "Address: \(.address[0].line[0] // "N/A"), \(.address[0].city // "N/A")",
        "Identifier Type: \(.identifier[0].type.coding[0].code // "N/A")",
        "Identifier Value: \(.identifier[0].value // "N/A")"
    ' "$patient_file"

    jq -r '.identifier[] | select(.type.coding[0].code == "MC") | "Medicare Number: \(.value)" // "NA"' "$patient_file"

    echo "---------"
    break
done

echo "Exploration complete"

