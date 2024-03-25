#!/usr/bin/env node
const fs = require("fs");
const crypto = require("crypto");

const order = ["Jeopardy", "DoubleJeopardy", "FinalJeopardy"];

const data = JSON.parse(fs.readFileSync("./combined.json"));

const dataWithIds = data.map((v) => ({
  ...v,
  id: crypto.randomUUID(),
}));

dataWithIds
  .sort((a, b) => order.indexOf(a.round) - order.indexOf(b.round))
  .sort((a, b) => {
    if (a.category === b.category) {
      return 0;
    } else if (a.category < b.category) {
      return -1;
    } else {
      return 1;
    }
  });

fs.writeFileSync("./combined.json", JSON.stringify(dataWithIds, null, 4), {
  encoding: "utf-8",
  flag: "w",
});
