/**
 * @type {WebAssembly.Instance}
 */
let wasm;

/**
 * Pass a JS string to Pascal
 * This sets 2 variables: stringBuffer, stringBufferLength
 */
function loadStringBuffer(text) {
  const encoder = new TextEncoder();
  const bytes = encoder.encode(text);

  const bufferPtr = wasm.exports.getStringBuffer();
  const buffer = new Uint8Array(
    wasm.exports.memory.buffer, bufferPtr, bytes.length);
  buffer.set(bytes);

  wasm.exports.setStringBufferLength(bytes.length);

  return bytes.length
}

function documentWrite() {
  // Read from string buffer, then output as HTML
  const bufferPtr = wasm.exports.getStringBuffer();
  const buffer = new Uint8Array(wasm.exports.memory.buffer, bufferPtr, 256);

  // Pascal string starts from index 1
  const len = buffer[0];
  const bytes = buffer.slice(1, 1 + len);
  const msg = new TextDecoder().decode(bytes);

  document.writeln(msg)
}

// Add your Pascal external procedures & functions here:
const importObject = Object.freeze({
  env: {
    _haltproc: exitcode => console.log("Programme halted with code:", exitcode),

    hello: () => document.writeln("Hello from Wasm!"),
    documentWrite: () => documentWrite()
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
  // loadStringBuffer("Hello from JS!");
}

main()
