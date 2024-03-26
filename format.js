#!/usr/bin/env node
const fs = require("fs");

const order = ["Jeopardy", "DoubleJeopardy", "FinalJeopardy"];

// read data
const data = JSON.parse(fs.readFileSync("./combined.json"));

// generate id
let dataWithIds = data.map((v, i) => ({ ...v, id: i }));

// sort by round
dataWithIds.sort((a, b) => order.indexOf(a.round) - order.indexOf(b.round));

// sort by category
dataWithIds.sort((a, b) => {
  if (a.category === b.category) {
    return a.value - b.value;
  } else if (a.category < b.category) {
    return -1;
  } else {
    return 1;
  }
});

// stringify
const newData = JSON.stringify(dataWithIds, null, 2);

// write back to outfile
fs.writeFileSync("./combined.json", newData, { encoding: "utf-8", flag: "w" });

// inform user of success
console.log("[format.js] complete");
