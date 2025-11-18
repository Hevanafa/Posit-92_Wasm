class Posit92 {
  /**
   * @type {HTMLCanvasElement}
   */
  #canvas;
  #ctx;

  /**
   * @type {WebAssembly.Instance}
   */
  #wasm;

  #importObject = Object.freeze({
    env: {
      _haltproc: exitcode => console.log("Programme halted with code:", exitcode),

      // Logger
      writeLogI32: value => console.log("Pascal:", value),
      flushLog: () => this.pascalWriteLog()
    }
  });

  constructor(canvasID) {
    if (canvasID == null || canvasID == "")
      throw new Error("canvasID is required!");

    this.#canvas = document.getElementById(canvasID);
    if (this.#canvas == null)
      throw new Error(`Couldn't find canvasID \"${ canvasID }\"`);

    this.#ctx = this.#canvas.getContext("2d");
  }

  // Init segment
  async #initWebAssembly() {
    const response = await fetch("game.wasm");
    const bytes = await response.arrayBuffer();
    const result = await WebAssembly.instantiate(bytes, this.#importObject);
    this.#wasm = result.instance;
  }

  async init() {
    await this.#initWebAssembly();
    // console.log("wasm.exports", this.#wasm.exports);
    this.#wasm.exports.initBuffer();
  }


  // BITMAP.PAS
  async loadImageFromURL(url) {
    if (url == null || url == "")
      throw new Error("loadImageFromURL: url is required");

    return new Promise((resolve, reject) => {
      const img = new Image();
      img.onload = () => resolve(img);
      img.onerror = reject;
      img.src = url
    })
  }

  debugImage(imgHandle) {
    this.#wasm.exports.debugImage(imgHandle)
  }

  async loadImage(url) {
    if (url == null || url == "")
      throw new Error("loadImage: url is required");

    const img = await this.loadImageFromURL(url);
    // console.log(`Loaded image: { w: ${img.width}, h: ${img.height} }`);

    // Copy image
    const tempCanvas = document.createElement("canvas");
    tempCanvas.width = img.width;
    tempCanvas.height = img.height;
    const tempCtx = tempCanvas.getContext("2d");
    tempCtx.drawImage(img, 0, 0);
    const pixels = tempCtx.getImageData(0, 0, img.width, img.height).data;

    // Obtain a new handle number
    const imgHandle = this.#wasm.exports.loadImageHandle();
    const bitmapPtr = this.#wasm.exports.getImagePtr(imgHandle);
    
    // Write to TBitmap
    const memory = new Uint8Array(this.#wasm.exports.memory.buffer, bitmapPtr);
    memory[0] = img.width & 0xff;
    memory[1] = (img.width >> 8) & 0xff;
    memory[2] = img.height & 0xff;
    memory[3] = (img.height >> 8) & 0xff;
    memory.set(pixels, 4);  // TBitmap.data

    // console.log("First 20 bytes:", Array.from(memory).slice(0, 20));

    return imgHandle
  }

  spr(imgHandle, x, y) {
    this.#wasm.exports.spr(imgHandle, x, y)
  }


  // GRAPHICS.PAS
  circ(cx, cy, radius, colour) {
    this.#wasm.exports.circ(cx, cy, radius, colour)
  }

  circfill(cx, cy, radius, colour) {
    this.#wasm.exports.circfill(cx, cy, radius, colour)
  }

  rect(x0, y0, x1, y1, colour) {
    this.#wasm.exports.rect(x0, y0, x1, y1, colour)
  }

  rectfill(x0, y0, x1, y1, colour) {
    this.#wasm.exports.rectfill(x0, y0, x1, y1, colour)
  }

  hline(x0, x1, y, colour) {
    this.#wasm.exports.hline(x0, x1, y, colour)
  }

  vline(x, y0, y1, colour) {
    this.#wasm.exports.vline(x, y0, y1, colour)
  }

  line(x0, y0, x1, y1, colour) {
    this.#wasm.exports.line(x0, y0, x1, y1, colour)
  }



  // LOGGER.PAS
  pascalWriteLog() {
    const bufferPtr = this.#wasm.exports.getLogBuffer();
    const buffer = new Uint8Array(this.#wasm.exports.memory.buffer, bufferPtr, 256);

    const len = buffer[0];
    const msgBytes = buffer.slice(1, 1 + len);
    const msg = new TextDecoder().decode(msgBytes);

    console.log("Pascal:", msg);
  }


  // VGA.PAS
  cls(colour) {
    this.#wasm.exports.cls(colour);
  }

  flush() {
    const surfacePtr = this.#wasm.exports.getSurface();
    // console.log("Surface pointer", surfacePtr);

    const imageData = new Uint8ClampedArray(
      this.#wasm.exports.memory.buffer,
      surfacePtr,
      320 * 200 * 4
    );
    const imgData = new ImageData(imageData, 320, 200);
    this.#ctx.putImageData(imgData, 0, 0)
  }

  pset(x, y, colour) {
    this.#wasm.exports.pset(x, y, colour)
  }
}
