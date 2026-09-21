#!/usr/bin/env node
const fs = require("fs");

// tell user we're starting
console.log("Formatting combined.json...");

const order = ["Jeopardy", "DoubleJeopardy", "FinalJeopardy"];

// read data
const data = JSON.parse(fs.readFileSync("./combined.json"));

// sort by category, then by value, then by round
data.sort((a, b) => {
  if (a.category !== b.category) {
    return a.category < b.category ? -1 : 1;
  }

  if (a.value !== b.value) {
    return a.value - b.value;
  }

  return order.indexOf(a.round) - order.indexOf(b.round);
});

// number the clues in the order they're written out
const questions = data.map((question, index) => ({ ...question, id: index }));

// write back to outfile
fs.writeFileSync("./combined.json", JSON.stringify(questions, null, 2), {
  encoding: "utf-8",
  flag: "w",
});

// inform user of success
console.log(
  `Successfully formatted ${questions.length.toLocaleString()} questions`
);
