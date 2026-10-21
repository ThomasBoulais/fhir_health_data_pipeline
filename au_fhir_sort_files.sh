#!/bin/bash

set -e

cd data/raw/au-fhir-test-data-set

for subfolder in */;do
    subfolder=${subfolder%/} # retire les slash de fin
    echo "Processing: $subfolder"
    
    [ -d "$subfolder" ] || continue # skip les éléments qui ne sont pas des dir
    
    cd "$subfolder"
    
    for filename in *;do
        [ -f "$filename" ] || continue
        
        category=${filename%%-*}
        target_dir="../sorted-$subfolder/$category"

        mkdir -p "$target_dir"
        echo "Moving: $filename => $category" 
        mv -- "$filename" "$target_dir/"
    done

    cd ../
    rm -d "$subfolder" 2>/dev/null || echo "Warning: Could not remove $subfolder"
done

echo "Sort complete"