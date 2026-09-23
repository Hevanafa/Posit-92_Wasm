"use strict";

class Game extends BMFontMixin(Posit92) {
  AssetManifest = {
    images: {
      cursor: "assets/images/cursor.png",
      hand_cursor: "assets/images/hand.png",
      slime_girl: "assets/images/piyo_0426_slime_girl.png",
      blue_enemy: "assets/images/blue_enemy.png"
    }
  }
}

async function Main() {
  const game = new Game();
  game.Start();
}

function Play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay);
  Main()
}
