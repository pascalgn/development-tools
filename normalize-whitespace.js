#!/usr/bin/env node

const { readFile, writeFile } = require("fs");
const { argv, stdin } = require("process");

async function main() {
  const args = argv.slice(2);
  if (args[0] === "-h" || args[0] === "--help") {
    console.log("usage: normalize-whitespace [-h] [file...]");
  } else if (args.length === 0) {
    const input = await readStdin();
    const output = normalize(input);
    process.stdout.write(output, "utf8");
  } else {
    for (const arg of args) {
      const input = await readFileAsync(arg);
      const output = normalize(input);
      await writeFileAsync(arg, output);
    }
  }
}

function normalize(str) {
  return (
    str
      .trim()
      .replace(/\r\n/g, "\n")
      .replace(/\n\n+/g, "\n\n")
      .replace(/\t/g, "    ")
      .replace(/ +$/gm, "") + "\n"
  );
}

function readStdin() {
  return new Promise((resolve, reject) => {
    const data = [];
    stdin.setEncoding("utf8");
    stdin.on("data", chunk => data.push(chunk));
    stdin.on("error", err => reject(err));
    stdin.on("end", () => resolve(data.join("")));
  });
}

function readFileAsync(path) {
  return new Promise((resolve, reject) =>
    readFile(path, "utf8", (err, data) => (err ? reject(err) : resolve(data)))
  );
}

function writeFileAsync(path, data) {
  return new Promise((resolve, reject) =>
    writeFile(path, data, err => (err ? reject(err) : resolve()))
  );
}

if (require.main === module) {
  main().catch(err => {
    process.exitCode = 1;
    console.error(err);
  });
}
