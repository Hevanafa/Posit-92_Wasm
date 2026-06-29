"use strict";

const
  SfxBwonk = 1,
  SfxBite = 2,
  SfxBonk = 3,
  SfxStrum = 4,
  SfxSlip = 5;

// Game < SoundsMixin < Posit92
class Game extends SoundsMixin {
  /**
   * KeyboardEvent.code to DOS scancode
   */
  ScancodeMap = {
    "Escape": 0x01,
    "Space": 0x39,

    "Digit1": 0x02,
    "Digit2": 0x03,
    "Digit3": 0x04,
    "Digit4": 0x05,
    "Digit5": 0x06
    // Add more scancodes as necessary
  };

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

  async LoadDefaultFont() {
    await this.LoadBMFont(
      "assets/fonts/nokia_cellphone_fc_8.txt",
      this.WasmInstance.exports.DefaultFontPtr(),
      this.WasmInstance.exports.DefaultFontGlyphsPtr());
  }

  async LoadAssets() {
    this.InitLoadingScreen();
    await this.LoadImagesFromManifest(this.AssetManifest.images);
    await this.LoadSoundsFromManifest(this.AssetManifest.sounds);
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
  await game.Init();
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
  overlay.parentNode.removeChild(overlay)

  Main()
}
