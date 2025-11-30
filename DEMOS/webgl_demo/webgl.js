class WebGLGame extends Posit92 {
  /**
   * @type {WebGLRenderingContext}
   */
  #gl;

	async init() {
    await super.init()

    // Important: #ctx initialisation must be turned off
    this.#gl = this.#canvas.getContext("webgl") ?? this.#canvas.getContext("experimental-webgl");

    if (this.#gl == null)
      throw new Error("WebGL is not supported!");
  }

  // TODO: Override initWebAssembly

  async afterinit() {
    await super.afterinit()
  }

  cleanup() { super.cleanup() }

  // Game loop
  update() { super.update() }
  draw() { super.draw() }

  // VGA.PAS
  /**
   * Superseded by flushWebGL in Pascal code
   */
  flush() { }

  // WEBGL.PAS
  #readCString(ptr) {
    this.#assertNumber(ptr);

    const memory = new Uint8Array(this.#wasm.exports.memory.buffer);
    let end = ptr;
    while (memory[end] != 0) end++;  // Find null terminator

    const bytes = memory.subarray(ptr, end);
    return new TextDecoder().decode(bytes)
  }

  /**
   * @type {Map<number, WebGLTexture>}
   */
  #textures = new Map();
  #nextTextureId = 1;

  #glCreateTexture() {
    const texture = this.#gl.createTexture();
    const id = this.#nextTextureId++;
    console.log("id", id, this.#nextTextureId);
    this.#textures.set(id, texture);
    return 1
  }

  #glBindTexture(target, textureId) {
    const texture = this.#textures.get(textureId);
    this.#gl.bindTexture(target, texture)
  }

  #glTextParameteri(target, pname, param) {
    this.#gl.texParameteri(target, pname, param)
  }

  #glTexImage2D(
    target, level, internalFormat,
    width, height, border,
    format, type, pixelsPtr) {

    const pixels = new Uint8Array(
      this.#wasm.exports.memory.buffer,
      pixelsPtr,
      width * height * 4);

    this.#gl.texImage2D(
      target, level, internalFormat,
      width, height, border,
      format, type, pixels)
  }

  #shaders = new Map();
  #nextShaderId = 1;
  #programs = new Map();
  #nextProgramId = 1;

  #glCreateShader(type) {
    const shader = this.#gl.createShader(type);
    const id = this.#nextShaderId++;
    this.#shaders.set(id, shader);
    return id
  }

  #glShaderSource(shaderId, sourcePtr) {
    const shader = this.#shaders.get(shaderId);
    const source = this.#readCString(sourcePtr);
    this.#gl.shaderSource(shader, source)
  }

  #glCompileShader(shaderId) {
    const shader = this.#shaders.get(shaderId);
    this.#gl.compileShader(shader)
  }

  #glCreateProgram() {
    const program = this.#gl.createProgram();
    const id = this.#nextProgramId++;
    this.#programs.set(id, program);
    return id
  }

  #glAttachShader(programId, shaderId) {
    const program = this.#programs.get(programId);
    const shader = this.#shaders.get(shaderId);
    this.#gl.attachShader(program, shader)
  }

  #glLinkProgram(programId) {
    const program = this.#programs.get(programId);
    this.#gl.linkProgram(program)
  }

  #glUseProgram(programId) {
    const program = this.#programs.get(programId);
    this.#gl.useProgram(program)
  }

  #buffers = new Map();
  #nextBufferId = 1;

  #glCreateBuffer() {
    const buffer = this.#gl.createBuffer();
    const id = this.#nextBufferId++;
    this.#buffers.set(id, buffer);
    return id
  }

  #glBindBuffer(target, bufferId) {
    const buffer = this.#buffers.get(bufferId);
    this.#gl.bindBuffer(target, buffer)
  }

  #glBufferData(target, size, dataPtr, usage) {
    const data = new Float32Array(
      this.#wasm.exports.memory.buffer,
      dataPtr,
      size / 4
    );
    this.#gl.bufferData(target, data, usage)
  }

  #glGetAttribLocation(programId, namePtr) {
    const program = this.#programs.get(programId);
    const name = this.#readCString(namePtr);
    return this.#gl.getAttribLocation(program, name)
  }

  #glEnableVertexAttribArray(idx) {
    this.#gl.enableVertexAttribArray(idx)
  }

  #glVertexAttribPointer(idx, size, type, normalized, stride, offset) {
    this.#gl.vertexAttribPointer(idx, size, type, normalized, stride, offset)
  }

  #glDrawArrays(mode, first, count) {
    let err = this.#gl.getError();
    if (err != 0)
      throw new Error("WebGL error before draw:", err);

    this.#gl.drawArrays(mode, first, count);

    err = this.#gl.getError();
    if (err != 0)
      throw new Error("WebGL error after draw:", err);
  }

  #uniformLocations = new Map();
  #nextUniformId = 1;

  #glGetUniformLocation(programId, namePtr) {
    const program = this.#programs.get(programId);
    const name = this.#readCString(namePtr);
    const location = this.#gl.getUniformLocation(program, name);

    const id = this.#nextUniformId++;
    this.#uniformLocations.set(id, location);
    return id
    // console.log("glGetUniformLocation name", name);
    // return this.#gl.getUniformLocation(program, name)
  }

  #glUniform1i(locationId, value) {
    console.log("unifLoc", locationId, value);
    const loc = this.#uniformLocations.get(locationId);
    this.#gl.uniform1i(loc, value)
  }

  #glActiveTexture(texture) {
    this.#gl.activeTexture(texture)
  }
}
