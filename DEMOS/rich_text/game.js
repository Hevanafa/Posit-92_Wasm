"use strict";

/**
 * Experimental boilerplate without the intro
 */
class Game extends Posit92 {
  /**
   * KeyboardEvent.code to DOS scancode
   */
  ScancodeMap = {
    "Escape": 0x01,
    "Space": 0x39,
    "Enter": 0x1C,
    // Add more scancodes as necessary
  };

  AssetManifest = {
    images: {
      cursor: "assets/images/cursor.png",
      dosu_exe: [
        "assets/images/dosu_1.png",
        "assets/images/dosu_2.png"
      ]
    }
  };

  async loadDefaultFont() {
    await this.loadBMFont(
      "assets/fonts/ms_sans_serif_10px_regular.txt",
      this.wasmInstance.exports.defaultFontPtr(),
      this.wasmInstance.exports.defaultFontGlyphsPtr());
  }

  /**
   * @override
   */
  async loadAssets() {

    this.initLoadingScreen();

    await this.loadImagesFromManifest(this.AssetManifest.images);

    await this.loadBMFont(
      "assets/fonts/ms_sans_serif_10px_bold.txt",
      this.wasmInstance.exports.boldFontPtr(),
      this.wasmInstance.exports.boldFontGlyphsPtr());

    await this.loadBMFont(
      "assets/fonts/ms_sans_serif_10px_italic.txt",
      this.wasmInstance.exports.italicFontPtr(),
      this.wasmInstance.exports.italicFontGlyphsPtr());

    await this.loadBMFont(
      "assets/fonts/ms_sans_serif_10px_bold_italic.txt",
      this.wasmInstance.exports.boldItalicFontPtr(),
      this.wasmInstance.exports.boldItalicFontGlyphsPtr());
  }
}

const TargetFPS = 60;
const FrameTime = 1000 / TargetFPS;
/**
 * in milliseconds
 */
let lastFrameTime = 0.0;

var done = false;

async function main() {
  const game = new Game("game");
  await game.init();
  await game.loadDefaultFont();

  game.quickStart();

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
  overlay.parentNode.removeChild(overlay);

  main()
}
