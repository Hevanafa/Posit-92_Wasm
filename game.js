/**
 * @type {HTMLCanvasElement}
 */
const canvas = document.getElementById("canvas");
const ctx = canvas.getContext("2d");

/**
 * @type {WebAssembly.Instance}
 */
let wasm;

const importObject = {
  env: {
    _haltproc: exitcode => console.log("Programme halted with code:", exitcode)
  }
}

// VGA
function flush() {
  const surfacePtr = wasm.exports.getSurface();
  // console.log("Surface pointer", surfacePtr);

  const imageData = new Uint8ClampedArray(
    wasm.exports.memory.buffer,
    surfacePtr,
    320 * 200 * 4
  );
  const imgData = new ImageData(imageData, 320, 200);
  ctx.putImageData(imgData, 0, 0)
}

async function loadImage(url) {
  if (url == null || url == "")
    throw new Error("loadImage: url is required");

  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = reject;
    img.src = url
  })
}

// Bitmaps
async function loadImageBuffer(url) {
  if (url == null || url == "")
    throw new Error("loadImageBuffer: url is required");

  const img = await loadImage(url);
  console.log(`Loaded image: { w: ${img.width}, h: ${img.height} }`);

  // Copy image
  const tempCanvas = document.createElement("canvas");
  tempCanvas.width = img.width;
  tempCanvas.height = img.height;
  const tempCtx = tempCanvas.getContext("2d");
  tempCtx.drawImage(img, 0, 0);
  const pixels = tempCtx.getImageData(0, 0, img.width, img.height).data;
  // wasm.exports.allocImageData(pixels.length);

  const imgBufferPtr = wasm.exports.getImageBuffer();
  // Create a view into the WASM memory
  const imgBuffer = new Uint8Array(
    wasm.exports.memory.buffer,
    imgBufferPtr, 
    pixels.length);

  // The same as implementation above
  imgBuffer.set(pixels);

  console.log("First 20 bytes:", Array.from(imgBuffer));
}

// Init segment
async function initWebAssembly() {
  const response = await fetch("game.wasm");
  const bytes = await response.arrayBuffer();
  const result = await WebAssembly.instantiate(bytes, importObject);
  wasm = result.instance;
}

async function init() {
  await initWebAssembly();
  console.log("wasm.exports", wasm.exports);
  wasm.exports.initBuffer();
}

async function main() {
  await init();

  // Load assets
  loadImageBuffer("assets/images/satono_diamond.png");

  // Begin render logic
  wasm.exports.cls(0xFF6495ED);

  // Debug surfacePtr
  // const memory = new Uint8Array(wasm.exports.memory.buffer, surfacePtr, 20);
  // console.log("First 20 bytes:", Array.from(memory));

  // wasm.exports.spr(10, 10, img.width, img.height);
  wasm.exports.spr(10, 10, 100, 88);

  flush();
}

main()
