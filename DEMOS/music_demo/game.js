"use strict";

class Game extends SoundMixin(BMFontMixin(Posit92)) {
  async LoadGameAssets() {
    await this.LoadSound(
      BgmClassic,
      "assets/bgm/Georges Bizet - Les Toreadors from Carmen Suite No. 1.ogg");

    // Add more assets as necessary
  }
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
