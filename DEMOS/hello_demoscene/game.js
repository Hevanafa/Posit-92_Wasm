"use strict";

/**
 * Experimental boilerplate without the intro
 */
class Game extends Posit92 {
  AssetManifest = {
    images: {
      cursor: "assets/images/cursor.png",
      dosu_exe: [
        "assets/images/dosu_1.png",
        "assets/images/dosu_2.png"
      ]
      // Add more image assets here
    },
    sounds: new Map([
      // Add sound assets here
    ])
  }

  async LoadDefaultFont() {
    await this.LoadBMFont(
      "assets/fonts/nokia_cellphone_fc_8.txt",
      this.WasmInstance.exports.DefaultFontPtr(),
      this.WasmInstance.exports.DefaultFontGlyphsPtr());
  }

  /**
   * @override
   */
  async LoadAssets() {
    // this.initLoadingScreen();

    await this.LoadImagesFromManifest(this.AssetManifest.images);
    // Sounds can be loaded later
  }
}

const TargetFPS = 60;
const FrameTime = 1000 / TargetFPS;
/**
 * in milliseconds
 */
let lastFrameTime = 0.0;

var done = false;

async function Main() {
  const game = new Game("game");
  await game.InitRuntime();
  await game.LoadDefaultFont();

  game.QuickStart();

  function Loop(currentTime) {
    if (done) {
      game.Cleanup();
      return;
    }

    const elapsed = currentTime - lastFrameTime;

    if (elapsed >= FrameTime) {
      lastFrameTime = currentTime - (elapsed % FrameTime);  // Carry over extra time
      game.Update();
      game.Draw();
    }

    requestAnimationFrame(Loop)
  }

  requestAnimationFrame(Loop)
}

function Play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay);

  Main()
}
