// posit-92.ts
class Posit92 {
  static version = "0.1.6_experimental";
  #wasmSource = "game.wasm";
  #wasmMemSize = 2 * 1048576;
  #stackSize = 256 * 1024;
  #videoMemSize = 0;
  #poolSize = 512 * 1024;
  #vgaWidth;
  get VgaWidth() {
    return this.#vgaWidth;
  }
  #vgaHeight;
  get VgaHeight() {
    return this.#vgaHeight;
  }
  #canvas;
  get Canvas() {
    return this.#canvas;
  }
  #ctx;
  get CanvasCtx() {
    return this.#ctx;
  }
  #wasm = null;
  get WasmInstance() {
    return this.#wasm;
  }
  #midnightOffset = 0;
  #importObject = {
    env: {
      _haltproc: this.#HandleHaltProc.bind(this),
      HideLoadingOverlay: this.HideLoadingOverlay.bind(this),
      LoadAssets: this.#LoadAssets.bind(this),
      GetLoadingActual: this.GetLoadingActual.bind(this),
      GetLoadingTotal: this.GetLoadingTotal.bind(this),
      HideCursor: () => this.#HideCursor(),
      ShowCursor: () => this.#ShowCursor(),
      ToggleFullscreen: () => this.#ToggleFullscreen(),
      EndFullscreen: () => this.#EndFullscreen(),
      GetFullscreenState: () => this.#GetFullscreenState(),
      FitCanvas: () => this.#FitCanvas(),
      IsKeyDown: this.#IsKeyDown.bind(this),
      SignalDone: this.#SignalDone.bind(this),
      WriteLogF32: (value) => console.log("Pascal (f32):", value),
      WriteLogI32: (value) => console.log("Pascal (i32):", value),
      FlushLog: () => this.#PascalWriteLog(),
      GetMouseX: () => this.#GetMouseX(),
      GetMouseY: () => this.#GetMouseY(),
      GetMouseButton: () => this.#GetMouseButton(),
      JsPanicHalt: this.#PanicHalt.bind(this),
      GetTimer: () => this.#GetTimer(),
      GetFullTimer: () => this.#GetFullTimer(),
      VgaUpload: () => this.#VgaUpload(),
      VgaPresent: () => this.#VgaPresent()
    }
  };
  GetWasmImportObject() {
    return this.#importObject;
  }
  #HandleHaltProc(exitcode) {
    console.log("Programme halted with code:", exitcode);
    this.Cleanup();
    done = true;
  }
  #SignalDone() {
    this.Cleanup();
    done = true;
  }
  constructor(canvasID, vgaWidth = 320, vgaHeight = 200) {
    this.#AssertString(canvasID);
    this.#AssertNumber(vgaWidth);
    this.#AssertNumber(vgaHeight);
    if (document.getElementById(canvasID) == null)
      throw new Error(`Couldn't find canvasID "${canvasID}"`);
    this.#canvas = document.getElementById(canvasID);
    this.#ctx = this.#canvas.getContext("2d");
    this.#vgaWidth = vgaWidth;
    this.#vgaHeight = vgaHeight;
    this.#videoMemSize = this.#vgaWidth * this.#vgaHeight * 4;
  }
  #LoadMidnightOffset() {
    const now = new Date;
    const midnight = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    this.#midnightOffset = midnight.getTime();
  }
  async#InitWebAssembly() {
    const response = await fetch(this.#wasmSource);
    const contentLength = response.headers.get("x-goog-stored-content-length") ?? response.headers.get("content-length");
    const total = Number(contentLength);
    let loaded = 0;
    if (response.body == null)
      throw new Error("Missing response.body");
    const reader = response.body.getReader();
    const chunks = [];
    while (true) {
      const { done: done2, value } = await reader.read();
      if (done2)
        break;
      chunks.push(value);
      loaded += value.length;
      this.OnWasmProgress(loaded, total);
    }
    const bytes = new Uint8Array(loaded);
    let pos = 0;
    for (const chunk of chunks) {
      bytes.set(chunk, pos);
      pos += chunk.length;
    }
    const result = await WebAssembly.instantiate(bytes.buffer, this.#importObject);
    this.#wasm = result.instance;
  }
  OnWasmProgress(loaded, total) {
    const loadedKB = Math.ceil(loaded / 1024);
    if (isNaN(total))
      this.SetLoadingText(`Downloading engine (${loadedKB} KB)`);
    else {
      const totalKB = Math.ceil(total / 1024);
      this.SetLoadingText(`Downloading engine (${loadedKB} KB / ${totalKB} KB)`);
    }
  }
  #InitWasmMemory() {
    const videoMemStart = this.#stackSize;
    const heapRegionStart = this.#stackSize + this.#videoMemSize;
    const heapSize = this.#wasmMemSize - this.#poolSize - heapRegionStart;
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
    this.#wasm.exports.BeginIntroState();
  }
  #AddOutOfFocusFix() {
    this.#canvas.addEventListener("click", () => {
      this.#canvas.tabIndex = 0;
      this.#canvas.focus();
    });
  }
  Cleanup() {
    this.#ShowCursor();
  }
  async LoadAssets() {}
  async#LoadAssets() {
    await this.LoadAssets();
    this.AfterInit();
  }
  async QuickStart() {
    this.HideLoadingOverlay();
    if (Object.hasOwn(this.#wasm.exports, "beginLoadingState"))
      this.#wasm.exports.BeginLoadingState();
  }
  AfterInit() {
    this.#wasm.exports.AfterInit();
    this.#AddOutOfFocusFix();
    this.#AddResizeListener();
  }
  #HideCursor() {
    this.#canvas.style.cursor = "none";
  }
  #ShowCursor() {
    this.#canvas.style.removeProperty("cursor");
  }
  #AssertNumber(value) {
    if (typeof value != "number")
      throw new Error(`Expected a number, but received ${typeof value}`);
    if (isNaN(value))
      throw new Error("Expected a number, but received NaN");
  }
  #AssertString(value) {
    if (typeof value != "string")
      throw new Error(`Expected a string, but received ${typeof value}`);
  }
  async LoadImageFromURL(url) {
    this.#AssertString(url);
    return new Promise((resolve, reject) => {
      const img = new Image;
      img.onload = () => resolve(img);
      img.onerror = reject;
      img.src = url;
    });
  }
  #images = [];
  async LoadImage(url) {
    this.#AssertString(url);
    const img = await this.LoadImageFromURL(url);
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
    wasmMemory.set(imageData.data, wasmPtr);
    if (this.#images.length == 0)
      this.#images.push(null);
    const handle = this.#images.length;
    this.#images.push(null);
    this.#wasm.exports.RegisterImageRef(handle, wasmPtr, img.width, img.height);
    return handle;
  }
  #loadingActual = 0;
  GetLoadingActual() {
    return this.#loadingActual;
  }
  #loadingTotal = 0;
  GetLoadingTotal() {
    return this.#loadingTotal;
  }
  async#LoadSingleImage(key, path) {
    return this.LoadImage(path).then((handle) => {
      this.IncLoadingActual();
      return { key, path, handle };
    });
  }
  async#LoadImageArray(key, paths) {
    const promises = paths.map((path, index) => this.LoadImage(path).then((handle) => {
      this.IncLoadingActual();
      return { key, path, handle, index };
    }));
    return Promise.all(promises);
  }
  async LoadImagesFromManifest(manifest) {
    const entries = Object.entries(manifest);
    const promises = entries.map(([key, pathOrArray]) => Array.isArray(pathOrArray) ? this.#LoadImageArray(key, pathOrArray) : this.#LoadSingleImage(key, pathOrArray));
    const results = await Promise.all(promises);
    const failures = results.flat(1).filter((item) => item.handle == 0);
    if (failures.length > 0) {
      console.error("Failed to load assets:");
      for (const failure of failures)
        console.error("   " + failure.key + ": " + failure.path);
      throw new Error("Failed to load some assets");
    }
    for (const item of results.flat(1)) {
      const { key, handle, index } = item;
      const caps = key.replace(/^./, (_) => _.toUpperCase()).replace(/_(.)/g, (_, g1) => g1.toUpperCase());
      const setterName = `SetImg${caps}`;
      if (typeof this.WasmInstance.exports[setterName] != "function")
        console.error("loadAssetsFromManifest: Missing setter", setterName, "for the asset key", key);
      else {
        if (index == null)
          this.WasmInstance.exports[setterName](handle);
        else
          this.WasmInstance.exports[setterName](handle, index);
      }
    }
  }
  async LoadBMFontFromManifest(manifest) {
    const entries = Object.entries(manifest);
    const promises = entries.map(([key, params]) => {
      const setter = this.WasmInstance.exports[params.setter];
      if (typeof setter != "function") {
        console.error("loadBMFontFromManifest: Missing setter", setter);
        return { key, setterPtr: 0 };
      }
      const glyphSetter = this.WasmInstance.exports[params.glyphSetter];
      if (typeof glyphSetter != "function") {
        console.error("loadBMFontFromManifest: Missing glyphSetter", params.glyphSetter);
        return { key, glyphSetterPtr: 0 };
      }
      const [setterPtr, glyphSetterPtr] = [setter(), glyphSetter()];
      return this.LoadBMFont(params.path, setterPtr, glyphSetterPtr).then(() => {
        this.IncLoadingActual();
        return { key, path: params.path, setterPtr, glyphSetterPtr };
      });
    });
    const results = await Promise.all(promises);
    const failures = results.filter((item) => item.setterPtr == 0 || item.glyphSetterPtr == 0);
    if (failures.length > 0) {
      console.error("Failed to load assets:", failures.map((item) => item.key).join(", "));
      throw new Error("Failed to load some assets");
    }
    for (const item of results)
      ;
  }
  get LoadingProgress() {
    return {
      actual: this.#loadingActual,
      total: this.#loadingTotal
    };
  }
  IncLoadingActual() {
    this.#loadingActual++;
  }
  SetLoadingActual(value) {
    this.#AssertNumber(value);
    this.#loadingActual = value;
  }
  IncLoadingTotal(count) {
    this.#loadingTotal += count;
  }
  SetLoadingTotal(value) {
    this.#AssertNumber(value);
    this.#loadingTotal = value;
  }
  SetLoadingText(text) {
    const div = document.querySelector("#loading-overlay > div");
    if (div == null)
      return;
    div.innerHTML = text;
  }
  HideLoadingOverlay() {
    const div = document.getElementById("loading-overlay");
    if (div == null)
      return;
    div.classList.add("hidden");
    this.SetLoadingText("");
  }
  async Sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
  AssetManifest = null;
  InitLoadingScreen() {
    if (this.AssetManifest == null) {
      console.warn("Missing AssetManifest in " + this.constructor.name);
      return;
    }
    const imageCount = this.AssetManifest.images != null ? Object.keys(this.AssetManifest.images).length : 0;
    const soundCount = this.AssetManifest.sounds != null ? this.AssetManifest.sounds.size : 0;
    const bmfontCount = this.AssetManifest.bmfonts != null ? Object.keys(this.AssetManifest.bmfonts).length : 0;
    this.SetLoadingActual(0);
    this.SetLoadingTotal(imageCount + soundCount + bmfontCount);
  }
  #NewBMFontGlyph() {
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
    };
  }
  async LoadBMFont(url, fontPtrRef, fontGlyphsPtrRef) {
    this.#AssertString(url);
    this.#AssertNumber(fontPtrRef);
    this.#AssertNumber(fontGlyphsPtrRef);
    const res = await fetch(url);
    const text = await res.text();
    const lines = text.endsWith(`\r
`) ? text.split(`\r
`) : text.split(`
`);
    let txtLine = "";
    let pairs;
    let k = "", v = "";
    let fontface = "";
    let filename = "";
    let lineHeight = 0;
    const fontGlyphs = new Map;
    let glyphCount = 0;
    let imgHandle = 0;
    let spacing = [0, 0];
    for (const line of lines) {
      txtLine = line.replaceAll(/\s+/g, " ");
      pairs = txtLine.split(" ").map((part) => part.split("="));
      if (txtLine.startsWith("info")) {
        for (const [k2, v2] of pairs) {
          switch (k2) {
            case "face":
              const result = txtLine.match(/face=\"(.*?)\"/);
              fontface = result?.[1] ?? "";
              console.log("Loading BMFont", fontface);
              break;
            case "spacing":
              const [x, y] = v2.split(",").map((s) => Number(s));
              spacing[0] = x;
              spacing[1] = y;
          }
        }
      } else if (txtLine.startsWith("common")) {
        [k, v] = pairs.find((pair) => pair[0] == "lineHeight");
        lineHeight = parseInt(v);
      } else if (txtLine.startsWith("page")) {
        [k, v] = pairs.find((pair) => pair[0] == "file");
        filename = v.replaceAll(/"/g, "");
      } else if (txtLine.startsWith("char") && !txtLine.startsWith("chars")) {
        const tempGlyph = this.#NewBMFontGlyph();
        for (const [k2, v2] of pairs) {
          switch (k2) {
            case "id":
              tempGlyph.id = parseInt(v2);
              break;
            case "x":
              tempGlyph.x = parseInt(v2);
              break;
            case "y":
              tempGlyph.y = parseInt(v2);
              break;
            case "width":
              tempGlyph.width = parseInt(v2);
              break;
            case "height":
              tempGlyph.height = parseInt(v2);
              break;
            case "xoffset":
              tempGlyph.xoffset = parseInt(v2);
              break;
            case "yoffset":
              tempGlyph.yoffset = parseInt(v2);
              break;
            case "xadvance":
              tempGlyph.xadvance = parseInt(v2);
              break;
          }
        }
        fontGlyphs.set(tempGlyph.id, tempGlyph);
        glyphCount++;
      }
    }
    console.log("Loaded", glyphCount, "glyphs");
    imgHandle = await this.LoadImage(filename);
    const fontPtr = fontPtrRef;
    const glyphsPtr = fontGlyphsPtrRef;
    const fontMem = new DataView(this.#wasm.exports.memory.buffer, fontPtr);
    let offset = 0;
    offset += 16;
    offset += 64;
    fontMem.setUint16(offset, lineHeight, true);
    fontMem.setUint8(offset + 2, spacing[0]);
    fontMem.setUint8(offset + 3, spacing[1]);
    fontMem.setInt32(offset + 4, imgHandle, true);
    const glyphsMem = new DataView(this.#wasm.exports.memory.buffer, glyphsPtr);
    for (const charID of fontGlyphs.keys()) {
      const glyph = fontGlyphs.get(charID);
      if (charID < 32 || charID > 126)
        continue;
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
  ScancodeMap = {
    Escape: 1,
    Digit1: 2,
    Digit2: 3,
    Digit3: 4,
    Digit4: 5,
    Digit5: 6,
    Digit6: 7,
    Digit7: 8,
    Digit8: 9,
    Digit9: 10,
    Digit0: 11,
    Minus: 12,
    Equal: 13,
    Backspace: 14,
    Tab: 15,
    KeyQ: 16,
    KeyW: 17,
    KeyE: 18,
    KeyR: 19,
    KeyT: 20,
    KeyY: 21,
    KeyU: 22,
    KeyI: 23,
    KeyO: 24,
    KeyP: 25,
    BracketLeft: 26,
    BracketRight: 27,
    Enter: 28,
    ControlLeft: 29,
    KeyA: 30,
    KeyS: 31,
    KeyD: 32,
    KeyF: 33,
    KeyG: 34,
    KeyH: 35,
    KeyJ: 36,
    KeyK: 37,
    KeyL: 38,
    Semicolon: 39,
    Quote: 40,
    Backquote: 41,
    ShiftLeft: 42,
    Backslash: 43,
    KeyZ: 44,
    KeyX: 45,
    KeyC: 46,
    KeyV: 47,
    KeyB: 48,
    KeyN: 49,
    KeyM: 50,
    Comma: 51,
    Period: 52,
    Slash: 53,
    ShiftRight: 54,
    AltLeft: 56,
    Space: 57,
    CapsLock: 58,
    F1: 59,
    F2: 60,
    F3: 61,
    F4: 62,
    F6: 64,
    F7: 65,
    F8: 66,
    F9: 67,
    F10: 68,
    F11: 87,
    F12: 88,
    NumLock: 69,
    ScrollLock: 70,
    Home: 71,
    ArrowUp: 72,
    PageUp: 73,
    ArrowLeft: 75,
    ArrowRight: 77,
    End: 79,
    ArrowDown: 80,
    PageDown: 81,
    Insert: 82,
    Delete: 83,
    Numpad7: 71,
    Numpad8: 72,
    Numpad9: 73,
    NumpadSubtract: 74,
    Numpad4: 75,
    Numpad5: 76,
    Numpad6: 77,
    NumpadAdd: 78,
    Numpad1: 79,
    Numpad2: 80,
    Numpad3: 81,
    Numpad0: 82,
    NumpadDecimal: 83
  };
  heldScancodes = new Set;
  #InitKeyboard() {
    if (this.ScancodeMap == null) {
      console.warn("Missing ScancodeMap in " + this.constructor.name);
      return;
    }
    window.addEventListener("keydown", (e) => {
      if (e.repeat)
        return;
      const scancode = this.ScancodeMap[e.code];
      if (scancode) {
        this.heldScancodes.add(scancode);
        e.preventDefault();
      }
    });
    window.addEventListener("keyup", (e) => {
      const scancode = this.ScancodeMap[e.code];
      if (scancode)
        this.heldScancodes.delete(scancode);
    });
  }
  #IsKeyDown(scancode) {
    return this.heldScancodes.has(scancode);
  }
  #mouseX = 0;
  #mouseY = 0;
  #mouseButton = 0;
  #leftButtonDown = false;
  #rightButtonDown = false;
  #InitMouse() {
    this.#canvas.addEventListener("mousemove", (e) => {
      const rect = this.#canvas.getBoundingClientRect();
      const scaleX = this.#canvas.width / rect.width;
      const scaleY = this.#canvas.height / rect.height;
      this.#mouseX = Math.floor((e.clientX - rect.left) * scaleX);
      this.#mouseY = Math.floor((e.clientY - rect.top) * scaleY);
    });
    this.#canvas.addEventListener("mousedown", (e) => {
      if (e.button == 0)
        this.#leftButtonDown = true;
      if (e.button == 2)
        this.#rightButtonDown = true;
      this.#UpdateMouseButton();
      e.preventDefault();
    });
    this.#canvas.addEventListener("mouseup", (e) => {
      if (e.button == 0)
        this.#leftButtonDown = false;
      if (e.button == 2)
        this.#rightButtonDown = false;
      this.#UpdateMouseButton();
    });
    this.#canvas.addEventListener("contextmenu", (e) => {
      e.preventDefault();
    });
    this.#canvas.addEventListener("touchmove", (e) => {
      const touch = e.touches[0];
      const rect = this.#canvas.getBoundingClientRect();
      const scaleX = this.#canvas.width / rect.width;
      const scaleY = this.#canvas.height / rect.height;
      this.#mouseX = Math.floor((touch.clientX - rect.left) * scaleX);
      this.#mouseY = Math.floor((touch.clientY - rect.top) * scaleY);
      e.preventDefault();
    });
    this.#canvas.addEventListener("touchstart", (e) => {
      const touch = e.touches[0];
      const rect = this.#canvas.getBoundingClientRect();
      const scaleX = this.#canvas.width / rect.width;
      const scaleY = this.#canvas.height / rect.height;
      this.#mouseX = Math.floor((touch.clientX - rect.left) * scaleX);
      this.#mouseY = Math.floor((touch.clientY - rect.top) * scaleY);
      this.#leftButtonDown = true;
      this.#UpdateMouseButton();
      e.preventDefault();
    });
    this.#canvas.addEventListener("touchend", (e) => {
      this.#leftButtonDown = false;
      this.#UpdateMouseButton();
      e.preventDefault();
    });
  }
  #GetMouseX() {
    return this.#mouseX;
  }
  #GetMouseY() {
    return this.#mouseY;
  }
  #GetMouseButton() {
    return this.#mouseButton;
  }
  #UpdateMouseButton() {
    if (this.#leftButtonDown && this.#rightButtonDown)
      this.#mouseButton = 3;
    else if (this.#rightButtonDown)
      this.#mouseButton = 2;
    else if (this.#leftButtonDown)
      this.#mouseButton = 1;
    else
      this.#mouseButton = 0;
  }
  #PascalWriteLog() {
    const bufferPtr = this.#wasm.exports.GetLogBuffer();
    const buffer = new Uint8Array(this.#wasm.exports.memory.buffer, bufferPtr, 256);
    const len = buffer[0];
    const msgBytes = buffer.slice(1, 1 + len);
    const msg = new TextDecoder().decode(msgBytes);
    console.log("Pascal:", msg);
  }
  #PanicHalt(textPtr, textLen) {
    const buffer = new Uint8Array(this.#wasm.exports.memory.buffer, textPtr, textLen);
    const msg = new TextDecoder().decode(buffer);
    done = true;
    this.Cleanup();
    throw new Error(`PANIC: ${msg}`);
  }
  #GetTimer() {
    return (Date.now() - this.#midnightOffset) / 1000;
  }
  #GetFullTimer() {
    return Date.now() / 1000;
  }
  #surface = null;
  #VgaUpload() {
    const surfacePtr = this.#wasm.exports.GetSurfacePtr();
    const imageData = new Uint8ClampedArray(this.#wasm.exports.memory.buffer, surfacePtr, this.#vgaWidth * this.#vgaHeight * 4);
    this.#surface = new ImageData(imageData, this.#vgaWidth, this.#vgaHeight);
  }
  #VgaPresent() {
    this.#ctx.putImageData(this.#surface, 0, 0);
  }
  #AddResizeListener() {
    window.addEventListener("resize", this.#HandleResize.bind(this));
  }
  #GetFullscreenState() {
    return document.fullscreenElement != null;
  }
  #ToggleFullscreen() {
    if (!this.#GetFullscreenState())
      this.#canvas.requestFullscreen();
    else
      document.exitFullscreen();
  }
  #EndFullscreen() {
    if (this.#GetFullscreenState())
      document.exitFullscreen();
  }
  #HandleResize() {
    this.#FitCanvas();
  }
  #FitCanvas() {
    const aspectRatio = this.#vgaWidth / this.#vgaHeight;
    const [windowWidth, windowHeight] = [window.innerWidth, window.innerHeight];
    const windowRatio = windowWidth / windowHeight;
    let w = 0, h = 0;
    if (windowRatio > aspectRatio) {
      h = windowHeight;
      w = h * aspectRatio;
    } else {
      w = windowWidth;
      h = w / aspectRatio;
    }
    if (this.#canvas != null) {
      this.#canvas.style.width = w + "px";
      this.#canvas.style.height = h + "px";
    }
  }
  Update() {
    this.#wasm.exports.Update();
  }
  Draw() {
    this.#wasm.exports.Draw();
  }
}
