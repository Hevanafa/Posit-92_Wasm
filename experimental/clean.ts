import Bun from "bun";

import { readdirSync, rmSync } from "node:fs";
import path from "node:path";
import { styleText } from "node:util";

const TargetExtensions = [
  ".res",
  ".a", ".o", ".ppu",
  ".dbg", ".obj"
];

const TargetDirs = ["backup", "lib"];

function collectFiles(dir: string): Array<string> {
  const result: Array<string> = [];

  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const fullpath = path.join(dir, entry.name);

    if (entry.isDirectory()) {
      if (TargetDirs.includes(entry.name))
        result.push(fullpath)
      else
        result.push(...collectFiles(fullpath));
    } else if (TargetExtensions.includes(path.extname(entry.name)))
      result.push(fullpath);
  }

  return result
}

const files = collectFiles(process.cwd());

if (files.length == 0)
  console.log(styleText("white", "No files needed to be cleaned"))
else {
  console.log(styleText("yellow", `Found ${ files.length } to delete`));

  for (const f of files) {
    console.log("  " + f);
    rmSync(f, { recursive: true })
  }

  console.log(styleText("cyan", `Deleted ${files.length} file(s)`))
}
