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
    _haltproc: exitcode => console.log("Programme halted with code:", exitcode),
    logI32: value => console.log("Pascal:", value)
  }
}


// VGA
function cls(colour) {
  wasm.exports.cls(colour);
}

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


// BITMAP
async function loadImageFromURL(url) {
  if (url == null || url == "")
    throw new Error("loadImageFromURL: url is required");

  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = reject;
    img.src = url
  })
}

async function loadImage(url) {
  if (url == null || url == "")
    throw new Error("loadImage: url is required");

  const img = await loadImageFromURL(url);
  // console.log(`Loaded image: { w: ${img.width}, h: ${img.height} }`);

  // Copy image
  const tempCanvas = document.createElement("canvas");
  tempCanvas.width = img.width;
  tempCanvas.height = img.height;
  const tempCtx = tempCanvas.getContext("2d");
  tempCtx.drawImage(img, 0, 0);
  const pixels = tempCtx.getImageData(0, 0, img.width, img.height).data;

  // Obtain a new handle number
  const imgHandle = wasm.exports.loadImageHandle();
  const bitmapPtr = wasm.exports.getImagePtr(imgHandle);
  
  // Write to TBitmap
  const memory = new Uint8Array(wasm.exports.memory.buffer, bitmapPtr);
  memory[0] = img.width & 0xff;
  memory[1] = (img.width >> 8) & 0xff;
  memory[2] = img.height & 0xff;
  memory[3] = (img.height >> 8) & 0xff;
  memory.set(pixels, 4);  // TBitmap.data

  // console.log("First 20 bytes:", Array.from(memory).slice(0, 20));

  return imgHandle
}

function spr(imgHandle, x, y) {
  wasm.exports.spr(imgHandle, x, y);
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
  // console.log("wasm.exports", wasm.exports);
  wasm.exports.initBuffer();
}
