// Copied from experimental/posit-92.js
// Last synced: 2025-12-29

"use strict";

class Posit92 {
  static version = "0.1.3_experimental";

  #wasmSource = "game.wasm";

  #vgaWidth = 320;
  #vgaHeight = 200;

  /**
   * @type {HTMLCanvasElement}
   */
  #canvas;
  /**
   * @type {CanvasRenderingContext2D}
   */
  #ctx;

  /**
   * @type {WebAssembly.Instance}
   */
  #wasm;
  get wasmInstance() { return this.#wasm }

  /**
   * Used in getTimer
   */
  #midnightOffset = 0;

  /**
   * @type {WebAssembly.Imports}
   */
  #importObject = {
    env: {
      _haltproc: this.#handleHaltProc.bind(this),

      // Intro
      hideLoadingOverlay: this.hideLoadingOverlay.bind(this),
      loadAssets: this.#loadAssets.bind(this),

      // Loading
      getLoadingActual: this.getLoadingActual.bind(this),
      getLoadingTotal: this.getLoadingTotal.bind(this),

      hideCursor: () => this.#hideCursor(),
      showCursor: () => this.#showCursor(),

      // Fullscreen
      toggleFullscreen: () => this.#toggleFullscreen(),
      endFullscreen: () => this.#endFullscreen(),
      getFullscreenState: () => this.#getFullscreenState(),
      fitCanvas: () => this.#fitCanvas(),

      // Keyboard
      isKeyDown: this.#isKeyDown.bind(this),
      signalDone: this.#signalDone.bind(this),

      // Logger
      writeLogF32: value => console.log("Pascal (f32):", value),
      writeLogI32: value => console.log("Pascal (i32):", value),
      flushLog: () => this.#pascalWriteLog(),

      // Mouse
      getMouseX: () => this.#getMouseX(),
      getMouseY: () => this.#getMouseY(),
      getMouseButton: () => this.#getMouseButton(),

      // Panic
      panicHalt: this.#panicHalt.bind(this),

      // Timing
      getTimer: () => this.#getTimer(),
      getFullTimer: () => this.#getFullTimer(),

      // VGA
      vgaFlush: () => this.#vgaFlush()
    }
  };

  _getWasmImportObject() {
    return this.#importObject
  }
  
  #handleHaltProc(exitcode) {
    console.log("Programme halted with code:", exitcode);
    this.cleanup();
    done = true
  }

  #signalDone() {
    this.cleanup();
    done = true
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

  #loadMidnightOffset() {
    const now = new Date();
    const midnight = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    this.#midnightOffset = midnight.getTime()
  }

  async #initWebAssembly() {
    const response = await fetch(this.#wasmSource);

    const contentLength = response.headers.get("Content-Length");  // Assuming that this is always available
    // in bytes:
    const total = Number(contentLength);
    let loaded = 0;

    const reader = response.body.getReader();
    const chunks = [];

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      chunks.push(value);
      loaded += value.length;

      this.onWasmProgress(loaded, total)
    }

    // Combine chunks
    const bytes = new Uint8Array(loaded);
    let pos = 0;
    for (const chunk of chunks) {
      bytes.set(chunk, pos);
      pos += chunk.length
    }

    const result = await WebAssembly.instantiate(bytes.buffer, this.#importObject);
    this.#wasm = result.instance;
  }

  /**
   * @param {number} loaded in bytes
   * @param {number} total in bytes
   */
  onWasmProgress(loaded, total) {
    const loadedKB = Math.ceil(loaded / 1024);

    if (isNaN(total))
      this.setLoadingText(`Downloading engine (${ loadedKB } KB)`)
    else {
      const totalKB = Math.ceil(total / 1024);
      this.setLoadingText(`Downloading engine (${ loadedKB } KB / ${ totalKB } KB)`)
    }
  }

  #initWasmMemory() {
    /**
     * Grow Wasm memory size (DOS-style: fixed allocation)
     * Layout:
     * * 256 KB: stack / globals
     * * 1MB-2MB: heap
     */
    const heapStart = 256 * 1024;
    const heapSize = 1 * 1048576;

    // Wasm memory is in 64KB pages
    const pages = this.#wasm.exports.memory.buffer.byteLength / 65536;
    const requiredPages = Math.ceil((heapStart + heapSize) / 65536);

    if (pages < requiredPages)
      this.#wasm.exports.memory.grow(requiredPages - pages);

    this.#wasm.exports.initHeap(heapStart, heapSize);
  }

  async init() {
    this.#loadMidnightOffset();

    Object.freeze(this.#importObject);
    await this.#initWebAssembly();
    this.#initWasmMemory();
    this.#wasm.exports.init();
    
    this.#initKeyboard();
    this.#initMouse();
  }

  beginIntro() {
    this.#wasm.exports.beginIntroState()
  }

  #addOutOfFocusFix() {
    this.#canvas.addEventListener("click", () => {
      this.#canvas.tabIndex = 0;
      this.#canvas.focus()
    })
  }

  /**
   * Called when `done` is `true`
   */
  cleanup() {
    this.#showCursor();
  }

  /**
   * Overridden by the inherited `Game` class
   */
  async loadAssets() {}

  async #loadAssets() {
    await this.loadAssets();
    this.afterInit()
  }

  /**
   * Bypass intro sequence
   * 
   * Should be used **without** the intro screen
   */
  async quickStart() {
    this.hideLoadingOverlay();
    this.#wasm.exports.beginLoadingState();
    // await this.#loadAssets();
    // this.afterInit()
  }

  afterInit() {
    this.#wasm.exports.afterInit();
    this.#addOutOfFocusFix()
  }


  #hideCursor() {
    this.#canvas.style.cursor = "none"
  }

  #showCursor() {
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
    const wasmPtr = this.#wasm.exports.WasmGetMem(byteSize);
    wasmMemory.set(imageData.data, wasmPtr)

    if (this.#images.length == 0)
      this.#images.push(null);

    // Register with Wasm pointer
    const handle = this.#images.length;
    this.#images.push(imageData);  // Keep data in JS for reference
    this.#wasm.exports.registerImageRef(handle, wasmPtr, img.width, img.height);

    return handle
  }

  /**
   * Used in asset counter
   */
  #loadingActual = 0;
  getLoadingActual() { return this.#loadingActual }

  /**
   * Used in asset counter
   */
  #loadingTotal = 0;
  getLoadingTotal() { return this.#loadingTotal }

  /**
   * Load images from manifest in parallel
   * @param {Object.<string, string>} manifest - Key-value pairs of `"asset_key": "image_path"`
   */
  async loadImagesFromManifest(manifest) {
    const entries = Object.entries(manifest);

    const promises = entries.map(([key, path]) =>
      this.loadImage(path).then(handle => {
        // On success
        this.incLoadingActual();
        return { key, path, handle }
      })
    );

    const results = await Promise.all(promises);

    const failures = results.filter(item => item.handle == 0);
    if (failures.length > 0) {
      console.error("Failed to load assets:");
      
      for (const failure of failures)
        console.error("   " + failure.key + ": " + failure.path);

      throw new Error("Failed to load some assets")
    }

    for (const { key, handle } of results) {
      const caps = key
        .replace(/^./, _ => _.toUpperCase())
        .replace(/_(.)/g, (_, g1) => g1.toUpperCase());
      const setterName = `setImg${caps}`;

      if (typeof this.wasmInstance.exports[setterName] != "function")
        console.error("loadAssetsFromManifest: Missing setter", setterName, "for the asset key", key)
      else
        this.wasmInstance.exports[setterName](handle);
    }
  }

  get loadingProgress() {
    return {
      actual: this.#loadingActual,
      total: this.#loadingTotal
    }
  }

  incLoadingActual() {
    // console.trace("incLoadingActual");
    this.#loadingActual++;
    // if (this.#loadingActual > this.#loadingTotal)
    //   this.#loadingActual = this.#loadingTotal;
  }

  setLoadingActual(value) {
    this.#assertNumber(value);
    this.#loadingActual = value
  }

  incLoadingTotal(count) {
    this.#loadingTotal += count
  }

  setLoadingTotal(value) {
    this.#assertNumber(value);
    this.#loadingTotal = value
  }

  setLoadingText(text) {
    const div = document.querySelector("#loading-overlay > div");
    div.innerHTML = text;
  }

  hideLoadingOverlay() {
    const div = document.getElementById("loading-overlay");
    // div.style.display = "none";
    div.classList.add("hidden");
    this.setLoadingText("");
  }

  async sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  initLoadingScreen() {
    const imageCount = this.AssetManifest.images != null
      ? Object.keys(this.AssetManifest.images).length
      : 0;
    const soundCount = this.AssetManifest.sounds != null
      ? this.AssetManifest.sounds.size
      : 0;
    
    this.setLoadingActual(0);
    this.setLoadingTotal(imageCount + soundCount);
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

  async loadBMFont(url, fontPtrRef, fontGlyphsPtrRef) {
    if (url == null)
      throw new Error("loadBMFont: url is required");

    this.#assertString(url);
    this.#assertNumber(fontPtrRef);
    this.#assertNumber(fontGlyphsPtrRef);

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

    const fontPtr = fontPtrRef;
    const glyphsPtr = fontGlyphsPtrRef;

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
    const ScancodeMap = this.ScancodeMap;
    
    window.addEventListener("keydown", e => {
      if (e.repeat) return;

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

  #isKeyDown(scancode) {
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

      const scaleX = this.#canvas.width / rect.width;
      const scaleY = this.#canvas.height / rect.height;

      this.#mouseX = Math.floor((e.clientX - rect.left) * scaleX);
      this.#mouseY = Math.floor((e.clientY - rect.top) * scaleY);
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

  #getMouseX() { return this.#mouseX }
  #getMouseY() { return this.#mouseY }
  #getMouseButton() { return this.#mouseButton }

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
  #pascalWriteLog() {
    const bufferPtr = this.#wasm.exports.getLogBuffer();
    const buffer = new Uint8Array(this.#wasm.exports.memory.buffer, bufferPtr, 256);

    const len = buffer[0];
    const msgBytes = buffer.slice(1, 1 + len);
    const msg = new TextDecoder().decode(msgBytes);

    console.log("Pascal:", msg);
  }


  // PANIC.PAS
  #panicHalt(textPtr, textLen) {
    const buffer = new Uint8Array(this.#wasm.exports.memory.buffer, textPtr, textLen);
    const msg = new TextDecoder().decode(buffer);

    done = true;
    this.cleanup();

    throw new Error(`PANIC: ${msg}`)
  }


  // TIMING.PAS
  #getTimer() {
    return (Date.now() - this.#midnightOffset) / 1000
  }

  #getFullTimer() {
    return Date.now() / 1000
  }


  // VGA.PAS
  flush() { this.#vgaFlush() }
  
  #vgaFlush() {
    const surfacePtr = this.#wasm.exports.getSurfacePtr();
    const imageData = new Uint8ClampedArray(
      this.#wasm.exports.memory.buffer,
      surfacePtr,
      this.#vgaWidth * this.#vgaHeight * 4
    );

    const imgData = new ImageData(imageData, this.#vgaWidth, this.#vgaHeight);

    this.#ctx.putImageData(imgData, 0, 0);
  }

  // Fullscreen.pas
  #toggleFullscreen() {
    if (document.fullscreenElement == null)
      this.#canvas.requestFullscreen()
    else
      document.exitFullscreen();
  }

  #endFullscreen() {
    if (this.#getFullscreenState())
      document.exitFullscreen();

    this.#fitCanvas()
  }

  #getFullscreenState() {
    return document.fullscreenElement != null
  }

  #fitCanvas() {
    const aspectRatio = this.#vgaWidth / this.#vgaHeight;

    const [windowWidth, windowHeight] = [window.innerWidth, window.innerHeight];
    const windowRatio = windowWidth / windowHeight;

    let w = 0, h = 0;
    if (windowRatio > aspectRatio) {
      h = windowHeight;
      w = h * aspectRatio
    } else {
      w = windowWidth;
      h = w / aspectRatio
    }

    if (this.#canvas != null) {
      this.#canvas.style.width = w + "px";
      this.#canvas.style.height = h + "px";
    }
  }


  // Game loop
  update() {
    this.#wasm.exports.update()
  }

  draw() {
    this.#wasm.exports.draw()
  }
}