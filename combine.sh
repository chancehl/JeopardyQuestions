#!/usr/bin/env bash
set -euo pipefail

# tell user we're starting
echo "Combining files..."

# flatten every episode into a flat clue list, tagging each clue with its
# episode id, then drop exact duplicates (same prompt, answer, category and
# value), keeping the earliest airing. Clues that merely share a prompt are
# left alone -- plenty of them are distinct questions.
jq -s '
  [ .[][]
    | .id as $game_id
    | .rounds[].questions[]
    | . + { gameId: $game_id }
  ]
  | group_by([.prompt, .answer, .category, .value])
  | map(min_by(.gameId))
' ./src/*.json > ./combined.json

# tell user we're done
echo "Successfully combined files into ./combined.json"
