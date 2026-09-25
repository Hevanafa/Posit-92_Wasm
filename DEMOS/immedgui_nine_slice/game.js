"use strict";

class Game extends BMFontMixin(Posit92) {
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
