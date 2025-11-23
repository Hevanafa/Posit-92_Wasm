const importObject = Object.freeze({
  env: {
    _haltproc: exitcode => console.log("Programme halted with code:", exitcode),
    // More of your Pascal externals here
  }
});

let wasm;

async function initWebAssembly() {
  const response = await fetch("program.wasm");
  const bytes = await response.arrayBuffer();
  const result = await WebAssembly.instantiate(bytes, importObject);
  wasm = result.instance;
}

async function main() {
  await initWebAssembly();
  
}

main()
