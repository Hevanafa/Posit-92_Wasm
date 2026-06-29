class WebGLMixin extends Posit92 {
  // WebAssembly initialisation happens in the parent class Posit92

  /**
   * @type {WebGLRenderingContext}
   */
  glCtx;

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

  /**
   * @override
   */
  SetupImportObject() {
    const { env } = this.WasmImportObject;

    console.log("SetupImportObject call");

    Object.assign(env, {
      // WebGL
      glClearColor: (r, g, b, a) => this.glCtx.clearColor(r, g, b, a),
      glClear: mask => this.glCtx.clear(mask),
      glViewport: (x, y, w, h) => this.glCtx.viewport(x, y, w, h),
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
  // async Init() {
  //   // Important: this.#ctx initialisation must be turned off
  //   this.#ctx = this.Canvas.getContext("webgl") ?? this.Canvas.getContext("experimental-webgl");

  //   if (this.#ctx == null)
  //     throw new Error("WebGL is not supported!");

  //   this.SetupImportObject();
  //   await super.Init();
  // }

  /**
   * @override
   */
  #AssertNumber(value) {
    if (typeof value != "number")
      throw new Error(`Expected a number, but received ${typeof value}`);

    if (isNaN(value))
      throw new Error("Expected a number, but received NaN");
  }


  // WEBGL.PAS
  #ReadCString(ptr) {
    this.#AssertNumber(ptr);

    const memory = new Uint8Array(this.WasmInstance.exports.memory.buffer);
    let end = ptr;
    while (memory[end] != 0) end++;  // Find null terminator

    const bytes = memory.subarray(ptr, end);
    return new TextDecoder().decode(bytes)
  }


  #glCreateTexture() {
    const texture = this.glCtx.createTexture();
    const id = this.#nextTextureId++;
    console.log("id", id, this.#nextTextureId);
    this.#textures.set(id, texture);
    return 1
  }

  #glBindTexture(target, textureId) {
    const texture = this.#textures.get(textureId);
    this.glCtx.bindTexture(target, texture)
  }

  #glTextParameteri(target, pname, param) {
    this.glCtx.texParameteri(target, pname, param)
  }

  #glTexImage2D(
    target, level, internalFormat,
    width, height, border,
    format, type, pixelsPtr) {

    const pixels = new Uint8Array(
      this.WasmInstance.exports.memory.buffer,
      pixelsPtr,
      width * height * 4);

    this.glCtx.texImage2D(
      target, level, internalFormat,
      width, height, border,
      format, type, pixels)
  }


  #glCreateShader(type) {
    const shader = this.glCtx.createShader(type);
    const id = this.#nextShaderId++;
    this.#shaders.set(id, shader);
    return id
  }

  #glShaderSource(shaderId, sourcePtr) {
    const shader = this.#shaders.get(shaderId);
    const source = this.#ReadCString(sourcePtr);
    this.glCtx.shaderSource(shader, source)
  }

  #glCompileShader(shaderId) {
    const shader = this.#shaders.get(shaderId);
    this.glCtx.compileShader(shader)
  }

  #glCreateProgram() {
    const program = this.glCtx.createProgram();
    const id = this.#nextProgramId++;
    this.#programs.set(id, program);
    return id
  }

  #glAttachShader(programId, shaderId) {
    const program = this.#programs.get(programId);
    const shader = this.#shaders.get(shaderId);
    this.glCtx.attachShader(program, shader)
  }

  #glLinkProgram(programId) {
    const program = this.#programs.get(programId);
    this.glCtx.linkProgram(program)
  }

  #glUseProgram(programId) {
    const program = this.#programs.get(programId);
    this.glCtx.useProgram(program)
  }


  #glCreateBuffer() {
    const buffer = this.glCtx.createBuffer();
    const id = this.#nextBufferId++;
    this.#buffers.set(id, buffer);
    return id
  }

  #glBindBuffer(target, bufferId) {
    const buffer = this.#buffers.get(bufferId);
    this.glCtx.bindBuffer(target, buffer)
  }

  #glBufferData(target, size, dataPtr, usage) {
    const data = new Float32Array(
      this.WasmInstance.exports.memory.buffer,
      dataPtr,
      size / 4
    );
    this.glCtx.bufferData(target, data, usage)
  }

  #glGetAttribLocation(programId, namePtr) {
    const program = this.#programs.get(programId);
    const name = this.#ReadCString(namePtr);
    return this.glCtx.getAttribLocation(program, name)
  }

  #glEnableVertexAttribArray(idx) {
    this.glCtx.enableVertexAttribArray(idx)
  }

  #glVertexAttribPointer(idx, size, type, normalized, stride, offset) {
    this.glCtx.vertexAttribPointer(idx, size, type, normalized, stride, offset)
  }

  #glDrawArrays(mode, first, count) {
    let err = this.glCtx.getError();
    if (err != 0)
      throw new Error("WebGL error before draw:", err);

    this.glCtx.drawArrays(mode, first, count);

    err = this.glCtx.getError();
    if (err != 0)
      throw new Error("WebGL error after draw:", err);
  }


  #glGetUniformLocation(programId, namePtr) {
    const program = this.#programs.get(programId);
    const name = this.#ReadCString(namePtr);
    const location = this.glCtx.getUniformLocation(program, name);

    const id = this.#nextUniformId++;
    this.#uniformLocations.set(id, location);
    return id
  }

  #glUniform1i(locationId, value) {
    // console.log("unifLoc", locationId, value);
    const loc = this.#uniformLocations.get(locationId);
    this.glCtx.uniform1i(loc, value)
  }

  #glActiveTexture(texture) {
    this.glCtx.activeTexture(texture)
  }
}
