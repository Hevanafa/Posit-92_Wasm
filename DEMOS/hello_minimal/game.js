"use strict";

/**
 * Simple Boilerplate
 */
class Game extends Posit92 {
  /**
   * KeyboardEvent.code to DOS scancode
   */
  ScancodeMap = {};
}

const TargetFPS = 60;
const FrameTime = 1000 / 60.0;

/**
 * in milliseconds
 */
let lastFrameTime = 0.0;

/**
 * Entry point
 */
async function main() {
  const game = new Game("game");
  await game.init();

  const wasm = game.wasmInstance;
  
  // Available in assets.pas
  const {
    defaultFontPtr, defaultFontGlyphsPtr,
    setImgCursor, setImgDosuEXE
  } = wasm.exports;

  // Load default font
  await game.loadBMFont(
    "assets/fonts/nokia_cellphone_fc_8.txt",
    defaultFontPtr(), defaultFontGlyphsPtr());

  // Load assets
  setImgCursor(await game.loadImage("assets/images/cursor.png"));
  setImgDosuEXE(await game.loadImage("assets/images/dosu_1.png"), 0);
  setImgDosuEXE(await game.loadImage("assets/images/dosu_2.png"), 1);

  game.hideLoadingOverlay();
  wasm.exports.afterInit();

  function loop(currentTime) {
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
