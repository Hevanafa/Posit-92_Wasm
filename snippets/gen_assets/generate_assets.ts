import { existsSync } from "node:fs";
import { styleText } from "node:util";

const manifestFile = "assets.json";

if (!existsSync(manifestFile)) {
  console.log(styleText("red", "Missing " + manifestFile + "!"));
  process.exit(1)
}

function capitalise(text) { return text.replace(/^(.)/, (_, g1) => g1.toUpperCase()) }

const manifest = await Bun.file(manifestFile).json();

const
  pascalVariables = [],
  pascalInterface = [],
  pascalImplementation = [];

for (const key in manifest.images) {
  const path = manifest.images[key];

  const varname = "img" + capitalise(key)
    .replace(/_(.)/g, (_, g1) => g1.toUpperCase());

  pascalVariables.push(varname)
  // console.log(key, path);
}

// TODO: Write everything in one go
await Bun.write(
  "AddAssets.pas",
`
interface

var
${pascalVariables.map(item => "  " + item).join(",\r\n")}: longint;
`);

export {}