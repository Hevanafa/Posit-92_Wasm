class WebGLGame extends Posit92 {
  /**
   * @type {WebGLRenderingContext}
   */
  #gl;

  /**
   * For use with WebAssembly init
   */
  #importObject = Object.freeze({
    env: {
      _haltproc: this.#handleHaltProc.bind(this),

      hideCursor: () => this.hideCursor(),
      showCursor: () => this.showCursor(),

      wasmgetmem: this.#WasmGetMem.bind(this),

      // Keyboard
      isKeyDown: this.isKeyDown.bind(this),
      signalDone: this.#signalDone.bind(this),

      // Logger
      writeLogF32: value => console.log("Pascal (f32):", value),
      writeLogI32: value => console.log("Pascal (i32):", value),
      flushLog: () => this.pascalWriteLog(),

      // Mouse
      getMouseX: () => this.getMouseX(),
      getMouseY: () => this.getMouseY(),
      getMouseButton: () => this.getMouseButton(),

      // Panic
      panicHalt: this.panicHalt.bind(this),

      // Sounds
      playSound: this.#playSound.bind(this),
      setSoundVolume: this.#setSoundVolume.bind(this),

      playMusic: this.#playMusic.bind(this),
      pauseMusic: this.#pauseMusic.bind(this),
      stopMusic: this.#stopMusic.bind(this),
      seekMusic: this.#seekMusic.bind(this),
      getMusicTime: this.#getMusicTime.bind(this),
      getMusicDuration: this.#getMusicDuration.bind(this),

      getMusicPlaying: () => { return this.#musicPlaying },
      getMusicRepeat: this.#getMusicRepeat.bind(this),
      setMusicRepeat: this.#setMusicRepeat.bind(this),
      setMusicVolume: this.#setMusicVolume.bind(this),

      // Timing
      getTimer: () => this.getTimer(),
      getFullTimer: () => this.getFullTimer(),

      // VGA
      flush: () => this.flush(),
      toggleFullscreen: () => this.toggleFullscreen(),

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
    }
  });


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

  /**
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
