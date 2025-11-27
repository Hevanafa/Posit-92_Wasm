"use strict";

// Asset boilerplate
class Game extends Posit92 {
  async loadAssets() {
    let handle = 0;

    handle = await this.loadImage("assets/images/cursor.png");
    this.wasmInstance.exports.setImgCursor(handle);
    handle = await this.loadImage("assets/images/hand.png");
    this.wasmInstance.exports.setImgHandCursor(handle);

    await this.loadBMFont(
      "assets/fonts/nokia_cellphone_fc_8.txt",
      this.wasmInstance.exports.defaultFontPtr(),
      this.wasmInstance.exports.defaultFontGlyphsPtr());
    await this.loadBMFont(
      "assets/fonts/nokia_cellphone_fc_8.txt",
      this.wasmInstance.exports.blackFontPtr(),
      this.wasmInstance.exports.blackFontGlyphsPtr());

    handle = await this.loadImage("assets/images/dosu_1.png");
    this.wasmInstance.exports.setImgDosuEXE(handle, 0);
    handle = await this.loadImage("assets/images/dosu_2.png");
    this.wasmInstance.exports.setImgDosuEXE(handle, 1);

    this.wasmInstance.exports.setImgWinNormal(
      await this.loadImage("assets/images/btn_normal.png"));

    this.wasmInstance.exports.setImgWinHovered(
      await this.loadImage("assets/images/btn_hovered.png"));

    this.wasmInstance.exports.setImgWinPressed(
      await this.loadImage("assets/images/btn_pressed.png"));

    this.wasmInstance.exports.setImg9SliceNormal(
      await this.loadImage("assets/images/9slice_normal.png"));

    this.wasmInstance.exports.setImg9SliceHovered(
      await this.loadImage("assets/images/9slice_hovered.png"));

    this.wasmInstance.exports.setImg9SlicePressed(
      await this.loadImage("assets/images/9slice_pressed.png"));

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
