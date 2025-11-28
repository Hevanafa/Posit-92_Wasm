"use strict";

// Asset boilerplate
class Game extends Posit92 {
  async loadAssets() {
    const imgCursor = await this.loadImage("assets/images/cursor.png");
    this.wasmInstance.exports.setImgCursor(imgCursor);

    const imgGasolineMaid = await this.loadImage("assets/images/gasoline_maid_100px.png")
    this.wasmInstance.exports.setImgGasolineMaid(imgGasolineMaid);

    await this.loadBMFont(
      "assets/fonts/nokia_cellphone_fc_8.txt",
      this.wasmInstance.exports.defaultFontPtr(),
      this.wasmInstance.exports.defaultFontGlyphsPtr());

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
      lastFrameTime = currentTime - (elapsed % FrameTime);  // Carry over extra time;
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

// main()
