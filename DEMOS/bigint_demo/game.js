"use strict";

// Compose: innermost mixin applies first
class Game extends BigIntMixin(BMFontMixin(Posit92)) {
  AssetManifest = {
    images: {
      cursor: "assets/images/cursor.png"
      // Add more image assets here
    },
    sounds: new Map([
      // Add sound assets here
    ])
  }

  async LoadGameAssets() {
    let handle = 0;

    this.InitLoadingScreen();
    await this.LoadImagesFromManifest(this.AssetManifest.images);

    handle = await this.LoadImage("assets/images/dosu_1.png");
    this.WasmInstance.exports.SetImgDosuEXE(handle, 0);
    handle = await this.LoadImage("assets/images/dosu_2.png");
    this.WasmInstance.exports.SetImgDosuEXE(handle, 1);

    // Add more assets as necessary
  }
}

console.log(Game.name);
console.log(Object.getPrototypeOf(Game).name);
console.log("SetupImportObject", BMFontMixin.SetupImportObject)

async function Main() {
  const game = new Game("game");
  await game.Start();
}

function Play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay)

  Main()
}
