// Requires Bun to be installed
if (Bun == null)
  throw new Error("This app requires Bun!");

async function startServer(port: number, maxRetries = 5): Promise<void> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    const server = Bun.serve({
      port: port + attempt,

      async fetch(req) {
        const url = new URL(req.url);
        const filepath = `.${url.pathname}`;

        try {
          let file = Bun.file(filepath);

          if (filepath.endsWith("/"))
            file = Bun.file(`${filepath}index.html`);
          
          if (!(await file.exists()))
            return new Response("404 - File not found", { status: 404 })
          else
            return new Response(file)
        } catch (error) {
          return new Response("404 - File not found", { status: 404 });
        }
      }
    })

    console.log(`Server running at http://localhost:${server.port}`);
  }
}

