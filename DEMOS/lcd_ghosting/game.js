"use strict";

/**
 * Experimental boilerplate (full)
 */
class Game extends Posit92 {
  AssetManifest = {
    images: {
      cursor: "assets/images/cursor.png"
      // Add more image assets here
    },
    sounds: new Map([
      // Add sound assets here
    ])
  }

  #setupImportObject() {
    const { env } = super._getWasmImportObject();

    Object.assign(env, {
      vgaFlush: this.#vgaFlush.bind(this)
    });
  }

  async init() {
    this.setLoadingText("Downloading engine...");
    this.#setupImportObject();
    await super.init();
  }

  /**
   * @type { HTMLCanvasElement }
   */
  cleanSurface

  /**
   * @type { HTMLCanvasElement }
   */
  accumulatorSurface;

  /**
   * @type { HTMLCanvasElement }
   */
  accumulatorSurfaceCopy;

  initGhostSurfaces() {
    this.cleanSurface = document.createElement("canvas");
    this.cleanSurface.width = this.vgaWidth;
    this.cleanSurface.height = this.vgaHeight;

    this.accumulatorSurface = document.createElement("canvas");
    this.accumulatorSurface.width = this.vgaWidth;
    this.accumulatorSurface.height = this.vgaHeight;

    this.accumulatorSurfaceCopy = document.createElement("canvas");
    this.accumulatorSurfaceCopy.width = this.vgaWidth;
    this.accumulatorSurfaceCopy.height = this.vgaHeight;
  }

  /**
   * @override
   */
  #vgaFlush() {
    const surfacePtr = this.wasmInstance.exports.getSurfacePtr();
    const imageData = new Uint8ClampedArray(
      this.wasmInstance.exports.memory.buffer,
      surfacePtr,
      this.vgaWidth * this.vgaHeight * 4);

    const imgData = new ImageData(imageData, this.vgaWidth, this.vgaHeight);

    if (this.cleanSurface == null)
      this.initGhostSurfaces();

    this.cleanSurface.getContext("2d").putImageData(imgData, 0, 0);

    /**
     * @type { CanvasRenderingContext2D }
     */
    let accumulatorCtx;

    // Surface copy (snapshot)
    accumulatorCtx = this.accumulatorSurfaceCopy.getContext("2d");
    // accumulatorCtx.clearRect(0, 0, this.vgaWidth, this.vgaHeight);
    accumulatorCtx.drawImage(this.accumulatorSurface, 0, 0);

    // Draw the copy back with the decay alpha
    accumulatorCtx = this.accumulatorSurface.getContext("2d");
    // accumulatorCtx.clearRect(0, 0, this.vgaWidth, this.vgaHeight);
    accumulatorCtx.drawImage(this.accumulatorSurfaceCopy, 0, 0);
    // accumulatorCtx.globalAlpha = 0.9;
    accumulatorCtx.fillStyle = "rgba(32, 32, 32, 0.9)";
    accumulatorCtx.fillRect(0, 0, this.vgaWidth, this.vgaHeight);

    accumulatorCtx.globalAlpha = 1.0;
    accumulatorCtx.drawImage(this.cleanSurface, 0, 0);

    // Displayed game canvas
    this.canvasCtx.drawImage(this.accumulatorSurface, 0, 0);
  }

  async loadDefaultFont() {
    await this.loadBMFont(
      "assets/fonts/nokia_cellphone_fc_8.txt",
      this.wasmInstance.exports.defaultFontPtr(),
      this.wasmInstance.exports.defaultFontGlyphsPtr());
  }

  /**
   * @override
   */
  async loadAssets() {
    let handle = 0;

    this.initLoadingScreen();

    await this.loadImagesFromManifest(this.AssetManifest.images);
    // Sounds can be loaded later

    handle = await this.loadImage("assets/images/dosu_1.png");
    this.wasmInstance.exports.setImgDosuEXE(handle, 0);
    handle = await this.loadImage("assets/images/dosu_2.png");
    this.wasmInstance.exports.setImgDosuEXE(handle, 1);

    // Add more assets as necessary
  }

  /**
   * @override
   */
  onWasmProgress(loaded, total) {
    const loadedKB = Math.ceil(loaded / 1024);
    const totalKB = Math.ceil(total / 1024);

    this.setLoadingText(`Downloading engine... ${loadedKB} / ${totalKB} KB`)
  }

  async loadIntro() {
    this.wasmInstance.exports.setImgPosit92Logo(
      await this.loadImage("assets/images/posit-92_32px.png"));

    this.wasmInstance.exports.setImgFPCLogo(
      await this.loadImage("assets/images/fpc_logo.png"));

    this.wasmInstance.exports.setImgWasmLogo(
      await this.loadImage("assets/images/wasm_logo.png"));
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

  await game.loadIntro();
  game.beginIntro();

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
