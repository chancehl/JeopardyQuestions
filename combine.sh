#!/usr/bin/env bash
set -euo pipefail

# tell user we're starting
echo "Combining files..."

# look for .json files
json_files=$(find ./src -maxdepth 1 -type f)

# index
index=1

# this does all the heavy lifting
function parse_questions() {
    echo "Processing file $index: $1"

    local file_path=$1
    
    jq 'map({gameId: .id, questions: .rounds[].questions[]}) | map(.questions.gameId = .gameId) | map(.questions) | group_by(.prompt) | map(.[0])' "$file_path" >> "./tmp.questions_$index.json"

    ((index++))
}

# generate tmp files
for i in $json_files; do [ -f "$i" ] && parse_questions "$i"; done

# combine the question files
jq -s 'add' tmp.questions*.json > combined.json

# cleanup
rm -rf ./tmp.questions*.json

# tell user we're done
echo "Successfully combined files into ./combined.json"