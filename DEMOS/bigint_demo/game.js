"use strict";

// Game < BigIntMixin < BMFontMixin < Posit92
class Game extends BigIntMixin(BMFontMixin(Posit92)) {
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
