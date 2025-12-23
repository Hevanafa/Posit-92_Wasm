import { styleText } from "node:util";

// Requires Bun to be installed
if (Bun == null)
  throw new Error("This app requires Bun!");

async function startServer(port: number, maxRetries: number): Promise<void> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
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

      const url = `http://localhost:${server.port}`;
      console.log(styleText("green", "Server is running at " + url));
      
      if (Bun.argv.includes("-o") || Bun.argv.includes("--open")) {
        // Start process on Windows
        Bun.spawn(["cmd", "/c", "start", url], { stdout: "inherit", stderr: "inherit" });

        console.log("Opening browser...")
      }

      return

    } catch (error) {
      if (attempt < maxRetries - 1)
        console.log(`Port ${port + attempt} is in use, trying ${port + attempt + 1}...`)
      else
        throw new Error("Failed to start server after " + maxRetries + " attempts");
    }
  }
}

try {
  await startServer(8008, 5)
} catch (error) {
  if (error instanceof Error)
    console.log(styleText("red", `Error: ${error.message}`))
  else
    console.log(styleText("red", "Error: " + String(error)));
}
