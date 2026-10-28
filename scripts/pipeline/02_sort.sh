#!/bin/bash

set -e

mkdir -p data/processed
cd data/raw/au-fhir-test-data-set

for subfolder in */;do
    subfolder=${subfolder%/} # remove ending slash /
    echo "Processing: $subfolder"
    
    [ -d "$subfolder" ] || continue # skip elements taht are not dir
    
    cd "$subfolder"
    
    for filename in *;do
        [ -f "$filename" ] || continue
        
        category=${filename%%-*}
        target_dir="../../../processed/sorted-$subfolder/$category"

        mkdir -p "$target_dir"
        echo "Moving: $filename => $category" 
        mv -- "$filename" "$target_dir/"
    done
done

echo "Sort complete"