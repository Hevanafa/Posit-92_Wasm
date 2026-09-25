"use strict";

class Game extends BMFontMixin(Posit92) {
  async loadAssets() {
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
