# Jeopardy questions

A dataset of ~564,000 Jeopardy! clues scraped from 9,501 episodes (air dates
September 6, 2004 through September 21, 2026), plus two small scripts that
flatten the per-episode archive into a single question list.

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

`combined.json` is a build artifact and is gitignored.

## Building `combined.json`

Requires [`jq`](https://jqlang.github.io/jq/) and Node.

```sh
./combine.sh   # ~6s, flattens and dedupes into ./combined.json
node format.js # ~1s, sorts in place and assigns ids (~139 MB final)
```

A full rebuild is deterministic: the same `src/` always produces a
byte-identical `combined.json`.

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

A flat array of clues. `gameId` back-references the episode's `id`; `id` is a
sequential index assigned by `format.js` after sorting, so it matches the
clue's position in the array.

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

Clues are sorted by category, then value, then round.

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
