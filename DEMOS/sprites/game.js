"use strict";

class Game extends BMFontMixin(Posit92) {
  AssetManifest = {
    images: {
      cursor: "assets/images/cursor.png",
      hand_cursor: "assets/images/hand.png",
      slime_girl: "assets/images/piyo_0426_slime_girl.png",
      blue_enemy: "assets/images/blue_enemy.png"
    }
  }

  async loadDefaultFont() {
    await this.loadBMFont(
      "assets/fonts/nokia_cellphone_fc_8.txt",
      this.wasmInstance.exports.defaultFontPtr(),
      this.wasmInstance.exports.defaultFontGlyphsPtr());
  }

  /**
   * @override
   */
  async loadAssets() {
    let handle = 0;

    this.initLoadingScreen();
    await this.loadImagesFromManifest(this.AssetManifest.images);

    handle = await this.loadImage("assets/images/dosu_1.png");
    this.wasmInstance.exports.setImgDosuEXE(handle, 0);
    handle = await this.loadImage("assets/images/dosu_2.png");
    this.wasmInstance.exports.setImgDosuEXE(handle, 1);
  }
}

async function Main() {
  const game = new Game();
  game.Start();
}

function Play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay);
  Main()
}
