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

  AssetManifest = {
    images: {
      cursor: "assets/images/cursor.png",
      hand: "assets/images/hand.png",

      win_normal: "assets/images/win_normal.png",
      win_hovered: "assets/images/win_hovered.png",
      win_pressed: "assets/images/win_pressed.png",
      prompt_bg: "assets/images/prompt_bg.png",
      btn_prompt_normal: "assets/images/btn_prompt_normal.png",
      btn_prompt_pressed: "assets/images/btn_prompt_pressed.png"
    }
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
    this.loadImagesFromManifest(this.AssetManifest.images);

    await this.loadBMFont(
      "assets/fonts/nokia_cellphone_fc_8.txt",
      this.wasmInstance.exports.blackFontPtr(),
      this.wasmInstance.exports.blackFontGlyphsPtr());

    await this.loadBMFont(
      "assets/fonts/picotron_8px.txt",
      this.wasmInstance.exports.picotronFontPtr(),
      this.wasmInstance.exports.picotronFontGlyphsPtr());

    handle = await this.loadImage("assets/images/dosu_1.png");
    this.wasmInstance.exports.setImgDosuEXE(handle, 0);
    handle = await this.loadImage("assets/images/dosu_2.png");
    this.wasmInstance.exports.setImgDosuEXE(handle, 1);

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
