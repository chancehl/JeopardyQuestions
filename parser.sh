#!/usr/bin/env bash

# capture required exes
cat_path=$(which cat)
jq_path=$(which jq)

# look for .json files
json_files=$(find ./src -maxdepth 1 -type f)

# index
index=1

# this does all the heavy lifting
function parse_questions() {
    local file_path=$1
    
    jq 'map(.rounds[].questions[]) | group_by(.prompt) | map(.[0])' "$file_path" >> "./out/questions_$index.json"

    ((index++))
}

# touch out dir
mkdir "./out"

# iterate over files
for i in $json_files; do [ -f "$i" ] && parse_questions $i; done

# tell user we're done
echo "Complete! Check ./out directory"