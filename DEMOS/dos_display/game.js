"use strict";

class Game extends SoundMixin(BMFontMixin(Posit92)) {
  SetupImportObject() {
    super.SetupImportObject();

    const { env } = this.WasmImportObject;

    Object.assign(env, {
      JsQueryDate: () => {
        this.WriteInteropBuffer(
          new Date().toLocaleDateString("en-AU").replace(/\//g, "-"))
      },
      JsQueryTime: () => {
        const now = new Date();
        
        this.WriteInteropBuffer(
          now.getHours().toString().padStart(2, "0") + ":" +
          now.getMinutes().toString().padStart(2, "0") + ":" +
          now.getSeconds().toString().padStart(2, "0"))
      }
    })
  }
}

async function Main() {
  const game = new Game();
  await game.Start();
}

function Play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay)
  Main()
}
