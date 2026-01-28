"use strict";
class Posit92 {
    static version = "0.1.4_experimental";
    #wasmSource = "game.wasm";
    #wasmMemSize = 2 * 1048576;
    #stackSize = 128 * 1024;
    #videoMemSize = 0;
    #vgaWidth = 320;
    #vgaHeight = 200;
    #canvas;
    #ctx;
    #wasm = null;
    get wasmInstance() { return this.#wasm; }
    #midnightOffset = 0;
    #importObject = {
        env: {
            _haltproc: this.#handleHaltProc.bind(this),
            hideLoadingOverlay: this.hideLoadingOverlay.bind(this),
            loadAssets: this.#loadAssets.bind(this),
            getLoadingActual: this.getLoadingActual.bind(this),
            getLoadingTotal: this.getLoadingTotal.bind(this),
            hideCursor: () => this.#hideCursor(),
            showCursor: () => this.#showCursor(),
            toggleFullscreen: () => this.#toggleFullscreen(),
            endFullscreen: () => this.#endFullscreen(),
            getFullscreenState: () => this.#getFullscreenState(),
            fitCanvas: () => this.#fitCanvas(),
            isKeyDown: this.#isKeyDown.bind(this),
            signalDone: this.#signalDone.bind(this),
            writeLogF32: value => console.log("Pascal (f32):", value),
            writeLogI32: value => console.log("Pascal (i32):", value),
            flushLog: () => this.#pascalWriteLog(),
            getMouseX: () => this.#getMouseX(),
            getMouseY: () => this.#getMouseY(),
            getMouseButton: () => this.#getMouseButton(),
            jsPanicHalt: this.#panicHalt.bind(this),
            getTimer: () => this.#getTimer(),
            getFullTimer: () => this.#getFullTimer(),
            vgaFlush: () => this.#vgaFlush()
        }
    };
    _getWasmImportObject() {
        return this.#importObject;
    }
    #handleHaltProc(exitcode) {
        console.log("Programme halted with code:", exitcode);
        this.cleanup();
        done = true;
    }
    #signalDone() {
        this.cleanup();
        done = true;
    }
    constructor(canvasID) {
        this.#assertString(canvasID);
        if (document.getElementById(canvasID) == null)
            throw new Error(`Couldn't find canvasID \"${canvasID}\"`);
        this.#canvas = document.getElementById(canvasID);
        this.#ctx = this.#canvas.getContext("2d");
        this.#videoMemSize = this.#vgaWidth * this.#vgaHeight * 4;
    }
    #loadMidnightOffset() {
        const now = new Date();
        const midnight = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        this.#midnightOffset = midnight.getTime();
    }
    async #initWebAssembly() {
        const response = await fetch(this.#wasmSource);
        const contentLength = response.headers.get("x-goog-stored-content-length")
            ?? response.headers.get("content-length");
        const total = Number(contentLength);
        let loaded = 0;
        if (response.body == null)
            throw new Error("Missing response.body");
        const reader = response.body.getReader();
        const chunks = [];
        while (true) {
            const { done, value } = await reader.read();
            if (done)
                break;
            chunks.push(value);
            loaded += value.length;
            this.onWasmProgress(loaded, total);
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
    onWasmProgress(loaded, total) {
        const loadedKB = Math.ceil(loaded / 1024);
        if (isNaN(total))
            this.setLoadingText(`Downloading engine (${loadedKB} KB)`);
        else {
            const totalKB = Math.ceil(total / 1024);
            this.setLoadingText(`Downloading engine (${loadedKB} KB / ${totalKB} KB)`);
        }
    }
    #initWasmMemory() {
        const videoMemStart = this.#stackSize;
        const heapStart = this.#stackSize + this.#videoMemSize;
        const heapSize = this.#wasmMemSize - heapStart;
        const pages = this.#wasm.exports.memory.buffer.byteLength / 65536;
        const requiredPages = Math.ceil(this.#wasmMemSize / 65536);
        if (pages < requiredPages)
            this.#wasm.exports.memory.grow(requiredPages - pages);
        this.#wasm.exports.initVideoMem(this.#vgaWidth, this.#vgaHeight, videoMemStart);
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
        this.#wasm.exports.beginIntroState();
    }
    #addOutOfFocusFix() {
        this.#canvas.addEventListener("click", () => {
            this.#canvas.tabIndex = 0;
            this.#canvas.focus();
        });
    }
    cleanup() {
        this.#showCursor();
    }
    async loadAssets() { }
    async #loadAssets() {
        await this.loadAssets();
        this.afterInit();
    }
    async quickStart() {
        this.hideLoadingOverlay();
        this.#wasm.exports.beginLoadingState();
    }
    afterInit() {
        this.#wasm.exports.afterInit();
        this.#addOutOfFocusFix();
        this.#addResizeListener();
    }
    #hideCursor() {
        this.#canvas.style.cursor = "none";
    }
    #showCursor() {
        this.#canvas.style.removeProperty("cursor");
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
        this.#assertString(url);
        return new Promise((resolve, reject) => {
            const img = new Image();
            img.onload = () => resolve(img);
            img.onerror = reject;
            img.src = url;
        });
    }
    #images = [];
    async loadImage(url) {
        this.#assertString(url);
        const img = await this.loadImageFromURL(url);
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
        this.#images.push(imageData);
        this.#wasm.exports.registerImageRef(handle, wasmPtr, img.width, img.height);
        return handle;
    }
    #loadingActual = 0;
    getLoadingActual() { return this.#loadingActual; }
    #loadingTotal = 0;
    getLoadingTotal() { return this.#loadingTotal; }
    async #loadSingleImage(key, path) {
        return this.loadImage(path).then(handle => {
            this.incLoadingActual();
            return { key, path, handle };
        });
    }
    async #loadImageArray(key, paths) {
        const promises = paths.map((path, index) => this.loadImage(path).then(handle => {
            this.incLoadingActual();
            return { key, path, handle, index };
        }));
        return Promise.all(promises);
    }
    async loadImagesFromManifest(manifest) {
        const entries = Object.entries(manifest);
        const promises = entries.map(([key, pathOrArray]) => Array.isArray(pathOrArray)
            ? this.#loadImageArray(key, pathOrArray)
            : this.#loadSingleImage(key, pathOrArray));
        const results = await Promise.all(promises);
        const failures = results.flat(1).filter(item => item.handle == 0);
        if (failures.length > 0) {
            console.error("Failed to load assets:");
            for (const failure of failures)
                console.error("   " + failure.key + ": " + failure.path);
            throw new Error("Failed to load some assets");
        }
        for (const item of results.flat(1)) {
            const { key, handle, index } = item;
            const caps = key
                .replace(/^./, _ => _.toUpperCase())
                .replace(/_(.)/g, (_, g1) => g1.toUpperCase());
            const setterName = `setImg${caps}`;
            if (typeof this.wasmInstance.exports[setterName] != "function")
                console.error("loadAssetsFromManifest: Missing setter", setterName, "for the asset key", key);
            else {
                if (index == null)
                    this.wasmInstance.exports[setterName](handle);
                else
                    this.wasmInstance.exports[setterName](handle, index);
            }
        }
    }
    async loadBMFontFromManifest(manifest) {
        const entries = Object.entries(manifest);
        const promises = entries.map(([key, params]) => {
            const setter = this.wasmInstance.exports[params.setter];
            if (typeof setter != "function") {
                console.error("loadBMFontFromManifest: Missing setter", setter);
                return { key, setterPtr: 0 };
            }
            const glyphSetter = this.wasmInstance.exports[params.glyphSetter];
            if (typeof glyphSetter != "function") {
                console.error("loadBMFontFromManifest: Missing glyphSetter", params.glyphSetter);
                return { key, glyphSetterPtr: 0 };
            }
            const [setterPtr, glyphSetterPtr] = [setter(), glyphSetter()];
            return this.loadBMFont(params.path, setterPtr, glyphSetterPtr).then(() => {
                this.incLoadingActual();
                return { key, path: params.path, setterPtr, glyphSetterPtr };
            });
        });
        const results = await Promise.all(promises);
        const failures = results.filter(item => item.setterPtr == 0 || item.glyphSetterPtr == 0);
        if (failures.length > 0) {
            console.error("Failed to load assets:", failures.map(item => item.key).join(", "));
            throw new Error("Failed to load some assets");
        }
        for (const item of results)
            ;
    }
    get loadingProgress() {
        return {
            actual: this.#loadingActual,
            total: this.#loadingTotal
        };
    }
    incLoadingActual() {
        this.#loadingActual++;
    }
    setLoadingActual(value) {
        this.#assertNumber(value);
        this.#loadingActual = value;
    }
    incLoadingTotal(count) {
        this.#loadingTotal += count;
    }
    setLoadingTotal(value) {
        this.#assertNumber(value);
        this.#loadingTotal = value;
    }
    setLoadingText(text) {
        const div = document.querySelector("#loading-overlay > div");
        if (div == null)
            return;
        div.innerHTML = text;
    }
    hideLoadingOverlay() {
        const div = document.getElementById("loading-overlay");
        if (div == null)
            return;
        div.classList.add("hidden");
        this.setLoadingText("");
    }
    async sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
    AssetManifest = null;
    initLoadingScreen() {
        if (this.AssetManifest == null) {
            console.warn("Missing AssetManifest in " + this.constructor.name);
            return;
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
        };
    }
    async loadBMFont(url, fontPtrRef, fontGlyphsPtrRef) {
        this.#assertString(url);
        this.#assertNumber(fontPtrRef);
        this.#assertNumber(fontGlyphsPtrRef);
        const res = await fetch(url);
        const text = await res.text();
        const lines = text.endsWith("\r\n") ? text.split("\r\n") : text.split("\n");
        let txtLine = "";
        let pairs;
        let k = "", v = "";
        let fontface = "";
        let filename = "";
        let lineHeight = 0;
        const fontGlyphs = new Map();
        let glyphCount = 0;
        let imgHandle = 0;
        for (const line of lines) {
            txtLine = line.replaceAll(/\s+/g, " ");
            pairs = txtLine.split(" ").map(part => part.split("="));
            if (txtLine.startsWith("info")) {
                const result = txtLine.match(/face=\"(.*?)\"/);
                fontface = result?.[1] ?? "";
                console.log("Loading BMFont ", fontface);
            }
            else if (txtLine.startsWith("common")) {
                [k, v] = (pairs.find(pair => pair[0] == "lineHeight"));
                lineHeight = parseInt(v);
            }
            else if (txtLine.startsWith("page")) {
                [k, v] = (pairs.find(pair => pair[0] == "file"));
                filename = v.replaceAll(/"/g, "");
            }
            else if (txtLine.startsWith("char") && !txtLine.startsWith("chars")) {
                const tempGlyph = this.#newBMFontGlyph();
                for (const [k, v] of pairs) {
                    switch (k) {
                        case "id":
                            tempGlyph.id = parseInt(v);
                            break;
                        case "x":
                            tempGlyph.x = parseInt(v);
                            break;
                        case "y":
                            tempGlyph.y = parseInt(v);
                            break;
                        case "width":
                            tempGlyph.width = parseInt(v);
                            break;
                        case "height":
                            tempGlyph.height = parseInt(v);
                            break;
                        case "xoffset":
                            tempGlyph.xoffset = parseInt(v);
                            break;
                        case "yoffset":
                            tempGlyph.yoffset = parseInt(v);
                            break;
                        case "xadvance":
                            tempGlyph.xadvance = parseInt(v);
                            break;
                    }
                }
                fontGlyphs.set(tempGlyph.id, tempGlyph);
                glyphCount++;
            }
        }
        console.log("Loaded", glyphCount, "glyphs");
        imgHandle = await this.loadImage(filename);
        const fontPtr = fontPtrRef;
        const glyphsPtr = fontGlyphsPtrRef;
        const fontMem = new DataView(this.#wasm.exports.memory.buffer, fontPtr);
        let offset = 0;
        offset += 16;
        offset += 64;
        fontMem.setUint16(offset, lineHeight, true);
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
    ScancodeMap = null;
    heldScancodes = new Set();
    #initKeyboard() {
        if (this.ScancodeMap == null) {
            console.warn("Missing ScancodeMap in " + this.constructor.name);
            return;
        }
        const ScancodeMap = this.ScancodeMap;
        window.addEventListener("keydown", e => {
            if (e.repeat)
                return;
            const scancode = ScancodeMap[e.code];
            if (scancode) {
                this.heldScancodes.add(scancode);
                e.preventDefault();
            }
        });
        window.addEventListener("keyup", e => {
            const scancode = ScancodeMap[e.code];
            if (scancode)
                this.heldScancodes.delete(scancode);
        });
    }
    #isKeyDown(scancode) {
        return this.heldScancodes.has(scancode);
    }
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
            if (e.button == 0)
                this.#leftButtonDown = true;
            if (e.button == 2)
                this.#rightButtonDown = true;
            this.#updateMouseButton();
            e.preventDefault();
        });
        this.#canvas.addEventListener("mouseup", e => {
            if (e.button == 0)
                this.#leftButtonDown = false;
            if (e.button == 2)
                this.#rightButtonDown = false;
            this.#updateMouseButton();
        });
        this.#canvas.addEventListener("contextmenu", e => {
            e.preventDefault();
        });
    }
    #getMouseX() { return this.#mouseX; }
    #getMouseY() { return this.#mouseY; }
    #getMouseButton() { return this.#mouseButton; }
    #updateMouseButton() {
        if (this.#leftButtonDown && this.#rightButtonDown)
            this.#mouseButton = 3;
        else if (this.#rightButtonDown)
            this.#mouseButton = 2;
        else if (this.#leftButtonDown)
            this.#mouseButton = 1;
        else
            this.#mouseButton = 0;
    }
    #pascalWriteLog() {
        const bufferPtr = this.#wasm.exports.getLogBuffer();
        const buffer = new Uint8Array(this.#wasm.exports.memory.buffer, bufferPtr, 256);
        const len = buffer[0];
        const msgBytes = buffer.slice(1, 1 + len);
        const msg = new TextDecoder().decode(msgBytes);
        console.log("Pascal:", msg);
    }
    #panicHalt(textPtr, textLen) {
        const buffer = new Uint8Array(this.#wasm.exports.memory.buffer, textPtr, textLen);
        const msg = new TextDecoder().decode(buffer);
        done = true;
        this.cleanup();
        throw new Error(`PANIC: ${msg}`);
    }
    #getTimer() {
        return (Date.now() - this.#midnightOffset) / 1000;
    }
    #getFullTimer() {
        return Date.now() / 1000;
    }
    flush() { this.#vgaFlush(); }
    #vgaFlush() {
        const surfacePtr = this.#wasm.exports.getSurfacePtr();
        const imageData = new Uint8ClampedArray(this.#wasm.exports.memory.buffer, surfacePtr, this.#vgaWidth * this.#vgaHeight * 4);
        const imgData = new ImageData(imageData, this.#vgaWidth, this.#vgaHeight);
        this.#ctx.putImageData(imgData, 0, 0);
    }
    #addResizeListener() {
        window.addEventListener("resize", this.#handleResize.bind(this));
    }
    #getFullscreenState() {
        return document.fullscreenElement != null;
    }
    #toggleFullscreen() {
        if (!this.#getFullscreenState())
            this.#canvas.requestFullscreen();
        else
            document.exitFullscreen();
    }
    #endFullscreen() {
        if (this.#getFullscreenState())
            document.exitFullscreen();
    }
    #handleResize() {
        this.#fitCanvas();
    }
    #fitCanvas() {
        const aspectRatio = this.#vgaWidth / this.#vgaHeight;
        const [windowWidth, windowHeight] = [window.innerWidth, window.innerHeight];
        const windowRatio = windowWidth / windowHeight;
        let w = 0, h = 0;
        if (windowRatio > aspectRatio) {
            h = windowHeight;
            w = h * aspectRatio;
        }
        else {
            w = windowWidth;
            h = w / aspectRatio;
        }
        if (this.#canvas != null) {
            this.#canvas.style.width = w + "px";
            this.#canvas.style.height = h + "px";
        }
    }
    update() { this.#wasm.exports.update(); }
    draw() { this.#wasm.exports.draw(); }
}
//# sourceMappingURL=posit-92.js.map