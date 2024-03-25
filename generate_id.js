#!/usr/bin/env node
const fs = require("fs");
const crypto = require("crypto");

const data = JSON.parse(fs.readFileSync("./combined.json"));

const dataWithIds = data.map((v) => ({ ...v, id: crypto.randomUUID() }));

fs.writeFileSync("./combined.json", JSON.stringify(dataWithIds, null, 4), {
  encoding: "utf-8",
  flag: "w",
});
