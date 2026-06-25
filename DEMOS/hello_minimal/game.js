"use strict";

/**
 * Minimal Boilerplate
 */
class Game extends Posit92 {
}

/**
 * Entry point
 */
async function Main() {
  const game = new Game("game");
  await game.Init();

  game.HideLoadingOverlay();
  game.WasmInstance.exports.AfterInit();

  function Loop() {
    game.Update();
    game.Draw();
    requestAnimationFrame(Loop)
  }

  requestAnimationFrame(Loop)
}
