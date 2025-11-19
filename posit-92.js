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
      writeLogI32: value => console.log("Pascal (i32):", value),
      flush: () => this.flush(),
      flushLog: () => this.pascalWriteLog(),
      getTimer: () => this.getTimer()
    }
  });

  constructor(canvasID) {
    if (canvasID == null)
      throw new Error("canvasID is required!");

    this.#assertString(canvasID);

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
    // this.#wasm.exports.initBuffer();
    this.#wasm.exports.init();
  }

  #assertNumber(value) {
    if (value == null)
      throw new Error("Expected a number, but received null");

    if (typeof value != "number")
      throw new Error(`Expected a number, but received ${typeof value}`);

    if (isNaN(value))
      throw new Error("Expected a number, but received NaN");
  }

  #assertString(value) {
    if (typeof value != "string")
      throw new Error(`Expected a string, but received ${typeof value}`);
  }


  // BITMAP.PAS
  async loadImageFromURL(url) {
    if (url == null)
      throw new Error("loadImageFromURL: url is required");

    this.#assertString(url);

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
    if (url == null)
      throw new Error("loadImage: url is required");

    this.#assertString(url);

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

  getImageWidth(imgHandle) {
    this.#assertNumber(imgHandle);
    return this.#wasm.exports.getImageWidth(imgHandle)
  }

  getImageHeight(imgHandle) {
    this.#assertNumber(imgHandle);
    return this.#wasm.exports.getImageHeight(imgHandle)
  }

  spr(imgHandle, x, y) {
    this.#assertNumber(imgHandle);
    this.#assertNumber(x);
    this.#assertNumber(y);

    this.#wasm.exports.sprBlend(imgHandle, x, y);
  }

  sprRegion(imgHandle, srcX, srcY, srcW, srcH, destX, destY) {
    this.#assertNumber(imgHandle);
    this.#assertNumber(srcX);
    this.#assertNumber(srcY);
    this.#assertNumber(srcW);
    this.#assertNumber(srcH);
    this.#assertNumber(destX);
    this.#assertNumber(destY);

    this.#wasm.exports.sprRegionBlend(imgHandle, srcX, srcY, srcW, srcH, destX, destY)
  }


  // BMFONT.PAS
  #newBMFontGlyph() {
    return {
      id: 0,
      x: 0,
      y: 0,
      width: 0,
      height: 0,
      xoffset: 0,
      yoffset: 0,
      xadvance: 0,
      lineHeight: 0
    }
  }

  async loadBMFont(url) {
    if (url == null)
      throw new Error("loadBMFont: url is required");

    this.#assertString(url);

    const res = await fetch(url);
    const text = await res.text();

    const lines = text.endsWith("\r\n") ? text.split("\r\n") : text.split("\n");

    let txtLine = "";
    /**
     * @type {Array<[string, string]>}
     */
    let pairs;
    let k = "", v = "";

    let lineHeight = 0;
    // font bitmap URL
    let filename = "";
    const fontGlyphs = {};
    let glyphCount = 0;
    let imgHandle = 0;

    for (const line of lines) {
      txtLine = line.replaceAll(/\s+/g, " ");
      
      pairs = txtLine.split(" ").map(part => part.split("="));

      if (txtLine.startsWith("info")) {
        [k, v] = pairs.find(pair => pair[0] == "face");
        // console.log("face", v)

      } else if (txtLine.startsWith("common")) {
        [k, v] = pairs.find(pair => pair[0] == "lineHeight");
        lineHeight = parseInt(v);
        // console.log("lineHeight", lineHeight);

      } else if (txtLine.startsWith("page")) {
        [k, v] = pairs.find(pair => pair[0] == "file");
        filename = v.replaceAll(/"/g, "");
        // console.log("filename", filename);

      } else if (txtLine.startsWith("char") && !txtLine.startsWith("chars")) {
        const tempGlyph = this.#newBMFontGlyph();

        for (const [k, v] of pairs) {
          switch (k) {
            case "id": tempGlyph.id = parseInt(v); break;
            case "x": tempGlyph.x = parseInt(v); break;
            case "y": tempGlyph.y = parseInt(v); break;
            case "width": tempGlyph.width = parseInt(v); break;
            case "height": tempGlyph.height = parseInt(v); break;
            case "xoffset": tempGlyph.xoffset = parseInt(v); break;
            case "yoffset": tempGlyph.yoffset = parseInt(v); break;
            case "xadvance": tempGlyph.xadvance = parseInt(v); break;
          }
        }

        fontGlyphs[tempGlyph.id] = tempGlyph;
        glyphCount++
      }
    }

    console.log("Loaded", glyphCount, "glyphs");

    // Load font bitmap
    imgHandle = await this.loadImage(filename);
    console.log("loadBMFont imgHandle:", imgHandle);

    // Obtain pointers to Pascal structures
    const fontPtr = this.#wasm.exports.defaultFontPtr();
    const glyphsPtr = this.#wasm.exports.defaultFontGlyphsPtr();

    // Write font data
    const fontMem = new DataView(this.#wasm.exports.memory.buffer, fontPtr);

    let offset = 0;
    // Skip face string
    offset += 16;  // was 256
    // Skip filename string
    offset += 64;  // was 256

    // true makes it little-endian
    fontMem.setUint16(offset, lineHeight, true);
    // console.log("imgHandle to write", imgHandle);
    fontMem.setInt32(offset + 2, imgHandle, true);

    // Write glyphs
    const glyphsMem = new DataView(this.#wasm.exports.memory.buffer, glyphsPtr);

    for (const charID in fontGlyphs) {
      const glyph = fontGlyphs[charID];
      const id = parseInt(charID);

      // Range check
      if (id < 32 || id > 126) continue;

      // 16 is from the 8 fields of TBMFontGlyph, all 2 bytes
      const glyphOffset = (id - 32) * 16;

      glyphsMem.setUint16(glyphOffset + 0, glyph.id, true);

      glyphsMem.setUint16(glyphOffset + 2, glyph.x, true);
      glyphsMem.setUint16(glyphOffset + 4, glyph.y, true);
      glyphsMem.setUint16(glyphOffset + 6, glyph.width, true);
      glyphsMem.setUint16(glyphOffset + 8, glyph.height, true);

      glyphsMem.setInt16(glyphOffset + 10, glyph.xoffset, true);
      glyphsMem.setInt16(glyphOffset + 12, glyph.yoffset, true);
      glyphsMem.setInt16(glyphOffset + 14, glyph.xadvance, true);
    }

    console.log("loadBMFont completed");
  }

  #loadStringBuffer(text) {
    this.#assertString(text);

    const encoder = new TextEncoder();
    const bytes = encoder.encode(text);

    const bufferPtr = this.#wasm.exports.getStringBuffer();
    const buffer = new Uint8Array(this.#wasm.exports.memory.buffer, bufferPtr, bytes.length);
    buffer.set(bytes);

    return bytes.length
  }

  // printBMFont(text) {
  printDefault(text, x, y) {
    this.#assertString(text);
    this.#assertNumber(x);
    this.#assertNumber(y);

    const length = this.#loadStringBuffer(text);
    const bufferPtr = this.#wasm.exports.getStringBuffer();
    // this.#wasm.exports.debugStringBuffer();
    this.#wasm.exports.printDefault(bufferPtr, length, x, y)
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


  // TIMING.PAS
  getTimer() {
    return Date.now() / 1000
  }

  initDeltaTime() {
    this.#wasm.exports.initDeltaTime()
  }

  updateDeltaTime() {
    this.#wasm.exports.updateDeltaTime()
  }


  // VGA.PAS
  cls(colour) {
    this.#assertNumber(colour);
    this.#wasm.exports.cls(colour);
  }

  flush() {
    const surfacePtr = this.#wasm.exports.getSurface();
    const imageData = new Uint8ClampedArray(
      this.#wasm.exports.memory.buffer,
      surfacePtr,
      320 * 200 * 4
    );

    // console.log("First 5 pixels:");
    // for (let a=0; a < 20; a += 4)
    //   console.log(`Pixel ${a / 4}: R=${imageData[a]} G=${imageData[a+1]} B=${imageData[a+2]} A=${imageData[a+3]}`);

    const imgData = new ImageData(imageData, 320, 200);

    this.#ctx.putImageData(imgData, 0, 0);
  }

  pset(x, y, colour) {
    this.#assertNumber(x);
    this.#assertNumber(y);
    this.#assertNumber(colour);

    this.#wasm.exports.pset(x, y, colour)
  }

  // Game loop
  update() {
    this.#wasm.exports.update()
  }

  draw() {
    this.#wasm.exports.draw()
  }
}
