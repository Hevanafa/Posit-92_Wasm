precision mediump float;
varying vec2 uv;
uniform sampler2D tex;

void main() {
  gl_FragColor = texture2D(tex, vec2(uv.x, 1.0 - uv.y));
}
