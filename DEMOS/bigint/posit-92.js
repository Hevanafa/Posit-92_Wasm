"use strict";

/**
 * Game assets are loaded in loadAssets()
 */

/**
 * KeyboardEvent.code to DOS scancode
 */
const ScancodeMap = {
  "Escape": 0x01,
  "Space": 0x39,

  "ArrowLeft": 0x4B,
  "ArrowRight": 0x4D
  // Add more scancodes as necessary
};

class Posit92 {
  #displayScale = Object.freeze(2);
  #wasmSource = "game.wasm";

  #vgaWidth = 320;
  #vgaHeight = 200;

  /**
   * @type {HTMLCanvasElement}
   */
  #canvas;
  #ctx;

  /**
   * @type {WebAssembly.Instance}
   */
  #wasm;
  get wasmInstance() { return this.#wasm }

  /**
   * For use with WebAssembly init
   */
  #importObject = {
    env: {
      _haltproc: exitcode => console.log("Programme halted with code:", exitcode),

      hideCursor: () => this.hideCursor(),
      showCursor: () => this.showCursor(),

      wasmgetmem: this.#WasmGetMem.bind(this),

      // Keyboard
      isKeyDown: this.isKeyDown.bind(this),
      signalDone: () => { done = true },

      // Logger
      writeLogI32: value => console.log("Pascal (i32):", value),
      flushLog: () => this.pascalWriteLog(),

      // Mouse
      getMouseX: () => this.getMouseX(),
      getMouseY: () => this.getMouseY(),
      getMouseButton: () => this.getMouseButton(),

      // Panic
      panicHalt: this.panicHalt.bind(this),

      // Timing
      getTimer: () => this.getTimer(),

      // VGA
      flush: () => this.flush()
    }
  };
  
  _getWasmImportObject() {
    return this.#importObject
  }

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
    const response = await fetch(this.#wasmSource);
    const bytes = await response.arrayBuffer();
    const result = await WebAssembly.instantiate(bytes, this.#importObject);
    this.#wasm = result.instance;

    // Grow Wasm memory size
    // Wasm memory grows in 64KB pages
    const pages = this.#wasm.exports.memory.buffer.byteLength / 65536;
    const requiredPages = Math.ceil(2 * 1048576 / 65536);

    if (pages < requiredPages)
      this.#wasm.exports.memory.grow(requiredPages - pages);
  }

  async init() {
    Object.freeze(this.#importObject);
    await this.#initWebAssembly();
    this.#wasm.exports.init();
    
    this.#initKeyboard();
    this.#initMouse();
    
    if (this.loadAssets)
      await this.loadAssets();
  }

  afterInit() {
    this.#wasm.exports.afterInit();
    this.#addOutOfFocusFix()
  }

  #addOutOfFocusFix() {
    this.#canvas.addEventListener("click", () => {
      this.#canvas.tabIndex = 0;
      this.#canvas.focus()
    })
  }

  cleanup() {
    this.stopMusic();
    this.showCursor();
  }

  hideCursor() {
    this.#canvas.style.cursor = "none"
  }

  showCursor() {
    this.#canvas.style.removeProperty("cursor")
  }

  #assertNumber(value) {
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

  // Used in loadImage
  #images = [];

  async loadImage(url) {
    if (url == null)
      throw new Error("loadImage: url is required");

    this.#assertString(url);

    const img = await this.loadImageFromURL(url);

    // Copy image
    const tempCanvas = document.createElement("canvas");
    tempCanvas.width = img.width;
    tempCanvas.height = img.height;
    const tempCtx = tempCanvas.getContext("2d");
    tempCtx.drawImage(img, 0, 0);

    const imageData = tempCtx.getImageData(0, 0, img.width, img.height);

    const wasmMemory = new Uint8Array(this.#wasm.exports.memory.buffer);
    const byteSize = img.width * img.height * 4;
    const wasmPtr = this.#WasmGetMem(byteSize);
    wasmMemory.set(imageData.data, wasmPtr)

    if (this.#images.length == 0)
      this.#images.push(null);

    // Register with Wasm pointer
    const handle = this.#images.length;
    this.#images.push(imageData);  // Keep data in JS for reference
    this.#wasm.exports.registerImageRef(handle, wasmPtr, img.width, img.height);

    return handle
  }

  // Start at 1 MB
  #wasmMemoryOffset = 1048576;

  #WasmGetMem(bytes) {
    const ptr = this.#wasmMemoryOffset;
    this.#wasmMemoryOffset += bytes;

    // Align to 4 byte
    this.#wasmMemoryOffset = (this.#wasmMemoryOffset + 3) & ~3;
    return ptr
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

      } else if (txtLine.startsWith("common")) {
        [k, v] = pairs.find(pair => pair[0] == "lineHeight");
        lineHeight = parseInt(v);

      } else if (txtLine.startsWith("page")) {
        [k, v] = pairs.find(pair => pair[0] == "file");
        filename = v.replaceAll(/"/g, "");

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
    // console.log("loadBMFont imgHandle:", imgHandle);

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
    
    // +2 requires a packed record because Pascal records are padded by default
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


  // KEYBOARD.PAS
  heldScancodes = new Set();

  #initKeyboard() {
    window.addEventListener("keydown", e => {
      console.log("keydown", e.code);

      const scancode = ScancodeMap[e.code];
      if (scancode) {
        this.heldScancodes.add(scancode);
        e.preventDefault();
      }
    })

    window.addEventListener("keyup", e => {
      const scancode = ScancodeMap[e.code];
      if (scancode) this.heldScancodes.delete(scancode)
    })
  }

  isKeyDown(scancode) {
    return this.heldScancodes.has(scancode)
  }


  // MOUSE.PAS
  #mouseX = 0;
  #mouseY = 0;
  #mouseButton = 0;

  #leftButtonDown = false;
  #rightButtonDown = false;

  #initMouse() {
    this.#canvas.addEventListener("mousemove", e => {
      const rect = this.#canvas.getBoundingClientRect();
      this.#mouseX = Math.floor((e.clientX - rect.left) / this.#displayScale);
      this.#mouseY = Math.floor((e.clientY - rect.top) / this.#displayScale);
    });

    this.#canvas.addEventListener("mousedown", e => {
      if (e.button == 0) this.#leftButtonDown = true;
      if (e.button == 2) this.#rightButtonDown = true;
      this.#updateMouseButton();
      e.preventDefault();  // Prevent context menu on right click
    });

    this.#canvas.addEventListener("mouseup", e => {
      if (e.button == 0) this.#leftButtonDown = false;
      if (e.button == 2) this.#rightButtonDown = false;
      this.#updateMouseButton();
    });

    this.#canvas.addEventListener("contextmenu", e => {
      e.preventDefault()
    });
  }

  getMouseX() { return this.#mouseX }
  getMouseY() { return this.#mouseY }
  getMouseButton() { return this.#mouseButton }

  #updateMouseButton() {
    if (this.#leftButtonDown && this.#rightButtonDown)
      this.#mouseButton = 3
    else if (this.#rightButtonDown)
      this.#mouseButton = 2
    else if (this.#leftButtonDown)
      this.#mouseButton = 1
    else
      this.#mouseButton = 0;
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


  // PANIC.PAS
  panicHalt(textPtr, textLen) {
    const buffer = new Uint8Array(this.#wasm.exports.memory.buffer, textPtr, textLen);
    const msg = new TextDecoder().decode(buffer);

    done = true;
    throw new Error(`PANIC: ${msg}`)
  }


  // TIMING.PAS
  getTimer() {
    return Date.now() / 1000
  }


  // VGA.PAS
  flush() {
    const surfacePtr = this.#wasm.exports.getSurfacePtr();
    const imageData = new Uint8ClampedArray(
      this.#wasm.exports.memory.buffer,
      surfacePtr,
      this.#vgaWidth * this.#vgaHeight * 4
    );

    const imgData = new ImageData(imageData, this.#vgaWidth, this.#vgaHeight);

    this.#ctx.putImageData(imgData, 0, 0);
  }


  // Game loop
  update() {
    this.#wasm.exports.update()
  }

  draw() {
    this.#wasm.exports.draw()
  }
}