// Requires Bun to be installed
if (Bun == null)
  throw new Error("This app requires Bun!");

const server = Bun.serve({
  port: 8008,
  async fetch(req) {
    const url = new URL(req.url);
    const filepath = `.${url.pathname}`;

    try {
      const file = Bun.file(filepath);
      return new Response(file)
    } catch (error) {
      return new Response("404 - File not found", { status: 404 });
    }
  }
})

console.log(`Server running at http://localhost:${server.port}`);
