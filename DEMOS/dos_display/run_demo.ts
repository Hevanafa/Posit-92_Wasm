const args = Bun.argv.slice(2).join(" ");
await Bun.$`bun ../../scripts/server.ts ${args}`;
export {}