#!/usr/bin/env bash
set -euo pipefail

if ! command -v jq > /dev/null; then
    echo "error: jq is required but not installed (try: brew install jq)" >&2
    exit 1
fi

# tell user we're starting
echo "Combining files..."

# flatten every episode into a flat clue list, tagging each clue with its
# episode id, then drop exact duplicates (same prompt, answer, category and
# value), keeping the earliest airing. Clues that merely share a prompt are
# left alone -- plenty of them are distinct questions.
#
# written to a temp file first so a failed run can't leave a half-written
# combined.json in place for format.js to choke on
jq -s '
  [ .[][]
    | .id as $game_id
    | .rounds[].questions[]
    | . + { gameId: $game_id }
  ]
  | group_by([.prompt, .answer, .category, .value])
  | map(min_by(.gameId))
' ./src/*.json > ./combined.json.tmp

mv ./combined.json.tmp ./combined.json

# tell user we're done
echo "Successfully combined files into ./combined.json"
