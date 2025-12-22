// Add your Pascal external procedures & functions here:
const importObject = Object.freeze({
  env: {
    _haltproc: exitcode => console.log("Programme halted with code:", exitcode),

    helloWorld: () => console.log("Hello from heap_getmem!")
    // Add more externals below
  }
});

/**
 * @type {WebAssembly.Instance}
 */
let wasm;

async function initWebAssembly() {
  const response = await fetch("main.wasm");
  const bytes = await response.arrayBuffer();
  const result = await WebAssembly.instantiate(bytes, importObject);
  wasm = result.instance;
}

async function main() {
  await initWebAssembly();
  wasm.exports.init();
  wasm.exports.testHeap()
}

main()
