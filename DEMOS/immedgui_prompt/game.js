"use strict";

class Game extends BMFontMixin(Posit92) {
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

    await this.loadBMFont(
      "assets/fonts/nokia_cellphone_fc_8.txt",
      this.wasmInstance.exports.blackFontPtr(),
      this.wasmInstance.exports.blackFontGlyphsPtr());

    await this.loadBMFont(
      "assets/fonts/picotron_8px.txt",
      this.wasmInstance.exports.picotronFontPtr(),
      this.wasmInstance.exports.picotronFontGlyphsPtr());
  }
}

async function Main() {
  const game = new Game("game");
  await game.Start();
}

function Play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay);
  Main();
}
