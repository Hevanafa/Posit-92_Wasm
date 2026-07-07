"use strict";

const
  BgmClassic = 1;

// Game < SoundMixin < Posit92
class Game extends SoundMixin {
  AssetManifest = {
    images: {
      cursor: "assets/images/cursor.png"
    },
    sounds: new Map([
    ])
  }

  /**
   * @override
   */
  async LoadGameAssets() {
    let handle = 0;

    this.InitLoadingScreen();

    await this.LoadImagesFromManifest(this.AssetManifest.images);

    handle = await this.LoadImage("assets/images/dosu_1.png");
    this.WasmInstance.exports.SetImgDosuEXE(handle, 0);
    handle = await this.LoadImage("assets/images/dosu_2.png");
    this.WasmInstance.exports.SetImgDosuEXE(handle, 1);

    this.WasmInstance.exports.SetImgPlay(
      await this.LoadImage("assets/images/play.png"));
    this.WasmInstance.exports.SetImgStop(
      await this.LoadImage("assets/images/stop.png"));
    this.WasmInstance.exports.SetImgPause(
      await this.LoadImage("assets/images/pause.png"));

    this.WasmInstance.exports.SetImgVolumeOn(
      await this.LoadImage("assets/images/volume_on.png"));
    this.WasmInstance.exports.SetImgVolumeOff(
      await this.LoadImage("assets/images/volume_off.png"));

    await this.LoadSound(
      BgmClassic,
      "assets/bgm/Georges Bizet - Les Toreadors from Carmen Suite No. 1.ogg");

    // Add more assets as necessary
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
