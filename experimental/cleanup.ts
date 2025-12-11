// Recursively removes all .o and .ppu files

import { Glob } from "bun";
import { unlink } from "node:fs/promises";
import { styleText } from "node:util";

const glob = new Glob("**/*.{o,ppu}");
const files: Array<string> = [];

for await (const file of glob.scan("."))
  files.push(file);

if (files.length == 0)
  console.log(styleText("white", "No .o or .ppu files found"))
else {
  console.log(styleText("yellow", `Found ${files.length} file(s) to delete`));

  for (const file of files)
    console.log(`  ${file}`);

  // Assuming that no files are locked after compilation
  await Promise.all(files.map(file => unlink(file)));
  console.log(styleText("cyan", `Deleted ${files.length} file(s)`))
}
