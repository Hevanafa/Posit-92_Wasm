"use strict";

class Game extends SoundMixin(BMFontMixin(Posit92)) {
  AssetManifest = {
    images: {
      CGA_font: "assets/images/CGA8x8.png",
      cursor: "assets/images/cursor.png"
    },
    sounds: new Map([
      [this.BgmJingle, "assets/ogg/Jingle Bells (Chiptune Version) - Chiptune Arcade.ogg"]
    ])
  }

  SetupImportObject() {
    const { env } = super._getWasmImportObject();

    Object.assign(env, {
      queryDate: () => {
        this.#loadStringBuffer(new Date().toLocaleDateString("en-AU").replace(/\//g, "-"))
      },
      queryTime: () => {
        const now = new Date();
        
        this.#loadStringBuffer(
          now.getHours().toString().padStart(2, "0") + ":" +
          now.getMinutes().toString().padStart(2, "0") + ":" +
          now.getSeconds().toString().padStart(2, "0"))
      }
    })
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
