"use strict";

/**
 * Experimental boilerplate without the intro
 * 
 * Game < BMFontMixin < Posit92
 */
class Game extends BMFontMixin {
  // AssetManifest = {
  //   images: {
  //     cursor: "assets/images/cursor.png",
  //     dosu_exe: [
  //       "assets/images/dosu_1.png",
  //       "assets/images/dosu_2.png"
  //     ]
  //     // Add more image assets here
  //   },
  //   sounds: new Map([
  //     // Add sound assets here
  //   ])
  // }

  // /**
  //  * @override
  //  */
  async LoadGameAssets() {
    super.LoadGameAssets();
    // await this.LoadImagesFromManifest(this.AssetManifest.images);
    
    // Sounds can be loaded later
  }
}

async function Main() {
  const game = new Game("game", { skipIntro: true, fps: 0 });
  game.Start();
}

function Play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay);

  Main()
}
