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
  const game = new Game("game", { defaultFont: false });
  await game.Start();
}
