"use strict";

class Game extends SoundsMixin {
  /**
   * KeyboardEvent.code to DOS scancode
   */
  ScancodeMap = {
    "Escape": 0x01,
    "Backspace": 0x0E,
    "Enter": 0x1C,

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

    "KeyA": 0x1E,
    "KeyS": 0x1F,
    "KeyD": 0x20,
    "KeyF": 0x21,
    "KeyG": 0x22,
    "KeyH": 0x23,
    "KeyJ": 0x24,
    "KeyK": 0x25,
    "KeyL": 0x26,

    "KeyZ": 0x2C,
    "KeyX": 0x2D,
    "KeyC": 0x2E,
    "KeyV": 0x2F,
    "KeyB": 0x30,
    "KeyN": 0x31,
    "KeyM": 0x32,

    "Space": 0x39
    // Add more scancodes as necessary
  };

  BgmJingle = 1;

  #AssetManifest = {
    images: {
      CGA_font: "assets/images/CGA8x8.png",
      cursor: "assets/images/cursor.png"
      // Add more image assets here
    },
    sounds: new Map([
      [this.BgmJingle, "assets/ogg/Jingle Bells (Chiptune Version) - Chiptune Arcade.ogg"]
      // Add sound assets here
    ])
  }

  /**
   * Pass a JS string to Pascal
   */
  #loadStringBuffer(text) {
    const encoder = new TextEncoder();
    const bytes = encoder.encode(text);

    const bufferPtr = this.wasmInstance.exports.getStringBuffer();
    const buffer = new Uint8Array(
      this.wasmInstance.exports.memory.buffer,
      bufferPtr,
      bytes.length);
    buffer.set(bytes);

    this.wasmInstance.exports.setStringBufferLength(bytes.length);

    return bytes.length
  }

  #setupImportObject() {
    const { env } = super._getWasmImportObject();

    Object.assign(env, {
      queryDate: () => {
        this.#loadStringBuffer(new Date().toLocaleDateString("en-AU").replace(/\//g, "-"))
      },
      queryTime: () => {
        const now = new Date();
        
        this.#loadStringBuffer(
          now.getHours().toString().padStart(2, "0") + ":" +
          now.getMinutes().toString().padStart(2, "0") + ":" +
          now.getSeconds().toString().padStart(2, "0"))
      }
    })
  }

  async loadAssets() {
    let handle = 0;

    this.setLoadingActual(0);

    const imageCount = Object.keys(this.#AssetManifest.images).length;
    const soundCount = this.#AssetManifest.sounds.size;
    this.setLoadingTotal(imageCount + soundCount);

    await this.loadImagesFromManifest(this.#AssetManifest.images);
    await this.loadSoundsFromManifest(this.#AssetManifest.sounds);

    // Add more assets as necessary
  }

  async init() {
    this.setLoadingText("Loading WebAssembly...");
    this.#setupImportObject();
    await super.init();
  }

  async afterInit() {
    // Only applicable with an in-game loading screen
    // This is because loadAssets is called in `afterInit`
    this.hideLoadingOverlay();

    this.wasmInstance.exports.renderLoadingScreen(
      this.loadingProgress.actual,
      this.loadingProgress.total);

    const t = window.setInterval(() => {
      const { actual, total } = this.loadingProgress;
      this.wasmInstance.exports.renderLoadingScreen(actual, total);
      // console.log("loadingProgress", actual, total);
    }, 100);

    await super.afterInit();

    window.clearInterval(t);
  }
}

const TargetFPS = 60;
const FrameTime = 1000 / 60.0;
/**
 * in milliseconds
 */
let lastFrameTime = 0.0;

var done = false;

async function main() {
  const game = new Game("game");
  await game.init();
  await game.loadAssets();
  game.wasmInstance.exports.initDefaultFont();
  await game.afterInit();

  function loop(currentTime) {
    if (done) {
      game.cleanup();
      return;
    }

    const elapsed = currentTime - lastFrameTime;

    if (elapsed >= FrameTime) {
      lastFrameTime = currentTime - (elapsed % FrameTime);  // Carry over extra time
      game.update();
      game.draw();
    }

    requestAnimationFrame(loop)
  }

  requestAnimationFrame(loop)
}

function play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay)

  main()
}
