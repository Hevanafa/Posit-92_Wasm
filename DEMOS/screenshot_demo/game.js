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
    "F2": 0x3C,
    // Add more scancodes as necessary
  };

  AssetManifest = {
    images: {
      cursor: "assets/images/cursor.png",
      dosu_exe: [
        "assets/images/dosu_1.png",
        "assets/images/dosu_2.png"
      ]
      // Add more image assets here
    },
    sounds: new Map([
      // Add sound assets here
    ])
  }

  #setupImportObject() {
    const { env } = super._getWasmImportObject();

    Object.assign(env, {
      takeScreenshot: () => {
        console.log("takeScreenshot call")
        console.log("canvasID", this.canvasID);

        /**
         * @type {HTMLCanvasElement}
         */
        const canvas = document.getElementById(this.canvasID);
        const anchor = document.createElement("a");
        anchor.href = canvas.toDataURL();
        anchor.download = "test_image.png";
        anchor.click();
      }
    })
  }

  canvasID = "";

  /**
   * @override
   */
  constructor(canvasID, vgaWidth = 320, vgaHeight = 200) {
    super(canvasID, vgaWidth, vgaHeight);

    this.canvasID = canvasID;
  }

  /**
   * @override
   */
  async init() {
    this.#setupImportObject();
    await super.init()
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
    this.initLoadingScreen();

    await this.loadImagesFromManifest(this.AssetManifest.images);
    // Sounds can be loaded later
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
