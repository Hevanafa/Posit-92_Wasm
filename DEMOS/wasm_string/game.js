/**
 * String interop demo
 * Part of Posit-92 framework
 * Jump to loadHelloText to see how it's done
 */

"use strict";

// Asset boilerplate
class Game extends Posit92 {
  /**
   * KeyboardEvent.code to DOS scancode
   */
  ScancodeMap = {
    "Escape": 0x01,
    "Space": 0x39
    // Add more scancodes as necessary
  };

  /**
   * Pass a JS string to Pascal
   */
  #loadStringBuffer(text) {
    const encoder = new TextEncoder();
    const bytes = encoder.encode(text);

    const bufferPtr = this.wasmInstance.exports.getStringBuffer();
    const buffer = new Uint8Array(this.wasmInstance.exports.memory.buffer, bufferPtr, bytes.length);
    buffer.set(bytes);

    return bytes.length
  }

  loadHelloText() {
    const length = this.#loadStringBuffer("Hello from JS to WebAssembly!");
    const bufferPtr = this.wasmInstance.exports.getStringBuffer();
    // this.wasmInstance.exports.debugStringBuffer();
    this.wasmInstance.exports.loadHelloText(bufferPtr, length);
  }

  async loadAssets() {
    let handle = 0;

    handle = await this.loadImage("assets/images/cursor.png");
    this.wasmInstance.exports.setImgCursor(handle);

    await this.loadBMFont(
      "assets/fonts/nokia_cellphone_fc_8.txt",
      this.wasmInstance.exports.defaultFontPtr(),
      this.wasmInstance.exports.defaultFontGlyphsPtr());

    handle = await this.loadImage("assets/images/dosu_1.png");
    this.wasmInstance.exports.setImgDosuEXE(handle, 0);
    handle = await this.loadImage("assets/images/dosu_2.png");
    this.wasmInstance.exports.setImgDosuEXE(handle, 1);

    // Add more assets as necessary
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
  game.afterInit();

  game.loadHelloText();

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
