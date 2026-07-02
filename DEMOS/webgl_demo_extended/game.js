"use strict";

// Game < WebGLMixin < Posit92
class Game extends WebGLMixin {
  async LoadGameAssets() {
    let handle = 0;

    handle = await this.LoadImage("assets/images/cursor.png");
    this.WasmInstance.exports.SetImgCursor(handle);

    await this.LoadBMFont(
      "assets/fonts/nokia_cellphone_fc_8.txt",
      this.WasmInstance.exports.DefaultFontPtr(),
      this.WasmInstance.exports.DefaultFontGlyphsPtr());

    handle = await this.LoadImage("assets/images/dosu_1.png");
    this.WasmInstance.exports.SetImgDosuEXE(handle, 0);
    handle = await this.LoadImage("assets/images/dosu_2.png");
    this.WasmInstance.exports.SetImgDosuEXE(handle, 1);

    // Add more assets as necessary
  }

  /**
   * @returns {WebGLRenderingContext}
   */
  get gl() { return this.glCtx; }

  /**
   * @override
   */
  Draw() {
    this.WasmInstance.exports.Draw();

    const vertices = new Float32Array([
      0.0, 0.5,
      -0.5, -0.5,
      0.5, -0.5
    ]);

    const buffer = this.gl.createBuffer();
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, buffer);
    this.gl.bufferData(this.gl.ARRAY_BUFFER, vertices, this.gl.STATIC_DRAW);

    const shaders = glsl`
// vertex
attribute vec2 aPosition;
void main() {
  gl_Position = vec4(aPosition, 0.0, 1.0);
}

precision mediump float;
void main() {
  // rgba
  gl_FragColor = vec4(0.39, 0.58, 0.93, 1.0);
}
    `;

    // TODO: Link the attribute
    // TODO: call drawArrays

  }
}

async function Main() {
  const game = new Game("game", { renderer: "webgl" });
  await game.Start();
}

function Play() {
  const overlay = document.getElementById("play-overlay");
  overlay.parentNode.removeChild(overlay)

  Main()
}
