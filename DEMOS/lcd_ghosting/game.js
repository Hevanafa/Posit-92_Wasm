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
  surfaceCopy;

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

    if (this.surfaceCopy == null) {
      this.surfaceCopy = document.createElement("canvas");
      this.surfaceCopy.width = this.vgaWidth;
      this.surfaceCopy.height = this.vgaHeight;
    }

    this.surfaceCopy.getContext("2d").putImageData(imgData, 0, 0);

    this.canvasCtx.globalAlpha = 0.1;

    this.canvasCtx.drawImage(this.surfaceCopy, 0, 0);
    
    this.canvasCtx.globalAlpha = 1.0;
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
