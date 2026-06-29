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
  GetLogBuffer: () => number,

  // VGA.PAS
  GetSurfacePtr: () => number,
  InitVideoMem: (width: number, height: number, startAddr: number) => void,

  // WASMHEAP.PAS
  InitHeapRegion: (startAddr: number, poolSize: number, heapSize: number) => void,
  WasmGetMem: (bytes: number) => number,

  // IMGREF.PAS
  RegisterImageRef: (imgHandle: number, dataPtr: number, width: number, height: number) => void;

  // Primary unit
  BeginIntroState: () => void,
  BeginLoadingState: () => void,
  Init: () => void,
  AfterInit: () => void,
  Update: () => void,
  Draw: () => void
};

type WasmImports = {
  env: {
    _haltproc: (n: number) => void,

    HideLoadingOverlay: () => void,
    LoadAssets: () => void,

    // Loading
    GetLoadingActual: () => number,
    GetLoadingTotal: () => number,

    HideCursor: () => void,
    ShowCursor: () => void,

    // Fullscreen
    ToggleFullscreen: () => void,
    EndFullscreen: () => void,
    GetFullscreenState: () => boolean,
    FitCanvas: () => void,

    // Keyboard
    IsKeyDown: (scancode: number) => boolean,
    SignalDone: () => void,

    // Logger
    WriteLogF32: (value: number) => void,
    WriteLogI32: (value: number) => void,
    FlushLog: () => void,

    // Mouse
    GetMouseX: () => number,
    GetMouseY: () => number,
    GetMouseButton: () => number,

    // Panic
    JsPanicHalt: (textPtr: number, textLen: number) => void,

    // Timing
    GetTimer: () => number,
    GetFullTimer: () => number,

    // VGA
    VgaUpload: () => void,
    VgaPresent: () => void
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

type Posit92Options = {
  vgaWidth: number;
  vgaHeight: number;
  renderer: "2d" | "webgl" | "experimental-webgl" | string;
};

class Posit92 {
  static version = "0.1.7";

  #wasmSource = "game.wasm";

  // Engine configs
  #wasmMemSize = 2 * 1048576;  // 2 MB
  #stackSize = 256 * 1024;
  #videoMemSize = 0;  // assigned in the constructor
  #poolSize = 512 * 1024;

  #vgaWidth: number;
  get VgaWidth(): number { return this.#vgaWidth }

  #vgaHeight: number;
  get VgaHeight(): number { return this.#vgaHeight }

  #canvas: HTMLCanvasElement;
  get Canvas(): HTMLCanvasElement {
    return this.#canvas
  }
  
  #ctx: CanvasRenderingContext2D = null!; // or WebGLRenderingContext
  get CanvasCtx(): CanvasRenderingContext2D {
    return this.#ctx
  }

  #wasm: WebAssemblyInstance = null!;
  get WasmInstance() { return this.#wasm }

  /**
   * Used in `getTimer`
   */
  #midnightOffset = 0;

  #importObject: WasmImports = {
    env: {
      _haltproc: this.#HandleHaltProc.bind(this),

      // Intro
      HideLoadingOverlay: this.HideLoadingOverlay.bind(this),
      LoadAssets: this.#LoadAssets.bind(this),

      // Loading
      GetLoadingActual: this.GetLoadingActual.bind(this),
      GetLoadingTotal: this.GetLoadingTotal.bind(this),

      HideCursor: () => this.#HideCursor(),
      ShowCursor: () => this.#ShowCursor(),

      // Fullscreen
      ToggleFullscreen: () => this.#ToggleFullscreen(),
      EndFullscreen: () => this.#EndFullscreen(),
      GetFullscreenState: () => this.#GetFullscreenState(),
      FitCanvas: () => this.#FitCanvas(),

      // Keyboard
      IsKeyDown: this.#IsKeyDown.bind(this),
      SignalDone: this.#SignalDone.bind(this),

      // Logger
      WriteLogF32: value => console.log("Pascal (f32):", value),
      WriteLogI32: value => console.log("Pascal (i32):", value),
      FlushLog: () => this.#PascalWriteLog(),

      // Mouse
      GetMouseX: () => this.#GetMouseX(),
      GetMouseY: () => this.#GetMouseY(),
      GetMouseButton: () => this.#GetMouseButton(),

      // Panic
      JsPanicHalt: this.#PanicHalt.bind(this),

      // Timing
      GetTimer: () => this.#GetTimer(),
      GetFullTimer: () => this.#GetFullTimer(),

      // VGA
      VgaUpload: () => this.#VgaUpload(),
      VgaPresent: () => this.#VgaPresent()
    }
  };

  GetWasmImportObject() {
    return this.#importObject
  }
  
  #HandleHaltProc(exitcode: number) {
    console.log("Programme halted with code:", exitcode);
    this.Cleanup();
    //@ts-ignore
    done = true
  }

  #SignalDone() {
    this.Cleanup();
    //@ts-ignore
    done = true
  }

  #NormaliseOptions(vgaWidthOrOptions?: number | Posit92Options, vgaHeight?: number): Posit92Options {
    let vgaWidth = 320;
    vgaHeight = vgaHeight ?? 240;
    let renderer = "2d";

    if (typeof vgaWidthOrOptions == "object") {
      const options = vgaWidthOrOptions;

      vgaWidth = options.vgaWidth ?? 320;
      vgaHeight = options.vgaHeight ?? 240;
      renderer = options.renderer ?? "2d";
    } else {
      vgaWidth = vgaWidthOrOptions ?? 320;
      // vgaHeight = vgaHeight;
    }

    return {
      vgaWidth,
      vgaHeight,
      renderer
    }
  }

  constructor(canvasID: string);
  constructor(canvasID: string, vgaWidth: number, vgaHeight: number);
  constructor(canvasID: string, options: Posit92Options);

  constructor(canvasID: string, vgaWidthOrOptions?: number | Posit92Options, vgaHeight?: number) {
    this.#AssertString(canvasID);

    if (document.getElementById(canvasID) == null)
      throw new Error(`Couldn't find canvasID \"${ canvasID }\"`);

    const options = this.#NormaliseOptions(vgaWidthOrOptions, vgaHeight);

    this.#canvas = <HTMLCanvasElement>document.getElementById(canvasID);
    
    this.#vgaWidth = options.vgaWidth;
    this.#vgaHeight = options.vgaHeight;

    if (options.renderer == "2d")
      this.#ctx = this.#canvas.getContext(options.renderer)!;

    this.#videoMemSize = this.#vgaWidth * this.#vgaHeight * 4
  }

  #LoadMidnightOffset() {
    const now = new Date();
    const midnight = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    this.#midnightOffset = midnight.getTime()
  }

  async #InitWebAssembly() {
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

      this.OnWasmProgress(loaded, total)
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
  OnWasmProgress(loaded: number, total: number) {
    const loadedKB = Math.ceil(loaded / 1024);

    if (isNaN(total))
      this.SetLoadingText(`Downloading engine (${ loadedKB } KB)`)
    else {
      const totalKB = Math.ceil(total / 1024);
      this.SetLoadingText(`Downloading engine (${ loadedKB } KB / ${ totalKB } KB)`)
    }
  }

  #InitWasmMemory() {
    // console.log("Default mem size", this.#wasm.exports.memory.buffer.byteLength);

    const videoMemStart = this.#stackSize;
    const heapRegionStart = this.#stackSize + this.#videoMemSize;
    const heapSize = this.#wasmMemSize - this.#poolSize - heapRegionStart;

    // Wasm memory is in 64KB pages
    const pages = this.#wasm.exports.memory.buffer.byteLength / 65536;
    const requiredPages = Math.ceil(this.#wasmMemSize / 65536);

    if (pages < requiredPages)
      this.#wasm.exports.memory.grow(requiredPages - pages);

    this.#wasm.exports.InitVideoMem(this.#vgaWidth, this.#vgaHeight, videoMemStart);
    this.#wasm.exports.InitHeapRegion(heapRegionStart, this.#poolSize, heapSize);
  }

  async Init() {
    this.#LoadMidnightOffset();

    Object.freeze(this.#importObject);
    await this.#InitWebAssembly();
    this.#InitWasmMemory();
    this.#wasm.exports.Init();

    this.#InitKeyboard();
    this.#InitMouse();
  }

  BeginIntro() {
    this.#wasm.exports.BeginIntroState()
  }

  #AddOutOfFocusFix() {
    this.#canvas.addEventListener("click", () => {
      this.#canvas.tabIndex = 0;
      this.#canvas.focus()
    })
  }

  /**
   * Called when `done` is `true`
   */
  Cleanup() {
    this.#ShowCursor();
  }

  /**
   * Overridden by the inherited `Game` class
   */
  async LoadAssets() {}

  async #LoadAssets() {
    await this.LoadAssets();
    this.AfterInit()
  }

  /**
   * Bypass intro sequence
   * 
   * Should be used **without** the intro screen
   */
  async QuickStart() {
    this.HideLoadingOverlay();

    if (Object.hasOwn(this.#wasm.exports, "beginLoadingState"))
      this.#wasm.exports.BeginLoadingState();
  }

  AfterInit() {
    this.#wasm.exports.AfterInit();
    this.#AddOutOfFocusFix();
    this.#AddResizeListener()
  }


  #HideCursor() {
    this.#canvas.style.cursor = "none"
  }

  #ShowCursor() {
    this.#canvas.style.removeProperty("cursor")
  }

  #AssertNumber(value: any) {
    if (typeof value != "number")
      throw new Error(`Expected a number, but received ${typeof value}`);

    if (isNaN(value))
      throw new Error("Expected a number, but received NaN");
  }

  #AssertString(value: any) {
    if (typeof value != "string")
      throw new Error(`Expected a string, but received ${typeof value}`);
  }


  async LoadImageFromURL(url: string): Promise<HTMLImageElement> {
    this.#AssertString(url);

    return new Promise((resolve, reject) => {
      const img = new Image();
      img.onload = () => resolve(img);
      img.onerror = reject;
      img.src = url
    })
  }

  // Used in loadImage
  #images: Array<ImageData | null> = [];

  async LoadImage(url: string) {
    this.#AssertString(url);

    const img = await this.LoadImageFromURL(url);

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

    // Reserve index 0
    if (this.#images.length == 0)
      this.#images.push(null);

    // Register with Wasm pointer
    const handle = this.#images.length;
    this.#images.push(null);
    // this.#images.push(imageData);  // Keep data in JS for reference

    this.#wasm.exports.RegisterImageRef(handle, wasmPtr, img.width, img.height);

    return handle
  }

  /**
   * Used in asset counter
   */
  #loadingActual = 0;
  GetLoadingActual() { return this.#loadingActual }

  /**
   * Used in asset counter
   */
  #loadingTotal = 0;
  GetLoadingTotal() { return this.#loadingTotal }

  async #LoadSingleImage(key: string, path: string) {
    return this.LoadImage(path).then(handle => {
      // On success
      this.IncLoadingActual();
      return { key, path, handle }
    })
  }

  async #LoadImageArray(key: string, paths: Array<string>) {
    const promises = paths.map((path, index) => 
      this.LoadImage(path).then(handle => {
        // On success
        this.IncLoadingActual();
        return { key, path, handle, index }
      })
    );

    return Promise.all(promises)
  }

  /**
   * Load images from manifest in parallel
   * 
   * The setter must have this pattern: `"SetImg" + "[AssetName]"` in camelCase
   * 
   * For example: `SetImgCursor, SetImgHandCursor`
   * 
   * @param manifest - Key-value pairs of `"asset_key": "image_path"`
   */
  async LoadImagesFromManifest(manifest: ImageManifest) {
    const entries = Object.entries(manifest);

    const promises = entries.map(([key, pathOrArray]) =>
      Array.isArray(pathOrArray)
      ? this.#LoadImageArray(key, pathOrArray)
      : this.#LoadSingleImage(key, pathOrArray)
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
      
      const setterName = `SetImg${caps}`;

      if (typeof this.WasmInstance.exports[setterName] != "function")
        console.error("loadAssetsFromManifest: Missing setter", setterName, "for the asset key", key)
      else {
        if (index == null)
          //@ts-ignore
          this.WasmInstance.exports[setterName](handle);
        else
          //@ts-ignore
          this.WasmInstance.exports[setterName](handle, index);
      }
    }
  }

  async LoadBMFontFromManifest(manifest: BMFontManifest) {
    const entries = Object.entries(manifest);
    // console.log(entries);

    const promises = entries.map(([key, params]) => {
      const setter = this.WasmInstance.exports[params.setter];

      if (typeof setter != "function") {
        console.error("loadBMFontFromManifest: Missing setter", setter);
        return { key, setterPtr: 0 }
      }

      const glyphSetter = this.WasmInstance.exports[params.glyphSetter];

      if (typeof glyphSetter != "function") {
        console.error("loadBMFontFromManifest: Missing glyphSetter", params.glyphSetter);
        return { key, glyphSetterPtr: 0 }
      }

      const [setterPtr, glyphSetterPtr] = [setter(), glyphSetter()];

      return this.LoadBMFont(params.path, setterPtr, glyphSetterPtr).then(() => {
        // On success
        this.IncLoadingActual();
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

  get LoadingProgress() {
    return {
      actual: this.#loadingActual,
      total: this.#loadingTotal
    }
  }

  IncLoadingActual() {
    this.#loadingActual++
  }

  SetLoadingActual(value: number) {
    this.#AssertNumber(value);
    this.#loadingActual = value
  }

  IncLoadingTotal(count: number) {
    this.#loadingTotal += count
  }

  SetLoadingTotal(value: number) {
    this.#AssertNumber(value);
    this.#loadingTotal = value
  }

  SetLoadingText(text: string) {
    const div = document.querySelector("#loading-overlay > div");
    if (div == null) return;
    div.innerHTML = text;
  }

  HideLoadingOverlay() {
    const div = document.getElementById("loading-overlay");
    if (div == null) return;
    div.classList.add("hidden");
    this.SetLoadingText("");
  }

  async Sleep(ms: number) {
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

  InitLoadingScreen() {
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
    
    this.SetLoadingActual(0);
    this.SetLoadingTotal(imageCount + soundCount + bmfontCount);
  }


  // BMFONT.PAS
  #NewBMFontGlyph(): TBMFontGlyph {
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

  async LoadBMFont(url: string, fontPtrRef: number, fontGlyphsPtrRef: number) {
    this.#AssertString(url);
    this.#AssertNumber(fontPtrRef);
    this.#AssertNumber(fontGlyphsPtrRef);

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
    let spacing = [0, 0];

    for (const line of lines) {
      txtLine = line.replaceAll(/\s+/g, " ");
      
      pairs = txtLine.split(" ").map(part => <StringPair>part.split("="));

      if (txtLine.startsWith("info")) {
        // [k, v] = <StringPair>(pairs.find(pair => pair[0] == "face"));

        for (const [k, v] of pairs) {
          switch (k) {
            case "face":
              const result = txtLine.match(/face=\"(.*?)\"/);
              fontface = result?.[1] ?? "";

              console.log("Loading BMFont", fontface);
              break;

            case "spacing":
              const [x, y] = v.split(",").map(s => Number(s));

              // console.log("spacing", x, y);
              spacing[0] = x;
              spacing[1] = y;
          }
        }


      } else if (txtLine.startsWith("common")) {
        [k, v] = <StringPair>(pairs.find(pair => pair[0] == "lineHeight"));
        lineHeight = parseInt(v);

      } else if (txtLine.startsWith("page")) {
        [k, v] = <StringPair>(pairs.find(pair => pair[0] == "file"));
        filename = v.replaceAll(/"/g, "");

      } else if (txtLine.startsWith("char") && !txtLine.startsWith("chars")) {
        const tempGlyph = this.#NewBMFontGlyph();

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
    imgHandle = await this.LoadImage(filename);

    const fontPtr = fontPtrRef;
    const glyphsPtr = fontGlyphsPtrRef;

    // Load TBMFont
    const fontMem = new DataView(this.#wasm.exports.memory.buffer, fontPtr);

    let offset = 0;
    offset += 16;  // Skip fontface string
    offset += 64;  // Skip filename string

    // true makes it little-endian
    fontMem.setUint16(offset, lineHeight, true);
    fontMem.setUint8(offset + 2, spacing[0]);
    fontMem.setUint8(offset + 3, spacing[1]);
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

  /**
   * JS KeyboardEvent.code to DOS scancode
   */
  ScancodeMap: Record<string, number> = {
    "Escape": 0x01,
    "Digit1": 0x02,
    "Digit2": 0x03,
    "Digit3": 0x04,
    "Digit4": 0x05,
    "Digit5": 0x06,
    "Digit6": 0x07,
    "Digit7": 0x08,
    "Digit8": 0x09,
    "Digit9": 0x0A,
    "Digit0": 0x0B,
    "Minus": 0x0C,
    "Equal": 0x0D,
    "Backspace": 0x0E,
    "Tab": 0x0F,
    "KeyQ": 0x10,
    "KeyW": 0x11,
    "KeyE": 0x12,
    "KeyR": 0x13,
    "KeyT": 0x14,
    "KeyY": 0x15,
    "KeyU": 0x16,
    "KeyI": 0x17,
    "KeyO": 0x18,
    "KeyP": 0x19,
    "BracketLeft": 0x1A,
    "BracketRight":  0x1B,
    "Enter": 0x1C,
    "ControlLeft": 0x1D,
    "KeyA": 0x1E,
    "KeyS": 0x1F,
    "KeyD": 0x20,
    "KeyF": 0x21,
    "KeyG": 0x22,
    "KeyH": 0x23,
    "KeyJ": 0x24,
    "KeyK": 0x25,
    "KeyL": 0x26,
    "Semicolon": 0x27,
    "Quote": 0x28,
    "Backquote": 0x29,
    "ShiftLeft": 0x2A,
    "Backslash": 0x2B,
    "KeyZ": 0x2C,
    "KeyX": 0x2D,
    "KeyC": 0x2E,
    "KeyV": 0x2F,
    "KeyB": 0x30,
    "KeyN": 0x31,
    "KeyM": 0x32,
    "Comma": 0x33,
    "Period": 0x34,
    "Slash": 0x35,
    "ShiftRight": 0x36,
    "AltLeft": 0x38,
    "Space": 0x39,
    "CapsLock": 0x3A,

    "F1": 0x3B,
    "F2": 0x3C,
    "F3": 0x3D,
    "F4": 0x3E,
    // "F5": 0x3F,
    "F6": 0x40,
    "F7": 0x41,
    "F8": 0x42,
    "F9": 0x43,
    "F10": 0x44,
    "F11": 0x57,
    "F12": 0x58,

    "NumLock": 0x45,
    "ScrollLock": 0x46,

    // NumLock OFF
    "Home": 0x47,
    "ArrowUp": 0x48,
    "PageUp": 0x49,
    "ArrowLeft": 0x4B,
    "ArrowRight": 0x4D,
    "End": 0x4F,
    "ArrowDown": 0x50,
    "PageDown": 0x51,
    "Insert": 0x52,
    "Delete": 0x53,

    // NumLock ON
    "Numpad7": 0x47,
    "Numpad8": 0x48,
    "Numpad9": 0x49,
    "NumpadSubtract":0x4A,
    "Numpad4": 0x4B,
    "Numpad5": 0x4C,
    "Numpad6": 0x4D,
    "NumpadAdd": 0x4E,
    "Numpad1": 0x4F,
    "Numpad2": 0x50,
    "Numpad3": 0x51,
    "Numpad0": 0x52,
    "NumpadDecimal": 0x53,
  };

  heldScancodes = new Set();

  #InitKeyboard() {
    if (this.ScancodeMap == null) {
      console.warn("Missing ScancodeMap in " + this.constructor.name);
      return
    }

    window.addEventListener("keydown", e => {
      if (e.repeat) return;

      const scancode = this.ScancodeMap[e.code];
      if (scancode) {
        this.heldScancodes.add(scancode);
        e.preventDefault();
      }
    })

    window.addEventListener("keyup", e => {
      const scancode = this.ScancodeMap[e.code];
      if (scancode) this.heldScancodes.delete(scancode)
    })
  }

  #IsKeyDown(scancode: number) {
    return this.heldScancodes.has(scancode)
  }


  // MOUSE.PAS
  #mouseX = 0;
  #mouseY = 0;
  #mouseButton = 0;

  #leftButtonDown = false;
  #rightButtonDown = false;

  #InitMouse() {
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
      this.#UpdateMouseButton();
      e.preventDefault();  // Prevent context menu on right click
    });

    this.#canvas.addEventListener("mouseup", e => {
      if (e.button == 0) this.#leftButtonDown = false;
      if (e.button == 2) this.#rightButtonDown = false;
      this.#UpdateMouseButton();
    });

    this.#canvas.addEventListener("contextmenu", e => {
      e.preventDefault()
    });

    // Handle touch events
    this.#canvas.addEventListener("touchmove", e => {
      const touch = e.touches[0];

      const rect = this.#canvas.getBoundingClientRect();
      const scaleX = this.#canvas.width / rect.width;
      const scaleY = this.#canvas.height / rect.height;

      this.#mouseX = Math.floor((touch.clientX - rect.left) * scaleX);
      this.#mouseY = Math.floor((touch.clientY - rect.top) * scaleY);

      //@ts-ignore
      e.preventDefault({ passive: false });
    });

    this.#canvas.addEventListener("touchstart", e => {
      // Similar to touchmove but with #leftButtonDown assignment
      const touch = e.touches[0];

      const rect = this.#canvas.getBoundingClientRect();
      const scaleX = this.#canvas.width / rect.width;
      const scaleY = this.#canvas.height / rect.height;

      this.#mouseX = Math.floor((touch.clientX - rect.left) * scaleX);
      this.#mouseY = Math.floor((touch.clientY - rect.top) * scaleY);

      this.#leftButtonDown = true;
      this.#UpdateMouseButton();

      //@ts-ignore
      e.preventDefault({ passive: false });
    });

    this.#canvas.addEventListener("touchend", e => {
      this.#leftButtonDown = false;
      this.#UpdateMouseButton();

      //@ts-ignore
      e.preventDefault({ passive: false });
    });
  }

  #GetMouseX() { return this.#mouseX }
  #GetMouseY() { return this.#mouseY }
  #GetMouseButton() { return this.#mouseButton }

  #UpdateMouseButton() {
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
  #PascalWriteLog() {
    const bufferPtr = this.#wasm.exports.GetLogBuffer();
    const buffer = new Uint8Array(this.#wasm.exports.memory.buffer, bufferPtr, 256);

    const len = buffer[0];
    const msgBytes = buffer.slice(1, 1 + len);
    const msg = new TextDecoder().decode(msgBytes);

    console.log("Pascal:", msg);
  }


  // PANIC.PAS
  #PanicHalt(textPtr: number, textLen: number) {
    const buffer = new Uint8Array(this.#wasm.exports.memory.buffer, textPtr, textLen);
    const msg = new TextDecoder().decode(buffer);

    //@ts-ignore
    done = true;
    this.Cleanup();

    throw new Error(`PANIC: ${msg}`)
  }


  // TIMING.PAS
  #GetTimer() {
    return (Date.now() - this.#midnightOffset) / 1000
  }

  #GetFullTimer() {
    return Date.now() / 1000
  }


  // VGA.PAS
  // flush() { this.#vgaFlush() }
  #surface: ImageData = null!;

  #VgaUpload() {
    const surfacePtr = this.#wasm.exports.GetSurfacePtr();
    const imageData = new Uint8ClampedArray(
      this.#wasm.exports.memory.buffer,
      surfacePtr,
      this.#vgaWidth * this.#vgaHeight * 4
    );

    this.#surface = new ImageData(imageData, this.#vgaWidth, this.#vgaHeight);
  }
  
  #VgaPresent() {
    this.#ctx.putImageData(this.#surface, 0, 0);
  }

  // Fullscreen.pas
  #AddResizeListener() {
    window.addEventListener("resize", this.#HandleResize.bind(this))
  }

  #GetFullscreenState() {
    return document.fullscreenElement != null
  }

  #ToggleFullscreen() {
    if (!this.#GetFullscreenState())
      this.#canvas.requestFullscreen()
    else
      document.exitFullscreen();
  }

  #EndFullscreen() {
    if (this.#GetFullscreenState())
      document.exitFullscreen();
  }

  #HandleResize() {
    this.#FitCanvas()
  }

  #FitCanvas() {
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
  Update() { this.#wasm.exports.Update() }
  Draw() { this.#wasm.exports.Draw() }
}