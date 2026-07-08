"use strict";

class Game extends SoundMixin(BMFontMixin(Posit92)) {
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
        setter: "BlackFontPtr",
        glyphSetter: "BlackFontGlyphsPtr"
      },
      picotron: {
        path: "assets/fonts/picotron_8px.txt",
        setter: "PicotronFontPtr",
        glyphSetter: "PicotronFontGlyphsPtr"
      }
    }
  }

  async LoadGameAssets() {
    this.InitLoadingScreen();
    await this.LoadImagesFromManifest(this.AssetManifest.images);
    await this.LoadBMFontFromManifest(this.AssetManifest.bmfonts);
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
