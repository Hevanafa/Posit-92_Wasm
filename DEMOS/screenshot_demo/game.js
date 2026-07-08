"use strict";

class Game extends SoundMixin(BMFontMixin(Posit92)) {
  AssetManifest = {
    images: {
      cursor: "assets/images/cursor.png",
      dosu_exe: [
        "assets/images/dosu_1.png",
        "assets/images/dosu_2.png"
      ]
      // Add more image assets here
    },
    sounds: new Map([
      // Add sound assets here
    ])
  }

  #setupImportObject() {
    const { env } = super._getWasmImportObject();

    Object.assign(env, {
      takeScreenshot: () => {
        console.log("takeScreenshot call")
        console.log("canvasID", this.canvasID);

        /**
         * @type {HTMLCanvasElement}
         */
        const canvas = document.getElementById(this.canvasID);

        const now = new Date();

        const timestampStr =
          now.toISOString().split("T")[0]
          + "_"
          + now.toISOString().split("T")[1].split(".")[0].replace(/:/g,".");

        console.log("timestampStr", timestampStr);

        const anchor = document.createElement("a");
        anchor.href = canvas.toDataURL();
        anchor.download = timestampStr + ".png";
        anchor.click();
      }
    })
  }

  canvasID = "";

  /**
   * @override
   */
  constructor(canvasID, vgaWidth = 320, vgaHeight = 200) {
    super(canvasID, vgaWidth, vgaHeight);

    this.canvasID = canvasID;
  }
}

async function Main() {
  const game = new Game("game");
  await game.Start();
}

function Play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay);
  Main()
}
