/**
 * @type {WebAssembly.Instance}
 */
let wasm;

/**
 * This also works:
 * 
 * `new TextDecoder()`
 * 
 * Since it's UTF-8 by default
 */
const textDecoder = new TextDecoder("utf-8");

function logWithPtr(ptr, len) {
  const bytes = new Uint8Array(wasm.exports.memory.buffer, ptr, len);
  const text = textDecoder.decode(bytes);

  console.log(text)
}

// Add your Pascal external procedures & functions here:
const importObject = Object.freeze({
  env: {
    _haltproc: exitcode => console.log("Programme halted with code:", exitcode),

    // Just to please the WebAssembly init
    flushLog: () => {},
    jsPanicHalt: () => {},

    helloWorld: () => console.log("Hello from snippets!"),

    // logWithPtr: (ptr, len) => logWithPtr(ptr, len);
    logWithPtr

    // Add more externals below
  }
});

async function initWebAssembly() {
  const response = await fetch("main.wasm");
  const bytes = await response.arrayBuffer();
  const result = await WebAssembly.instantiate(bytes, importObject);
  wasm = result.instance;
}

async function main() {
  await initWebAssembly();
  wasm.exports.init();

  const ptr = wasm.exports.getByteArrayPtr();
  const len = wasm.exports.getByteArrayLen();

  // console.log("ptr:", ptr);
  // console.log("len:", len);

  // Test 大家好 - JS to Pascal
  // new TextEncoder("utf-8") is the default
  const bytes = new TextEncoder().encode("大家好！");
  wasm.exports.setByteArrayLen(bytes.length);
  new Uint8Array(wasm.exports.memory.buffer, ptr, bytes.length).set(bytes);

  // Test the result immediately
  logWithPtr(ptr, len)
}

main()
