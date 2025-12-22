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
  
  /**
   * Grow Wasm memory size (DOS-style: fixed allocation)
   * Layout:
   * * 0-1 MB: stack / globals
   * * 1MB-2MB: heap
   */

  const heapStart = 1048576;  // 1 MB = 1024 * 1024 B
  const heapSize = 1 * 1048576;

  // Wasm memory is in 64KB pages
  const pages = wasm.exports.memory.buffer.byteLength / 65536;
  const requiredPages = Math.ceil((heapStart + heapSize) / 65536);

  if (pages < requiredPages)
    wasm.exports.memory.grow(requiredPages - pages);

  wasm.exports.initHeap(heapStart, heapSize);
}

async function main() {
  await initWebAssembly();
  wasm.exports.init();
  wasm.exports.testHeap()
}

main()
