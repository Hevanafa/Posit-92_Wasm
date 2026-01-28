"use strict";

const
  BgmClassic = 1;

// Game < SoundsMixin < Posit92
class Game extends SoundsMixin {
  /**
   * KeyboardEvent.code to DOS scancode
   */
  ScancodeMap = {
    "Escape": 0x01,
    "Space": 0x39
    // Add more scancodes as necessary
  };

  AssetManifest = {
    images: {
      cursor: "assets/images/cursor.png"
    },
    sounds: new Map([
    ])
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

    handle = await this.loadImage("assets/images/dosu_1.png");
    this.wasmInstance.exports.setImgDosuEXE(handle, 0);
    handle = await this.loadImage("assets/images/dosu_2.png");
    this.wasmInstance.exports.setImgDosuEXE(handle, 1);

    this.wasmInstance.exports.setImgPlay(
      await this.loadImage("assets/images/play.png"));
    this.wasmInstance.exports.setImgStop(
      await this.loadImage("assets/images/stop.png"));
    this.wasmInstance.exports.setImgPause(
      await this.loadImage("assets/images/pause.png"));

    this.wasmInstance.exports.setImgVolumeOn(
      await this.loadImage("assets/images/volume_on.png"));
    this.wasmInstance.exports.setImgVolumeOff(
      await this.loadImage("assets/images/volume_off.png"));

    await this.loadSound(BgmClassic, "assets/bgm/Georges Bizet - Les Toreadors from Carmen Suite No. 1.ogg");

    // Add more assets as necessary
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
  overlay.parentNode.removeChild(overlay)

  main()
}
