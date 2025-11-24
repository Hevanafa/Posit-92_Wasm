interface ImportObject {
  env: {
    _haltproc: (exitcode: number) => void;
    helloWorld: () => void;
  }
}

// Add your Pascal external procedures & functions here:
const importObject: ImportObject = Object.freeze({
  env: {
    _haltproc: (exitcode: number) => console.log("Programme halted with code:", exitcode),

    helloWorld: () => console.log("Hello from snippets!")
    // Add more externals below
  }
});

let wasm: WebAssembly.Instance;

async function initWebAssembly() {
  const response = await fetch("main.wasm");
  const bytes = await response.arrayBuffer();
  const result = await WebAssembly.instantiate(bytes, importObject);
  wasm = result.instance;
}

async function main() {
  await initWebAssembly();
  wasm.exports.init();
}

main()
