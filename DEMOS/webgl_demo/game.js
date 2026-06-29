"use strict";

// Game < WebGLMixin < Posit92
class Game extends WebGLMixin {
  /**
   * KeyboardEvent.code to DOS scancode
   */
  ScancodeMap = {
    "Escape": 0x01,
    "Space": 0x39
    // Add more scancodes as necessary
  };

  async LoadAssets() {
    let handle = 0;

    handle = await this.LoadImage("assets/images/cursor.png");
    this.wasmInstance.exports.SetImgCursor(handle);

    await this.LoadBMFont(
      "assets/fonts/nokia_cellphone_fc_8.txt",
      this.wasmInstance.exports.DefaultFontPtr(),
      this.wasmInstance.exports.DefaultFontGlyphsPtr());

    handle = await this.LoadImage("assets/images/dosu_1.png");
    this.wasmInstance.exports.SetImgDosuEXE(handle, 0);
    handle = await this.LoadImage("assets/images/dosu_2.png");
    this.wasmInstance.exports.SetImgDosuEXE(handle, 1);

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

async function Main() {
  const game = new Game("game");
  await game.Init();
  game.AfterInit();

  function Loop(currentTime) {
    if (done) {
      game.Cleanup();
      return;
    }

    const elapsed = currentTime - lastFrameTime;

    if (elapsed >= FrameTime) {
      lastFrameTime = currentTime - (elapsed % FrameTime);  // Carry over extra time
      game.Update();
      game.Draw();
    }

    requestAnimationFrame(Loop)
  }

  requestAnimationFrame(Loop)
}

function Play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay)

  Main()
}
