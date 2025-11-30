class WebGLGame extends Posit92 {
  #wasmSource = "game.wasm";

  /**
   * @type {WebAssembly.Instance}
   */
  #wasm;
  get wasmInstance() { return this.#wasm }

  /**
   * @type {WebGLRenderingContext}
   */
  #gl;

  /**
   * For use with WebAssembly init
   */
  #importObject = null;

  #setupImportObject() {
    this.#importObject = this._getWasmImportObject();
    const env = this.#importObject.env;

    this.#importObject = Object.assign(
      env, {
        // WebGL
        glClearColor: (r, g, b, a) => this.#gl.clearColor(r, g, b, a),
        glClear: mask => this.#gl.clear(mask),
        glViewport: (x, y, w, h) => this.#gl.viewport(x, y, w, h),
        glCreateTexture: this.#glCreateTexture.bind(this),

        glBindTexture: this.#glBindTexture.bind(this),
        glTexParameteri: this.#glTextParameteri.bind(this),
        glTexImage2D: this.#glTexImage2D.bind(this),

        glCreateShader: this.#glCreateShader.bind(this),
        glShaderSource: this.#glShaderSource.bind(this),
        glCompileShader: this.#glCompileShader.bind(this),
        glCreateProgram: this.#glCreateProgram.bind(this),
        glAttachShader: this.#glAttachShader.bind(this),
        glLinkProgram: this.#glLinkProgram.bind(this),
        glUseProgram: this.#glUseProgram.bind(this),

        glCreateBuffer: this.#glCreateBuffer.bind(this),
        glBindBuffer: this.#glBindBuffer.bind(this),
        glBufferData: this.#glBufferData.bind(this),
        glGetAttribLocation: this.#glGetAttribLocation.bind(this),
        glEnableVertexAttribArray: this.#glEnableVertexAttribArray.bind(this),
        glVertexAttribPointer: this.#glVertexAttribPointer.bind(this),
        glDrawArrays: this.#glDrawArrays.bind(this),

        glGetUniformLocation: this.#glGetUniformLocation.bind(this),
        glUniform1i: this.#glUniform1i.bind(this),

        glActiveTexture: this.#glActiveTexture.bind(this)
      });
  }

  async init() {
    this.#setupImportObject();

    // Important: this.#ctx initialisation must be turned off
    this.#gl = this._getCanvas().getContext("webgl") ?? this._getCanvas().getContext("experimental-webgl");

    if (this.#gl == null)
      throw new Error("WebGL is not supported!");

    await this.#initWebAssembly();
    this.#wasm.exports.init();

    await super.init();
  }

  async afterinit() {
    await super.afterinit()
  }

  /**
   * Important: #initWebAssembly in the parent class must be turned off
   * @override
   */
  async #initWebAssembly() {
    const response = await fetch(this.#wasmSource);
    const bytes = await response.arrayBuffer();
    const result = await WebAssembly.instantiate(bytes, this.#importObject);
    this.#wasm = result.instance;

    // Grow Wasm memory size
    // Wasm memory grows in 64KB pages
    const pages = this.#wasm.exports.memory.buffer.byteLength / 65536;
    const requiredPages = Math.ceil(2 * 1048576 / 65536);

    if (pages < requiredPages)
      this.#wasm.exports.memory.grow(requiredPages - pages);
  }

  cleanup() { super.cleanup() }

  // Game loop
  update() { super.update() }
  draw() { super.draw() }

  /**
   * @override
   */
  #assertNumber(value) {
    if (typeof value != "number")
      throw new Error(`Expected a number, but received ${typeof value}`);

    if (isNaN(value))
      throw new Error("Expected a number, but received NaN");
  }

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
