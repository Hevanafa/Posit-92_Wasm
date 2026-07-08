"use strict";

/**
 * Experimental boilerplate without the intro
 * 
 * Game < BMFontMixin < Posit92
 */
class Game extends SoundMixin(BMFontMixin(Posit92)) {
}

async function Main() {
  const game = new Game("game");
  game.Start();
}

function Play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay);

  Main()
}
