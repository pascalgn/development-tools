#!/usr/bin/env node

const { readdir, readFile, stat, writeFile } = require("fs");
const { resolve } = require("path");
const { argv } = require("process");

async function main() {
  const args = argv.slice(2);
  if (args[0] === "-h" || args[0] === "--help" || args.length < 2) {
    console.log("usage: mvn-increment-version [-h] <delta> <file>...");
    console.log();
    console.log("Examples:");
    console.log("  mvn-increment-version 0.0.1 .");
    console.log("  mvn-increment-version 1 pom.xml ../pom.xml");
  } else {
    const increment = args[0];

    const files = await Promise.all(
      args.slice(1).map(arg => walk(arg, name => name.endsWith("/pom.xml")))
    ).then(arr => arr.flat());

    for (const file of files) {
      const content = await readFileAsync(file);

      const transformed = transformContent(content, version => {
        const newVersion = incrementVersion(version, increment);
        console.log(file, version, "->", newVersion);
        return newVersion;
      });

      if (transformed !== content) {
        await writeFileAsync(file, transformed);
      }
    }
  }
}

function incrementVersion(version, increment) {
  const incrementArr = increment.split(".");
  const versionArr = version.split(".");
  for (let i = 0; i < incrementArr.length; i++) {
    if (versionArr[i].match(/^\d+$/) && incrementArr[i].match(/^\d+$/)) {
      versionArr[i] = parseInt(versionArr[i]) + parseInt(incrementArr[i]);
    }
  }
  return versionArr.join(".");
}

function transformContent(str, callback) {
  const lines = str.split(/(?=\r?\n)/);
  let level = 0;
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (line.startsWith("<?xml")) {
      continue;
    }
    if (level === 0) {
      lines[i] = line.replace(
        /^(\s*<version>\s*)(.+?)(\s*<\/version>\s*)$/,
        (line, before, version, after) => before + callback(version) + after
      );
    }
    if (line.match(/^\s*<[^\/<>]+>\s*$/)) {
      level += 1;
    } else if (line.match(/^\s*<\/[^\/<>]+>\s*$/)) {
      level -= 1;
    }
  }
  return lines.join("");
}

async function walk(path, filter) {
  const stats = await statAsync(path);
  if (stats.isDirectory()) {
    const entries = await readdirAsync(path);
    return Promise.all(
      entries.map(entry => {
        const p = resolve(path, entry.name);
        return entry.isDirectory() ? walk(p, filter) : [p].filter(filter);
      })
    ).then(arr => arr.flat());
  } else {
    return [resolve(path)].filter(filter);
  }
}

function statAsync(path) {
  return new Promise((resolve, reject) =>
    stat(path, (err, stats) => (err ? reject(err) : resolve(stats)))
  );
}

function readdirAsync(path) {
  return new Promise((resolve, reject) =>
    readdir(path, { withFileTypes: true }, (err, files) =>
      err ? reject(err) : resolve(files)
    )
  );
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
