// Setup Boilerplate script - Part of Posit-92 game engine
// Hevanafa

// This script should be executed before copying as a new demo

import { mkdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { stdin } from "node:process";

async function prompt(question: string): Promise<string> {
  process.stdout.write(question);

  for await (const line of console)
    return line.trim();

  return ""
}

while (true) {
  const answer = await prompt(
    "Which version do you want to develop?\n" +
    "  1 - default\n" +
    "  2 - demo\n" +
    "  0 - cancel setup\n" +
    "Choice (default: 1): "
  );

  if (answer == "" || answer == "1") {
    // Default
    console.log("Setting up default version...");

    const source = "..";
    if (!existsSync("UNITS"))
      await mkdir("UNITS");

    await Bun.$`cp ${source}/UNITS/*.pas ./UNITS/`;
    await Bun.$`cp ${source}/UNITS/*.PAS ./UNITS/`;
    
    await Bun.$`cp ${source}/favicon.ico ./`;
    await Bun.$`cp ${source}/posit-92.js ./`;

    const scripts = [
      "build_run", "compile", "run", "server",
      "dist", "build_dist"];
    for (const filename of scripts)
      await Bun.$`cp ${source}/scripts/${filename}.ts ./`;

    break

  } else if (answer == "2") {
    console.log("Setting up demo version...");
    console.log(
      "The demo version uses experimental\\units " +
      "instead of the local UNITS folder");

    const source = "..";
    
    await Bun.$`cp ${source}/favicon.ico ./`;
    await Bun.$`cp ${source}/posit-92.js ./`;

    const scripts = ["build_run_demo", "compile_demo", "run_demo"];
    for (const filename of scripts)
      await Bun.$`cp ${source}/scripts/${filename}.ts ./`;

    break

  } else if (answer == "0") {
    console.log("Setup cancelled");
    break
  }
}

export {}
