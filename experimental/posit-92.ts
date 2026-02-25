"use strict";

type ImageManifest = Record<string, string | string[]>;
type SoundManifest = Map<number, string>;
type BMFontManifest = Map<string, { path: string, setter: string, glyphSetter: string }>;

/**
 * The type definitions here are copied from Pascal except for `memory`
 */
type WasmExports = {
  memory: WebAssembly.Memory,

  // LOGGER.PAS
  getLogBuffer: () => number,

  // VGA.PAS
  getSurfacePtr: () => number,
  initVideoMem: (width: number, height: number, startAddr: number) => void,
  initHeap: (startAddr: number, heapSize: number) => void,
  WasmGetMem: (bytes: number) => number,

  // IMGREF.PAS
  registerImageRef: (imgHandle: number, dataPtr: number, width: number, height: number) => void;

  // Primary unit
  beginIntroState: () => void,
  beginLoadingState: () => void,
  init: () => void,
  afterInit: () => void,
  update: () => void,
  draw: () => void
};

type WasmImports = {
  env: {
    _haltproc: (n: number) => void,

    hideLoadingOverlay: () => void,
    loadAssets: () => void,

    // Loading
    getLoadingActual: () => number,
    getLoadingTotal: () => number,

    hideCursor: () => void,
    showCursor: () => void,

    // Fullscreen
    toggleFullscreen: () => void,
    endFullscreen: () => void,
    getFullscreenState: () => boolean,
    fitCanvas: () => void,

    // Keyboard
    isKeyDown: (scancode: number) => boolean,
    signalDone: () => void,

    // Logger
    writeLogF32: (value: number) => void,
    writeLogI32: (value: number) => void,
    flushLog: () => void,

    // Mouse
    getMouseX: () => number,
    getMouseY: () => number,
    getMouseButton: () => number,

    // Panic
    jsPanicHalt: (textPtr: number, textLen: number) => void,

    // Timing
    getTimer: () => number,
    getFullTimer: () => number,

    // VGA
    vgaFlush: () => void
  }
}

type StringPair = [string, string];

type WebAssemblyInstance = WebAssembly.Instance & { exports: WasmExports };

type TBMFontGlyph = {
  id: number,
  x: number,
  y: number,
  width: number,
  height: number,
  xoffset: number,
  yoffset: number,
  xadvance: number,
  lineHeight: number
}

class Posit92 {
  static version = "0.1.4_experimental";

  #wasmSource = "game.wasm";

  // Engine configs
  #wasmMemSize = 2 * 1048576; // 2 MB
  #stackSize = 128 * 1024;
  #videoMemSize = 0;
  #poolSize = 512 * 1024;

  #vgaWidth: number;
  #vgaHeight: number;

  #canvas: HTMLCanvasElement;
  #ctx: CanvasRenderingContext2D;

  #wasm: WebAssemblyInstance = null!;
  get wasmInstance() { return this.#wasm }

  /**
   * Used in `getTimer`
   */
  #midnightOffset = 0;

  #importObject: WasmImports = {
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
      jsPanicHalt: this.#panicHalt.bind(this),

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
  
  #handleHaltProc(exitcode: number) {
    console.log("Programme halted with code:", exitcode);
    this.cleanup();
    //@ts-ignore
    done = true
  }

  #signalDone() {
    this.cleanup();
    //@ts-ignore
    done = true
  }

  constructor(canvasID: string, vgaWidth = 320, vgaHeight = 200) {
    this.#assertString(canvasID);
    this.#assertNumber(vgaWidth);
    this.#assertNumber(vgaHeight);

    if (document.getElementById(canvasID) == null)
      throw new Error(`Couldn't find canvasID \"${ canvasID }\"`);

    this.#canvas = <HTMLCanvasElement>document.getElementById(canvasID);
    this.#ctx = this.#canvas.getContext("2d")!;

    this.#vgaWidth = vgaWidth;
    this.#vgaHeight = vgaHeight;

    this.#videoMemSize = this.#vgaWidth * this.#vgaHeight * 4
  }

  #loadMidnightOffset() {
    const now = new Date();
    const midnight = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    this.#midnightOffset = midnight.getTime()
  }

  async #initWebAssembly() {
    const response = await fetch(this.#wasmSource);

    const contentLength =
      response.headers.get("x-goog-stored-content-length")
      ?? response.headers.get("content-length");

    // in bytes:
    const total = Number(contentLength);
    let loaded = 0;

    if (response.body == null)
      throw new Error("Missing response.body");

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
    this.#wasm = <WebAssemblyInstance>result.instance;
  }

  /**
   * @param loaded in bytes
   * @param total in bytes
   */
  onWasmProgress(loaded: number, total: number) {
    const loadedKB = Math.ceil(loaded / 1024);

    if (isNaN(total))
      this.setLoadingText(`Downloading engine (${ loadedKB } KB)`)
    else {
      const totalKB = Math.ceil(total / 1024);
      this.setLoadingText(`Downloading engine (${ loadedKB } KB / ${ totalKB } KB)`)
    }
  }

  #initWasmMemory() {
    // console.log("Default mem size", this.#wasm.exports.memory.buffer.byteLength);

    const videoMemStart = this.#stackSize;
    const heapRegionStart = this.#stackSize + this.#videoMemSize;
    const heapSize = this.#wasmMemSize - this.#poolSize - heapRegionStart;

    // Wasm memory is in 64KB pages
    const pages = this.#wasm.exports.memory.buffer.byteLength / 65536;
    const requiredPages = Math.ceil(this.#wasmMemSize / 65536);

    if (pages < requiredPages)
      this.#wasm.exports.memory.grow(requiredPages - pages);

    this.#wasm.exports.initVideoMem(this.#vgaWidth, this.#vgaHeight, videoMemStart);
    this.#wasm.exports.initHeap(heapRegionStart, this.#poolSize, heapSize);
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
  }

  afterInit() {
    this.#wasm.exports.afterInit();
    this.#addOutOfFocusFix();
    this.#addResizeListener()
  }


  #hideCursor() {
    this.#canvas.style.cursor = "none"
  }

  #showCursor() {
    this.#canvas.style.removeProperty("cursor")
  }

  #assertNumber(value: any) {
    if (typeof value != "number")
      throw new Error(`Expected a number, but received ${typeof value}`);

    if (isNaN(value))
      throw new Error("Expected a number, but received NaN");
  }

  #assertString(value: any) {
    if (typeof value != "string")
      throw new Error(`Expected a string, but received ${typeof value}`);
  }


  async loadImageFromURL(url: string): Promise<HTMLImageElement> {
    this.#assertString(url);

    return new Promise((resolve, reject) => {
      const img = new Image();
      img.onload = () => resolve(img);
      img.onerror = reject;
      img.src = url
    })
  }

  // Used in loadImage
  #images: Array<ImageData | null> = [];

  async loadImage(url: string) {
    this.#assertString(url);

    const img = await this.loadImageFromURL(url);

    // Copy image
    const tempCanvas = document.createElement("canvas");
    tempCanvas.width = img.width;
    tempCanvas.height = img.height;
    
    const tempCtx = tempCanvas.getContext("2d");
    if (tempCtx == null)
      throw new Error("Error getting 2D canvas context");

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

  async #loadSingleImage(key: string, path: string) {
    return this.loadImage(path).then(handle => {
      // On success
      this.incLoadingActual();
      return { key, path, handle }
    })
  }

  async #loadImageArray(key: string, paths: Array<string>) {
    const promises = paths.map((path, index) => 
      this.loadImage(path).then(handle => {
        // On success
        this.incLoadingActual();
        return { key, path, handle, index }
      })
    );

    return Promise.all(promises)
  }

  /**
   * Load images from manifest in parallel
   * 
   * The setter must have this pattern: `"setImg" + "[AssetName]"` in camelCase
   * 
   * For example: `setImgCursor, setImgHandCursor`
   * 
   * @param manifest - Key-value pairs of `"asset_key": "image_path"`
   */
  async loadImagesFromManifest(manifest: ImageManifest) {
    const entries = Object.entries(manifest);

    const promises = entries.map(([key, pathOrArray]) =>
      Array.isArray(pathOrArray)
      ? this.#loadImageArray(key, pathOrArray)
      : this.#loadSingleImage(key, pathOrArray)
    );

    const results = await Promise.all(promises);

    type FailureItem = {
      key: string,
      path: string,
      handle: number,
      index?: number
    };
    const failures = <Array<FailureItem>>results.flat(1).filter(item => item.handle == 0);

    if (failures.length > 0) {
      console.error("Failed to load assets:");
      
      for (const failure of failures)
        console.error("   " + failure.key + ": " + failure.path);

      throw new Error("Failed to load some assets")
    }

    for (const item of results.flat(1)) {
      type ResultItem = { key: string, handle: number, index?: number };
      const { key, handle, index } = <ResultItem>item;
      
      const caps = key
        .replace(/^./, _ => _.toUpperCase())
        .replace(/_(.)/g, (_, g1) => g1.toUpperCase());
      const setterName = `setImg${caps}`;

      if (typeof this.wasmInstance.exports[setterName] != "function")
        console.error("loadAssetsFromManifest: Missing setter", setterName, "for the asset key", key)
      else {
        if (index == null)
          //@ts-ignore
          this.wasmInstance.exports[setterName](handle);
        else
          //@ts-ignore
          this.wasmInstance.exports[setterName](handle, index);
      }
    }
  }

  async loadBMFontFromManifest(manifest: BMFontManifest) {
    const entries = Object.entries(manifest);
    // console.log(entries);

    const promises = entries.map(([key, params]) => {
      const setter = this.wasmInstance.exports[params.setter];

      if (typeof setter != "function") {
        console.error("loadBMFontFromManifest: Missing setter", setter);
        return { key, setterPtr: 0 }
      }

      const glyphSetter = this.wasmInstance.exports[params.glyphSetter];

      if (typeof glyphSetter != "function") {
        console.error("loadBMFontFromManifest: Missing glyphSetter", params.glyphSetter);
        return { key, glyphSetterPtr: 0 }
      }

      const [setterPtr, glyphSetterPtr] = [setter(), glyphSetter()];

      return this.loadBMFont(params.path, setterPtr, glyphSetterPtr).then(() => {
        // On success
        this.incLoadingActual();
        return { key, path: params.path, setterPtr, glyphSetterPtr }
      })
    });

    const results = await Promise.all(promises);

    // console.log("BMFont results", results);

    const failures = results.filter(item => item.setterPtr == 0 || item.glyphSetterPtr == 0);

    if (failures.length > 0) {
      console.error(
        "Failed to load assets:",
        failures.map(item => item.key).join(", "));
      
      throw new Error("Failed to load some assets")
    }

    for (const item of results) ;
  }

  get loadingProgress() {
    return {
      actual: this.#loadingActual,
      total: this.#loadingTotal
    }
  }

  incLoadingActual() {
    this.#loadingActual++
  }

  setLoadingActual(value: number) {
    this.#assertNumber(value);
    this.#loadingActual = value
  }

  incLoadingTotal(count: number) {
    this.#loadingTotal += count
  }

  setLoadingTotal(value: number) {
    this.#assertNumber(value);
    this.#loadingTotal = value
  }

  setLoadingText(text: string) {
    const div = document.querySelector("#loading-overlay > div");
    if (div == null) return;
    div.innerHTML = text;
  }

  hideLoadingOverlay() {
    const div = document.getElementById("loading-overlay");
    if (div == null) return;
    div.classList.add("hidden");
    this.setLoadingText("");
  }

  async sleep(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  /**
   * Overridable from `game.js`
   */
  AssetManifest: {
    images?: ImageManifest,
    sounds?: SoundManifest,
    bmfonts?: BMFontManifest
  } | null = null;

  initLoadingScreen() {
    if (this.AssetManifest == null) {
      console.warn("Missing AssetManifest in " + this.constructor.name);
      return
    }

    const imageCount = this.AssetManifest.images != null
      ? Object.keys(this.AssetManifest.images).length
      : 0;
    const soundCount = this.AssetManifest.sounds != null
      ? this.AssetManifest.sounds.size
      : 0;
    const bmfontCount = this.AssetManifest.bmfonts != null
      ? Object.keys(this.AssetManifest.bmfonts).length
      : 0;
    
    this.setLoadingActual(0);
    this.setLoadingTotal(imageCount + soundCount + bmfontCount);
  }


  // BMFONT.PAS
  #newBMFontGlyph(): TBMFontGlyph {
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

  async loadBMFont(url: string, fontPtrRef: number, fontGlyphsPtrRef: number) {
    this.#assertString(url);
    this.#assertNumber(fontPtrRef);
    this.#assertNumber(fontGlyphsPtrRef);

    const res = await fetch(url);
    const text = await res.text();

    const lines = text.endsWith("\r\n") ? text.split("\r\n") : text.split("\n");

    let txtLine = "";
    let pairs: Array<StringPair>;
    let k = "", v = "";

    let fontface = "";
    let filename = "";
    let lineHeight = 0;

    const fontGlyphs: Map<number, TBMFontGlyph> = new Map();
    let glyphCount = 0;
    let imgHandle = 0;

    for (const line of lines) {
      txtLine = line.replaceAll(/\s+/g, " ");
      
      pairs = txtLine.split(" ").map(part => <StringPair>part.split("="));

      if (txtLine.startsWith("info")) {
        // [k, v] = <StringPair>(pairs.find(pair => pair[0] == "face"));

        const result = txtLine.match(/face=\"(.*?)\"/);
        fontface = result?.[1] ?? "";

        console.log("Loading BMFont", fontface);

      } else if (txtLine.startsWith("common")) {
        [k, v] = <StringPair>(pairs.find(pair => pair[0] == "lineHeight"));
        lineHeight = parseInt(v);

      } else if (txtLine.startsWith("page")) {
        [k, v] = <StringPair>(pairs.find(pair => pair[0] == "file"));
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

        fontGlyphs.set(tempGlyph.id, tempGlyph);
        glyphCount++
      }
    }

    console.log("Loaded", glyphCount, "glyphs");

    // Load font bitmap
    imgHandle = await this.loadImage(filename);

    const fontPtr = fontPtrRef;
    const glyphsPtr = fontGlyphsPtrRef;

    // Load TBMFont
    const fontMem = new DataView(this.#wasm.exports.memory.buffer, fontPtr);

    let offset = 0;
    offset += 16;  // Skip fontface string
    offset += 64;  // Skip filename string

    // true makes it little-endian
    fontMem.setUint16(offset, lineHeight, true);
    fontMem.setInt32(offset + 4, imgHandle, true);

    // Load glyphs
    const glyphsMem = new DataView(this.#wasm.exports.memory.buffer, glyphsPtr);

    for (const charID of fontGlyphs.keys()) {
      const glyph = fontGlyphs.get(charID)!;

      // Range check
      if (charID < 32 || charID > 126) continue;

      // 16 is from the 8 fields of TBMFontGlyph, all 2 bytes
      const glyphOffset = (charID - 32) * 16;

      glyphsMem.setUint16(glyphOffset + 0, glyph.id, true);

      glyphsMem.setUint16(glyphOffset + 2, glyph.x, true);
      glyphsMem.setUint16(glyphOffset + 4, glyph.y, true);
      glyphsMem.setUint16(glyphOffset + 6, glyph.width, true);
      glyphsMem.setUint16(glyphOffset + 8, glyph.height, true);

      glyphsMem.setInt16(glyphOffset + 10, glyph.xoffset, true);
      glyphsMem.setInt16(glyphOffset + 12, glyph.yoffset, true);
      glyphsMem.setInt16(glyphOffset + 14, glyph.xadvance, true);
    }

    console.log("loadBMFont", fontface, "completed");
  }


  // KEYBOARD.PAS
  ScancodeMap: Record<string, number> = null!;
  heldScancodes = new Set();

  #initKeyboard() {
    if (this.ScancodeMap == null) {
      console.warn("Missing ScancodeMap in " + this.constructor.name);
      return
    }

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

  #isKeyDown(scancode: number) {
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
  #panicHalt(textPtr: number, textLen: number) {
    const buffer = new Uint8Array(this.#wasm.exports.memory.buffer, textPtr, textLen);
    const msg = new TextDecoder().decode(buffer);

    //@ts-ignore
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
  #addResizeListener() {
    window.addEventListener("resize", this.#handleResize.bind(this))
  }

  #getFullscreenState() {
    return document.fullscreenElement != null
  }

  #toggleFullscreen() {
    if (!this.#getFullscreenState())
      this.#canvas.requestFullscreen()
    else
      document.exitFullscreen();
  }

  #endFullscreen() {
    if (this.#getFullscreenState())
      document.exitFullscreen();
  }

  #handleResize() {
    this.#fitCanvas()
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
  update() { this.#wasm.exports.update() }
  draw() { this.#wasm.exports.draw() }
}