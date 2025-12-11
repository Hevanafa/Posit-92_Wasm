// Setup Boilerplate
// By Hevanafa, 12-12-2025
// Part of Posit-92 framework

// This script should be executed before copying as a new demo

import { mkdir } from "node:fs/promises";
import { existsSync } from "node:fs";

const source = "..";
if (!existsSync("UNITS"))
  await mkdir("UNITS");

await Bun.$`cp ${source}/UNITS/*.pas ./UNITS/`;
await Bun.$`cp ${source}/scripts/*.ts ./`;
await Bun.$`cp ${source}/posit-92.js ./`;

export {}
