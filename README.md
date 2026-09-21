# Jeopardy questions

A dataset of ~564,000 Jeopardy! clues scraped from 9,501 episodes (air dates
September 6, 2004 through September 21, 2026), plus two small scripts that
flatten the per-episode archive into a single question list.

The archive in `src/` is the source of truth and is checked in. The flat clue
list, `combined.json`, is a build artifact — it is gitignored, and you generate
it yourself after cloning.

## Layout

```
src/                    # raw episode archive, chunked by episode number
  episodes_001_500.json
  episodes_501_1000.json
  ...
  episodes_9251_9538.json
  episodes_gaps.json    # backfill for episodes missed in the ranged files
combine.sh              # src/*.json -> combined.json  (flatten + dedupe)
format.js               # combined.json -> combined.json (sort + assign ids)
```

## Requirements

- [`jq`](https://jqlang.github.io/jq/) — recent macOS ships it at `/usr/bin/jq`;
  otherwise `brew install jq` or your package manager. Tested on 1.7.1.
- Node — any modern version. Tested on 24.
- ~400 MB free disk: the clone is ~215 MB (152 MB working tree + 63 MB of git
  history) and the build output adds ~139 MB.

## Building `combined.json`

```sh
git clone https://github.com/chancehl/JeopardyQuestions.git
cd JeopardyQuestions

./combine.sh    # ~6s  — flattens and dedupes
node format.js  # ~1s  — sorts and assigns ids
```

That's the whole process. It's deterministic: the same `src/` always produces a
byte-identical `combined.json`, and re-running either script is a no-op. If
`combine.sh` fails partway it leaves your previous `combined.json` untouched
rather than truncating it.

## Verifying your build

Four checks, each a couple of seconds. Expected output is in the comment.

```sh
jq 'length' combined.json                                   # 563776
jq '[.[].id] == [range(0; length)]' combined.json           # true

jq '[group_by([.prompt,.answer,.category,.value])[]
     | select(length > 1)] | length' combined.json          # 0  (no exact dupes)

jq '["Jeopardy","DoubleJeopardy","FinalJeopardy"] as $o
    | [.[] | .round as $r | [.category, (.value // -1), ($o | index($r))]]
    | . == sort' combined.json                              # true (sort order)
```

## Data format

### Input — `src/episodes_*.json`

Each file is an array of episodes. Every episode has exactly three rounds.

```json
{
  "id": 1,
  "air_date": "Monday, September 6, 2004",
  "rounds": [
    {
      "round": "Jeopardy",
      "questions": [
        {
          "prompt": "Let's all flock to read Psalm 95, in which humans are compared to these animals",
          "category": "THE OLD TESTAMENT",
          "round": "Jeopardy",
          "value": 200,
          "answer": "sheep"
        }
      ]
    }
  ]
}
```

`id` is the episode number. `round` is one of `Jeopardy`, `DoubleJeopardy`, or
`FinalJeopardy`.

### Output — `combined.json`

A flat array of clues, sorted by category, then value, then round. `gameId`
back-references the episode's `id`. `id` is assigned after sorting, so it
matches the clue's position in the array.

```json
{
  "prompt": "Screamer banner denoting a special or additional edition of a newspaper",
  "category": "\"!\"",
  "round": "Jeopardy",
  "value": 200,
  "answer": "Extra!",
  "gameId": 1815,
  "id": 0
}
```

`id` is positional, so it changes whenever episodes are added. Use `gameId` if
you need a reference that survives a rebuild.

## What's in it

| | |
|---|---|
| Episodes | 9,501 |
| Clues | 563,776 |
| — Jeopardy | 278,378 |
| — Double Jeopardy | 275,881 |
| — Final Jeopardy | 9,517 |
| Distinct categories | 59,312 |
| Clue values | 200, 400, 600, 800, 1000, 1200, 1600, 2000, `null` (Final Jeopardy) |

Values are the board values, not wagers — Daily Doubles and Final Jeopardy
carry no wager information.

## Adding episodes

New episodes go into a new chunk file in `src/`, named
`episodes_<start>_<end>.json`. Episodes missing from an already-committed range
go into `src/episodes_gaps.json` instead of being merged back into the ranged
file — that's what the gaps file is for.

Episode `id` is the episode number and must be unique across every file in
`src/`. After adding data, check the archive before rebuilding:

```sh
# count should equal unique
jq -s 'add | [.[].id] | {count: length, unique: (unique | length)}' src/*.json

# every episode needs all three rounds; expect 0
jq -s 'add | map(select((.rounds | length) != 3)) | length' src/*.json
```

Then rebuild, and expect the clue count to go up by roughly 60 per episode
added.

## Known gaps

37 episode numbers in the range 1–9538 have no data:

```
3575, 3576, 4256, 4273, 6223, 6224, 6226, 6227, 6737, 6978, 7463, 8499,
9161, 9165, 9450, 9452, 9505-9514, 9522-9532
```

## Duplicates

`combine.sh` removes clues that match another clue exactly — same prompt,
answer, category and value — keeping the earliest airing. That drops 884 rows
out of 564,660.

It deliberately does *not* dedupe on prompt alone. 3,583 rows in the output
share a prompt with some other row, but 1,426 of those prompt groups have
different correct responses, so collapsing them would destroy real clues:

```
"A Clockwork Orange"
   ep2030 [NAME THE NARRATOR]               -> Alex
   ep4720 [THEY TURNED MY BOOK INTO A MOVIE] -> (Anthony) Burgess
```

## Scope

This repo is the archive plus the flattening scripts. The scraper that produced
`src/` lives elsewhere and is not part of this codebase.
