import { existsSync } from "node:fs";
import { styleText } from "node:util";

const manifestFile = "assets.json";

if (!existsSync(manifestFile)) {
  console.log(styleText("red", "Missing " + manifestFile + "!"));
  process.exit(1)
}

const manifest = await Bun.file(manifestFile).json();

for (const key in manifest.images) {
  const path = manifest.images[key];
  console.log(key, path);
}

// await Bun.write("AddAssets.pas", "Hello");

export {}