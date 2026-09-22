"use strict";

class Game extends BMFontMixin(Posit92) {
  async loadDefaultFont() {
    await this.loadBMFont(
      "assets/fonts/ms_sans_serif_10px_regular.txt",
      this.wasmInstance.exports.defaultFontPtr(),
      this.wasmInstance.exports.defaultFontGlyphsPtr());
  }

  /**
   * @override
   */
  async loadAssets() {
    this.initLoadingScreen();

    await this.loadImagesFromManifest(this.AssetManifest.images);

    await this.loadBMFont(
      "assets/fonts/ms_sans_serif_10px_bold.txt",
      this.wasmInstance.exports.boldFontPtr(),
      this.wasmInstance.exports.boldFontGlyphsPtr());

    await this.loadBMFont(
      "assets/fonts/ms_sans_serif_10px_italic.txt",
      this.wasmInstance.exports.italicFontPtr(),
      this.wasmInstance.exports.italicFontGlyphsPtr());

    await this.loadBMFont(
      "assets/fonts/ms_sans_serif_10px_bold_italic.txt",
      this.wasmInstance.exports.boldItalicFontPtr(),
      this.wasmInstance.exports.boldItalicFontGlyphsPtr());
  }
}

async function Main() {
  const game = new Game("game", { LoadDefaultBMFont: false });
  await game.Start();
}

function Play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay);
  Main();
}
