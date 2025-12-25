import { readdirSync } from "node:fs";
import { join } from "node:path";
import { styleText } from "node:util";

const scriptDir = import.meta.dir;
const skip: Array<string> = ["webgl_demo"];

const demoFolders = readdirSync(scriptDir, { withFileTypes: true })
  .filter(dir => dir.isDirectory())
  .map(dir => dir.name);

for (const demoName of demoFolders) {
  if (skip.includes(demoName)) {
    console.log(styleText("cyan", `Skipping ${demoName} (special case)`));
    continue
  }

  console.log(styleText("yellow", "Setting up: " + demoName));

  // TODO: Run setup_demo.ts
}
