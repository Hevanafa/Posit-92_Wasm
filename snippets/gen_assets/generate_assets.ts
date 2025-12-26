/**
 * Automatically generates AddAssets.pas and add_assets.js
 * based on assets.json
 */

import { existsSync } from "node:fs";
import { styleText } from "node:util";

const manifestFile = "assets.json";
const pascalAssetsFile = "AddAssets.pas";
const jsAssetsFile = "add_assets.js";

if (!existsSync(manifestFile)) {
  console.log(styleText("red", "Missing " + manifestFile + "!"));
  process.exit(1)
}

function capitalise(text) { return text.replace(/^(.)/, (_, g1) => g1.toUpperCase()) }

const manifest = await Bun.file(manifestFile).json();

// Generate AddAssets.pas
const
  pascalVariables = [],
  pascalInterface = [],
  pascalImplementation = [];

for (const key in manifest.images) {
  const pascalCaseKey = capitalise(key)
    .replace(/_(.)/g, (_, g1) => g1.toUpperCase());

  const varname = "img" + pascalCaseKey;
  pascalVariables.push(varname);

  const procedureName = "setImg" + pascalCaseKey;
  pascalInterface.push(
    `procedure ${procedureName}(const imgHandle: longint); ` +
    `public name '${procedureName}';`);
  
  pascalImplementation.push(
`procedure ${procedureName}(const imgHandle: longint);
begin
  ${varname} := imgHandle
end;`
  )
}

// Write everything in one go
await Bun.write(
  pascalAssetsFile,
`
{ Copy this to assets.pas }

interface

var
${pascalVariables.map(item => "  " + item).join(",\r\n")}: longint;

${pascalInterface.join("\r\n")}


implementation

${pascalImplementation.join("\r\n\r\n")}
`);

console.log(styleText("green", "Generated AddAssets.pas"));


// Generate add_assets.js
const jsAssetPairs = Object.entries(manifest.images)
  .map(([key, path]) => `    ${key}: "${path}"`);

await Bun.write(jsAssetsFile,
`
#AssetManifest = {
  images: {
${jsAssetPairs.join(",\r\n")}
  }
}
`);

console.log(styleText("green", "Generated add_assets.js"));

export {}
