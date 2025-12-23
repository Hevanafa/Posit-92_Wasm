const args = Bun.argv.slice(2).join(" ");
await Bun.$`bun server.ts ${args}`;
export {}