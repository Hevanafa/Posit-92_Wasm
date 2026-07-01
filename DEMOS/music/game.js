"use strict";

const
  BgmClassic = 1;

// Game < SoundsMixin < Posit92
class Game extends SoundsMixin {
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
  async loadAssets() {
    let handle = 0;

    this.initLoadingScreen();

    await this.loadImagesFromManifest(this.AssetManifest.images);

    handle = await this.loadImage("assets/images/dosu_1.png");
    this.wasmInstance.exports.setImgDosuEXE(handle, 0);
    handle = await this.loadImage("assets/images/dosu_2.png");
    this.wasmInstance.exports.setImgDosuEXE(handle, 1);

    this.wasmInstance.exports.setImgPlay(
      await this.loadImage("assets/images/play.png"));
    this.wasmInstance.exports.setImgStop(
      await this.loadImage("assets/images/stop.png"));
    this.wasmInstance.exports.setImgPause(
      await this.loadImage("assets/images/pause.png"));

    this.wasmInstance.exports.setImgVolumeOn(
      await this.loadImage("assets/images/volume_on.png"));
    this.wasmInstance.exports.setImgVolumeOff(
      await this.loadImage("assets/images/volume_off.png"));

    await this.loadSound(BgmClassic, "assets/bgm/Georges Bizet - Les Toreadors from Carmen Suite No. 1.ogg");

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
