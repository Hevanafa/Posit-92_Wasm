"use strict";

/**
 * Minimal Boilerplate
 */
class Game extends Posit92 {
}

/**
 * Entry point
 */
async function main() {
  const game = new Game("game");
  await game.init();

  game.hideLoadingOverlay();
  game.wasmInstance.exports.afterInit();

  function loop() {
    game.update();
    game.draw();
    requestAnimationFrame(loop)
  }
  requestAnimationFrame(loop)
}
