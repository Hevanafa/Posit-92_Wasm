attribute vec2 a_pos;
varying vec2 uv;

void main() {
  uv = a_pos * 0.5 + 0.5;
  gl_Position = vec4(a_pos, 0.0, 1.0);
}