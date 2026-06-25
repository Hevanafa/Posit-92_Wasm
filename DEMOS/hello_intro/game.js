"use strict";

/**
 * Experimental boilerplate (full)
 */
class Game extends Posit92 {
  AssetManifest = {
    images: {
      cursor: "assets/images/cursor.png"
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
    let handle = 0;

    this.InitLoadingScreen();

    await this.LoadImagesFromManifest(this.AssetManifest.images);
    // Sounds can be loaded later

    handle = await this.LoadImage("assets/images/dosu_1.png");
    this.WasmInstance.exports.SetImgDosuEXE(handle, 0);
    handle = await this.LoadImage("assets/images/dosu_2.png");
    this.WasmInstance.exports.SetImgDosuEXE(handle, 1);

    // Add more assets as necessary
  }

  async Init() {
    this.SetLoadingText("Downloading engine...");
    await super.Init();
  }

  /**
   * @override
   */
  OnWasmProgress(loaded, total) {
    const loadedKB = Math.ceil(loaded / 1024);
    const totalKB = Math.ceil(total / 1024);

    this.SetLoadingText(`Downloading engine... ${loadedKB} / ${totalKB} KB`)
  }

  async LoadIntro() {
    this.WasmInstance.exports.SetImgPosit92Logo(
      await this.LoadImage("assets/images/posit-92_32px.png"));

    this.WasmInstance.exports.SetImgFPCLogo(
      await this.LoadImage("assets/images/fpc_logo.png"));

    this.WasmInstance.exports.SetImgWasmLogo(
      await this.LoadImage("assets/images/wasm_logo.png"));
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

  await game.LoadIntro();
  game.BeginIntro();

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
