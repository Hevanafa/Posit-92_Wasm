class WebGLMixin extends Posit92 {
  // WebAssembly initialisation happens in the parent class Posit92

  /**
   * @type {WebGLRenderingContext}
   */
  #gl;

  /**
   * @type {Map<number, WebGLTexture>}
   */
  #textures = new Map();
  #nextTextureId = 1;

  /**
   * @type {Map<number, WebGLShader>}
   */
  #shaders = new Map();
  #nextShaderId = 1;

  /**
   * @type {Map<number, WebGLProgram>}
   */
  #programs = new Map();
  #nextProgramId = 1;

  /**
   * @type {Map<number, WebGLBuffer>}
   */
  #buffers = new Map();
  #nextBufferId = 1;

  /**
   * @type {Map<number, WebGLUniformLocation>}
   */
  #uniformLocations = new Map();
  #nextUniformId = 1;

  #setupImportObject() {
    const { env } = super._getWasmImportObject();

    Object.assign(env, {
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

  /**
   * @override
   */
  async init() {
    // Important: this.#ctx initialisation must be turned off
    this.#gl = this._getCanvas().getContext("webgl") ?? this._getCanvas().getContext("experimental-webgl");

    if (this.#gl == null)
      throw new Error("WebGL is not supported!");

    this.#setupImportObject();
    await super.init();
  }

  /**
   * @override
   */
  #assertNumber(value) {
    if (typeof value != "number")
      throw new Error(`Expected a number, but received ${typeof value}`);

    if (isNaN(value))
      throw new Error("Expected a number, but received NaN");
  }


  // WEBGL.PAS
  #readCString(ptr) {
    this.#assertNumber(ptr);

    const memory = new Uint8Array(this.wasmInstance.exports.memory.buffer);
    let end = ptr;
    while (memory[end] != 0) end++;  // Find null terminator

    const bytes = memory.subarray(ptr, end);
    return new TextDecoder().decode(bytes)
  }


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
      this.wasmInstance.exports.memory.buffer,
      pixelsPtr,
      width * height * 4);

    this.#gl.texImage2D(
      target, level, internalFormat,
      width, height, border,
      format, type, pixels)
  }


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
      this.wasmInstance.exports.memory.buffer,
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


  #glGetUniformLocation(programId, namePtr) {
    const program = this.#programs.get(programId);
    const name = this.#readCString(namePtr);
    const location = this.#gl.getUniformLocation(program, name);

    const id = this.#nextUniformId++;
    this.#uniformLocations.set(id, location);
    return id
  }

  #glUniform1i(locationId, value) {
    // console.log("unifLoc", locationId, value);
    const loc = this.#uniformLocations.get(locationId);
    this.#gl.uniform1i(loc, value)
  }

  #glActiveTexture(texture) {
    this.#gl.activeTexture(texture)
  }
}
