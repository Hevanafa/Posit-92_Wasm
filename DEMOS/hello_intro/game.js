"use strict";

/**
 * Experimental boilerplate with intro
 */
class Game extends BMFontMixin(Posit92) {
  /**
   * @override
   */
  // OnWasmProgress(loaded, total) {
  //   const loadedKB = Math.ceil(loaded / 1024);
  //   const totalKB = Math.ceil(total / 1024);

  //   this.SetLoadingText(`Downloading engine... ${loadedKB} / ${totalKB} KB`)
  // }
}

async function Main() {
  const game = new Game("game", { skipIntro: false });
  game.Start();
}

function Play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay);

  Main()
}
