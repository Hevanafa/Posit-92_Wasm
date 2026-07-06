"use strict";

class Game extends BMFontMixin(Posit92) {
}

async function Main() {
  const game = new Game("game", 240, 160);
  await game.Start();
}

function Play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay);

  Main()
}
