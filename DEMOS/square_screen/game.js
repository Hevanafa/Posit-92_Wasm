"use strict";

class Game extends BMFontMixin(Posit92) {
  AssetManifest = {
    images: {
      cursor: "assets/images/cursor.png"
    }
  }
}

async function Main() {
  const game = new Game("game", 128, 128);
  await game.Start();
}

function Play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay)

  Main()
}
