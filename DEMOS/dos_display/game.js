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
      CGA_font: "assets/images/CGA8x8.png",
      cursor: "assets/images/cursor.png"
      // Add more image assets here
    },
    sounds: new Map([
      // Add sound assets here
    ])
  }

  async loadAssets() {
    let handle = 0;

    this.setLoadingActual(0);

    const imageCount = Object.keys(this.#AssetManifest.images).length;
    const soundCount = this.#AssetManifest.sounds.size;
    this.setLoadingTotal(imageCount + soundCount);

    this.loadImagesFromManifest(this.#AssetManifest.images);

    // Add more assets as necessary
  }

  async init() {
    this.setLoadingText("Loading WebAssembly...");
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
  // await game.loadDefaultFont();
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
