# CLAUDE.md

Guidance for working in this repo. See README.md for the dataset description.

## Never read the data files directly

Every file in `src/` is 4–8 MB of JSON, and `combined.json` is ~139 MB. Reading
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

Two steps, in this order — `format.js` reads `combined.json` and errors out if
`combine.sh` has not run:

```sh
./combine.sh    # src/*.json -> ./combined.json   (~6s)
node format.js  # rewrites ./combined.json in place (~1s)
```

Both steps are deterministic and idempotent: rebuilding from an unchanged
`src/` gives a byte-identical file, and re-running `format.js` on its own
output changes nothing. If a change to either script breaks that, it's a bug.

**After any change to either script, run the four checks under "Verifying your
build" in README.md** and paste the results. They cover clue count, id
sequencing, exact duplicates and sort order, and take about 8 seconds total.

Things worth knowing before you change them:

- **The dedupe key is deliberate.** `combine.sh` drops only exact duplicates
  (`[prompt, answer, category, value]`), keeping the lowest `gameId`. Do not
  "simplify" it to dedupe on `prompt` alone: 1,426 duplicate-prompt groups have
  *different* answers (`"A Clockwork Orange"` is `Alex` in NAME THE NARRATOR
  and `(Anthony) Burgess` in THEY TURNED MY BOOK INTO A MOVIE). Prompt-only
  dedupe silently deletes ~3,600 real clues.
- **`format.js` assigns `id` after sorting,** so `id` equals array position.
  It is still derived from position, not from the source data — adding
  episodes renumbers everything. `gameId` is the only stable cross-build
  reference.
- **The sort comparator is explicit** (category, then value, then round). An
  earlier version relied on V8's stable sort to carry the round ordering
  through a second `sort` call; don't reintroduce that.
- **`value` is `null` for Final Jeopardy,** which the comparator handles via
  the `a.value !== b.value` guard before the subtraction. Sorting changes need
  to keep `null` ordering deterministic.
- **`combine.sh` writes through a temp file** and checks for `jq` up front, so
  a failed run leaves the previous `combined.json` intact. Keep that property:
  redirecting straight into `combined.json` means an interrupted build silently
  truncates it and `format.js` then fails on a zero-byte file.
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

Then rebuild and confirm the clue count moved in the direction you expect —
roughly 60 clues per episode added, from a base of 563,776 across the current
9,501 episodes.

## Data conventions

- `round` is exactly `Jeopardy`, `DoubleJeopardy`, or `FinalJeopardy`, and every
  episode has all three, in that order.
- `value` is `null` for Final Jeopardy and a board value otherwise. There are no
  wagers anywhere in the dataset, so Daily Doubles are indistinguishable from
  ordinary clues.
- `prompt` is the clue shown to contestants; `answer` is the correct response,
  stored without the "What is…" phrasing and often with parenthetical
  alternatives (`"(Sean) Combs"`, `"Classic Comics (or Classics Illustrated)"`).
- `category` is upper-case as aired and is not normalized — 59,312 distinct
  values, many differing only by punctuation.

## Scope

This repo is the archive plus the flattening scripts. The scraper that produced
`src/` lives elsewhere and is not part of this codebase.
