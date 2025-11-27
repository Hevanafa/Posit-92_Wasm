"use strict";

const
  SfxBwonk = 1,
  SfxBite = 2,
  SfxBonk = 3,
  SfxStrum = 4,
  SfxSlip = 5;

// Asset boilerplate
class Game extends Posit92 {
  async loadAssets() {
    let handle = 0;

    handle = await this.loadImage("assets/images/cursor.png");
    this.wasmInstance.exports.setImgCursor(handle);

    await this.loadBMFont("assets/fonts/nokia_cellphone_fc_8.txt");

    handle = await this.loadImage("assets/images/dosu_1.png");
    this.wasmInstance.exports.setImgDosuEXE(handle, 0);
    handle = await this.loadImage("assets/images/dosu_2.png");
    this.wasmInstance.exports.setImgDosuEXE(handle, 1);

    await this.loadSound(SfxBwonk, "assets/sfx/bwonk.ogg");
    await this.loadSound(SfxBite, "assets/sfx/bite.ogg");
    await this.loadSound(SfxBonk, "assets/sfx/bonk.ogg");
    await this.loadSound(SfxStrum, "assets/sfx/strum.ogg");
    await this.loadSound(SfxSlip, "assets/sfx/slip.ogg");

    // Add more assets as necessary
  }
}

const TargetFPS = 60;
const FrameTime = 1000 / 60.0;
/**
 * in milliseconds
 */
let lastFrameTime = 0.0;

var done = false;

async function main() {
  const game = new Game("game");
  await game.init();
  game.afterInit();

  function loop(currentTime) {
    if (done) {
      game.cleanup();
      return;
    }

    const elapsed = currentTime - lastFrameTime;

    if (elapsed >= FrameTime) {
      lastFrameTime = currentTime - (elapsed % FrameTime);  // Carry over extra time
      game.update();
      game.draw();
    }

    requestAnimationFrame(loop)
  }

  requestAnimationFrame(loop)
}

function play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay)

  main()
}
