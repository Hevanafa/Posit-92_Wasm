/**
 * @type {HTMLCanvasElement}
 */
const canvas = document.getElementById("canvas");
const ctx = canvas.getContext("2d");

const importObject = {
  env: {
    _haltproc: exitcode => console.log("Programme halted with code:", exitcode)
  }
}

async function main() {
  const response = await fetch("game.wasm");
  const bytes = await response.arrayBuffer();
  const result = await WebAssembly.instantiate(bytes, importObject);
  const wasm = result.instance;

  wasm.exports.initBuffer();
  const surfacePtr = wasm.exports.getSurface();
  // console.log("Surface pointer", surfacePtr);

  wasm.exports.cls(0xFF6495ED);

  // Debug surfacePtr
  // const memory = new Uint8Array(wasm.exports.memory.buffer, surfacePtr, 20);
  // console.log("First 20 bytes:", Array.from(memory));

  // Output to the canvas
  const imageData = new Uint8ClampedArray(
    wasm.exports.memory.buffer,
    surfacePtr,
    320 * 200 * 4
  );
  const imgData = new ImageData(imageData, 320, 200);
  ctx.putImageData(imgData, 0, 0)
}

main()
