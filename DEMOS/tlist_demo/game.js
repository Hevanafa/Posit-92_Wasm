"use strict";

class Game extends Posit92 {
  /**
   * KeyboardEvent.code to DOS scancode
   */
  ScancodeMap = {
    "Escape": 0x01,
    "Space": 0x39
    // Add more scancodes as necessary
  };

  #AssetManifest = {
    images: {
      cursor: "assets/images/cursor.png"
      // Add more image assets here
    },
    sounds: new Map([
      // Add sound assets here
    ])
  }

  async loadDefaultFont() {
    await this.loadBMFont(
      "assets/fonts/nokia_cellphone_fc_8.txt",
      this.wasmInstance.exports.defaultFontPtr(),
      this.wasmInstance.exports.defaultFontGlyphsPtr());
  }

  async loadAssets() {
    let handle = 0;

    this.setLoadingActual(0);

    const imageCount = Object.keys(this.#AssetManifest.images).length;
    const soundCount = this.#AssetManifest.sounds.size;
    this.setLoadingTotal(imageCount + soundCount);

    await this.loadImagesFromManifest(this.#AssetManifest.images);

    handle = await this.loadImage("assets/images/dosu_1.png");
    this.wasmInstance.exports.setImgDosuEXE(handle, 0);
    handle = await this.loadImage("assets/images/dosu_2.png");
    this.wasmInstance.exports.setImgDosuEXE(handle, 1);

    // Add more assets as necessary
  }

  async init() {
    this.setLoadingText("Loading WebAssembly...");
    await super.init();
  }

  #loadingInterval = 0;

  beginLoadingScreen() {
    // Only applicable with an in-game loading screen
    // This is because loadAssets is called in `afterInit`
    this.hideLoadingOverlay();

    this.wasmInstance.exports.renderLoadingScreen(
      this.loadingProgress.actual,
      this.loadingProgress.total);

    this.#loadingInterval = window.setInterval(() => {
      const { actual, total } = this.loadingProgress;
      this.wasmInstance.exports.renderLoadingScreen(actual, total);
      // console.log("loadingProgress", actual, total);
    }, 100);
  }

  endLoadingScreen() {
    window.clearInterval(this.#loadingInterval);
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
  await game.loadDefaultFont();

  game.beginLoadingScreen();
    await game.loadAssets();
    await game.afterInit();
  game.endLoadingScreen();

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
