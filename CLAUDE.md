# CLAUDE.md

Guidance for working in this repo. See README.md for the dataset description.

## Never read the data files directly

Every file in `src/` is 4–8 MB of JSON, and `combined.json` is ~129 MB. Reading
one with the Read tool will blow up the context window for no benefit. Use `jq`
instead, always with a projection or aggregation that returns something small:

```sh
jq '.[0] | keys' src/episodes_001_500.json           # schema
jq '[.[].rounds[].questions[]] | length' src/episodes_001_500.json
jq -s 'add | map(.id) | [min, max, length]' src/*.json
jq -r '.[0:3][] | "\(.id)\t\(.air_date)"' src/episodes_gaps.json
```

`jq -s 'add' src/*.json` slurps the entire ~160 MB archive; it works and takes a
few seconds, but pipe it into an aggregation, never into the terminal raw.

## The build pipeline

Two steps, in this order — `format.js` reads `combined.json` and errors out if `combine.sh` has not run:

```sh
./combine.sh    # src/*.json -> ./combined.json
node format.js  # rewrites ./combined.json in place
```

Things about these scripts that are easy to get wrong:

- **`combine.sh` appends (`>>`) to `tmp.questions_N.json`.** It deletes those
  temp files on success, but if a run is interrupted they survive, and the next
  run appends to them — producing silently duplicated clues. Check for and
  remove `tmp.questions_*.json` before re-running after any failure.
- **`combine.sh` globs every file in `src/`,** not just `*.json`
  (`find ./src -maxdepth 1 -type f`). Anything you drop in that directory gets
  fed to `jq` and will fail the run. Keep scratch files elsewhere.
- **Dedupe is per-file, not global.** The `group_by(.prompt) | map(.[0])` step
  runs inside each source file, so repeated prompts across chunks survive into
  `combined.json` (~3,700 of them).
- **`format.js` is not id-stable.** It assigns `id` by array index on each run,
  so running it twice, or rebuilding after adding episodes, renumbers
  everything. `gameId` is the stable reference; `id` is not.
- **`combined.json` is gitignored.** Don't commit it, and don't check it in as
  "regenerated output".

## Adding episodes

New episodes go into a new chunk file in `src/` following the
`episodes_<start>_<end>.json` naming convention. Episodes that were missed
inside an already-committed range go into `src/episodes_gaps.json` instead of
being merged back into the ranged file — that's why the gaps file exists.

Episode `id` is the episode number and must be globally unique across all files
in `src/`. Verify after any data change:

```sh
jq -s 'add | [.[].id] | {count: length, unique: (unique | length)}' src/*.json
jq -s 'add | map(select((.rounds | length) != 3)) | length' src/*.json  # expect 0
```

Then rebuild and confirm the clue count moved in the direction you expect.

## Data conventions

- `round` is exactly `Jeopardy`, `DoubleJeopardy`, or `FinalJeopardy`, and every
  episode has all three, in that order.
- `value` is `null` for Final Jeopardy and a board value otherwise. There are no
  wagers anywhere in the dataset, so Daily Doubles are indistinguishable from
  ordinary clues.
- `prompt` is the clue shown to contestants; `answer` is the correct response,
  stored without the "What is…" phrasing and often with parenthetical
  alternatives (`"(Sean) Combs"`, `"Classic Comics (or Classics Illustrated)"`).
- `category` is upper-case as aired and is not normalized — 59,306 distinct
  values, many differing only by punctuation.

## Scope

This repo is the archive plus the flattening scripts. The scraper that produced
`src/` lives elsewhere and is not part of this codebase.
