"use strict";

/**
 * Experimental boilerplate without the intro
 */
class Game extends GamepadMixin {
  AssetManifest = {
    images: {
      cursor: "assets/images/cursor.png"
      // Add more image assets here
    },
    sounds: new Map([
      // Add sound assets here
    ])
  }

  /**
   * @override
   */
  async LoadGameAssets() {
    let handle = 0;

    this.InitLoadingScreen();

    await this.LoadImagesFromManifest(this.AssetManifest.images);
    // Sounds can be loaded later

    handle = await this.LoadImage("assets/images/dosu_1.png");
    this.WasmInstance.exports.setImgDosuEXE(handle, 0);
    handle = await this.LoadImage("assets/images/dosu_2.png");
    this.WasmInstance.exports.setImgDosuEXE(handle, 1);

    // Add more assets as necessary
  }
}

async function Main() {
  const game = new Game("game");
  await game.Start();
}

function Play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay);

  Main()
}
