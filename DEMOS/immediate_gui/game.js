"use strict";

class Game extends Posit92 {
  /**
   * KeyboardEvent.code to DOS scancode
   */
  ScancodeMap = {
    "Escape": 0x01,
    "Space": 0x39
    // Add more scancodes as necessary
  };

  AssetManifest = {
    images: {
      cursor: "assets/images/cursor.png",
      dosu: [
        "assets/images/dosu_1.png",
        "assets/images/dosu_2.png"
      ],
      hand_cursor: "assets/images/hand.png",
      
      win_normal: "assets/images/btn_normal.png",
      win_hovered: "assets/images/btn_hovered.png",
      win_pressed: "assets/images/btn_pressed.png"
    },
    bmfonts: {
      blackFont: {
        path: "assets/fonts/nokia_cellphone_fc_8.txt",
        setter: "blackFontPtr",
        glyphSetter: "blackFontGlyphsPtr"
      },
      picotron: {
        path: "assets/fonts/picotron_8px.txt",
        setter: "picotronFontPtr",
        glyphSetter: "picotronFontGlyphsPtr"
      }
    }
  }

  async loadDefaultFont() {
    await this.loadBMFont(
      "assets/fonts/nokia_cellphone_fc_8.txt",
      this.wasmInstance.exports.defaultFontPtr(),
      this.wasmInstance.exports.defaultFontGlyphsPtr());
  }

  async loadAssets() {
    this.initLoadingScreen();
    this.loadImagesFromManifest(this.AssetManifest.images);
    this.loadBMFontFromManifest(this.AssetManifest.bmfonts);

    // handle = await this.loadImage("assets/images/dosu_2.png");
    // this.wasmInstance.exports.setImgDosuEXE(handle, 1);

    // Add more assets as necessary
  }
}

const TargetFPS = 60;
const FrameTime = 1000 / TargetFPS;
/**
 * in milliseconds
 */
let lastFrameTime = 0.0;

var done = false;

async function main() {
  const game = new Game("game");
  await game.init();
  await game.loadDefaultFont();

  game.quickStart();

  function loop(currentTime) {
    if (done) {
      game.cleanup();
      return;
    }

    const elapsed = currentTime - lastFrameTime;

    if (elapsed >= FrameTime) {
      lastFrameTime = currentTime - (elapsed % FrameTime);  // Carry over extra time
      game.update();
      game.draw();
    }

    requestAnimationFrame(loop)
  }

  requestAnimationFrame(loop)
}

function play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay)

  main()
}
