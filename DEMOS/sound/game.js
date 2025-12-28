"use strict";

const
  SfxBwonk = 1,
  SfxBite = 2,
  SfxBonk = 3,
  SfxStrum = 4,
  SfxSlip = 5;

// Game < SoundsMixin < Posit92
class Game extends SoundsMixin {
  /**
   * KeyboardEvent.code to DOS scancode
   */
  ScancodeMap = {
    "Escape": 0x01,
    "Space": 0x39,

    "Digit1": 0x02,
    "Digit2": 0x03,
    "Digit3": 0x04,
    "Digit4": 0x05,
    "Digit5": 0x06
    // Add more scancodes as necessary
  };

  AssetManifest = {
    images: {
      cursor: "assets/images/cursor.png"
    },
    sounds: new Map([
      [SfxBwonk, "assets/sfx/bwonk.ogg"],
      [SfxBite, "assets/sfx/bite.ogg"],
      [SfxBonk, "assets/sfx/bonk.ogg"],
      [SfxStrum, "assets/sfx/strum.ogg"],
      [SfxSlip, "assets/sfx/slip.ogg"]
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
    
    this.initLoadingScreen();
    await this.loadImagesFromManifest(this.AssetManifest.images);
    await this.loadSoundsFromManifest(this.AssetManifest.sounds);

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
  overlay.parentNode.removeChild(overlay)

  main()
}
