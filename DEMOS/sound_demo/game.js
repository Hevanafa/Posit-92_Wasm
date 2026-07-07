"use strict";

const
  SfxBwonk = 1,
  SfxBite = 2,
  SfxBonk = 3,
  SfxStrum = 4,
  SfxSlip = 5;

// Game < SoundsMixin < Posit92
class Game extends SoundsMixin {
  AssetManifest = {
    images: {
      cursor: "assets/images/cursor.png",
      dosu_exe: [
        "assets/images/dosu_1.png",
        "assets/images/dosu_2.png"
      ]
    },
    sounds: new Map([
      [SfxBwonk, "assets/sfx/bwonk.ogg"],
      [SfxBite, "assets/sfx/bite.ogg"],
      [SfxBonk, "assets/sfx/bonk.ogg"],
      [SfxStrum, "assets/sfx/strum.ogg"],
      [SfxSlip, "assets/sfx/slip.ogg"]
    ])
  }

  /**
   * @override
   */
  async LoadGameAssets() {
    this.InitLoadingScreen();
    await this.LoadImagesFromManifest(this.AssetManifest.images);
    await this.LoadSoundsFromManifest(this.AssetManifest.sounds);
  }
}

async function Main() {
  const game = new Game("game");
  await game.Start();
}

function Play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay)

  Main()
}
