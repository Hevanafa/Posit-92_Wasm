"use strict";

// Game < WebGLMixin < BMFontMixin < Posit92
class Game extends WebGLMixin(BMFontMixin(Posit92)) {
}

async function Main() {
  const game = new Game("game", { renderer: "webgl" });
  await game.Start();
}

function Play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay)

  Main()
}
