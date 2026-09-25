"use strict";

class Game extends BMFontMixin(Posit92) {
  async loadAssets() {
    let handle = 0;

    handle = await this.loadImage("assets/images/cursor.png");
    this.wasmInstance.exports.setImgCursor(handle);

    await this.loadBMFont(
      "assets/fonts/nokia_cellphone_fc_8.txt",
      this.wasmInstance.exports.defaultFontPtr(),
      this.wasmInstance.exports.defaultFontGlyphsPtr());

    handle = await this.loadImage("assets/images/dosu_1.png");
    this.wasmInstance.exports.setImgDosuEXE(handle, 0);
    handle = await this.loadImage("assets/images/dosu_2.png");
    this.wasmInstance.exports.setImgDosuEXE(handle, 1);

    handle = await this.loadImage("assets/images/pip-boy_100px.png");
    this.wasmInstance.exports.setImgPipBoy(handle);
    // Add more assets as necessary
  }
}

async function Main() {
  const game = new Game();
  await game.Start();
}

function Play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay);
  Main()
}

