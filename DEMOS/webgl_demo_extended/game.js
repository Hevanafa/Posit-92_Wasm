"use strict";

// Game < WebGLMixin < Posit92
class Game extends WebGLMixin {
  async LoadGameAssets() {
    let handle = 0;

    handle = await this.LoadImage("assets/images/cursor.png");
    this.WasmInstance.exports.SetImgCursor(handle);

    await this.LoadBMFont(
      "assets/fonts/nokia_cellphone_fc_8.txt",
      this.WasmInstance.exports.DefaultFontPtr(),
      this.WasmInstance.exports.DefaultFontGlyphsPtr());

    handle = await this.LoadImage("assets/images/dosu_1.png");
    this.WasmInstance.exports.SetImgDosuEXE(handle, 0);
    handle = await this.LoadImage("assets/images/dosu_2.png");
    this.WasmInstance.exports.SetImgDosuEXE(handle, 1);

    // Add more assets as necessary
  }
}

async function Main() {
  const game = new Game("game", { renderer: "webgl" });
  await game.Start();
}

function Play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay)

  Main()
}
