/**
 * WebAssembly initialisation happens in the parent class Posit92
 * 
 * Part of Posit-92 game engine
 */

// eslint-disable-next-line @typescript-eslint/no-unused-vars
class WebGLMixin extends Posit92 {
  #textures: Map<number, WebGLTexture> = new Map();
  #nextTextureId = 1;

  #shaders: Map<number, WebGLShader> = new Map();
  #nextShaderId = 1;

  #programs: Map<number, WebGLProgram> = new Map();
  #nextProgramId = 1;

  #buffers: Map<number, WebGLBuffer> = new Map();
  #nextBufferId = 1;

  #uniformLocations: Map<number, WebGLUniformLocation> = new Map();
  #nextUniformId = 1;

  /**
   * @override
   */
  SetupImportObject(): void {
    const { env } = this.WasmImportObject;

    console.log("SetupImportObject call");

    Object.assign(env, {
      // WebGL
      glClearColor: this.#glClearColor.bind(this),
      glClear: this.#glClear.bind(this),
      glViewport: this.#glViewport.bind(this),

      glCreateTexture: this.#glCreateTexture.bind(this),
      glBindTexture: this.#glBindTexture.bind(this),
      glTexParameteri: this.#glTexParameteri.bind(this),
      glTexImage2D: this.#glTexImage2D.bind(this),

      glCreateShader: this.#glCreateShader.bind(this),
      glShaderSource: this.#glShaderSource.bind(this),
      glCompileShader: this.#glCompileShader.bind(this),

      glGetShaderParameter: this.#glGetShaderParameter.bind(this),

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

  // WEBGL.PAS

  #ReadCString(ptr: number): string {
    this.AssertNumber(ptr);

    const memory = new Uint8Array(this.WasmInstance.exports.memory.buffer);
    let end = ptr;
    while (memory[end] != 0) end++;  // Find null terminator

    const bytes = memory.subarray(ptr, end);
    return new TextDecoder().decode(bytes);
  }

  /**
   * 
   * @param r 0.0 .. 1.0
   * @param g 0.0 .. 1.0
   * @param b 0.0 .. 1.0
   * @param a 0.0 .. 1.0
   */
  #glClearColor(r: number, g: number, b: number, a: number): void {
    this.glCtx.clearColor(r, g, b, a);
  }

  #glClear(mask: number): void {
    this.glCtx.clear(mask);
  }

  #glViewport(x: number, y: number, w: number, h: number): void {
    this.glCtx.viewport(x, y, w, h);
  }


  #glCreateTexture(): number {
    const texture = this.glCtx.createTexture();
    const id = this.#nextTextureId;

    this.#textures.set(id, texture);

    this.#nextTextureId++;

    return id;
  }

  #glBindTexture(target: number, textureId: number): void {
    const texture = this.#textures.get(textureId);
    
    if (texture == null)
      throw new Error(`glBindTexture: Missing texture with textureId ${textureId}!`);

    this.glCtx.bindTexture(target, texture);
  }

  #glTexParameteri(target: number, pname: number, param: number): void {
    this.glCtx.texParameteri(target, pname, param);
  }

  #glTexImage2D(
    target: number,
    level: number,
    internalFormat: number,
    width: number,
    height: number,
    border: number,
    format: number,
    type: number,
    pixelsPtr: number
  ): void {
    const pixels = new Uint8Array(
      this.WasmInstance.exports.memory.buffer,
      pixelsPtr,
      width * height * 4);

    this.glCtx.texImage2D(
      target, level, internalFormat,
      width, height, border,
      format, type, pixels);
  }


  #glCreateShader(type: number): number {
    const shader = this.glCtx.createShader(type)!;
    const id = this.#nextShaderId;
    
    this.#shaders.set(id, shader);

    this.#nextShaderId++;

    return id;
  }

  #glShaderSource(shaderId: number, sourcePtr: number): void {
    const shader = this.#shaders.get(shaderId);

    if (shader == null)
      throw new Error(`glShaderSource: Missing shader with shaderId: ${shaderId}!`);

    const source = this.#ReadCString(sourcePtr);

    this.glCtx.shaderSource(shader, source);
  }

  #glCompileShader(shaderId: number): void {
    const shader = this.#shaders.get(shaderId);

    if (shader == null)
      throw new Error(`glShaderSource: Missing shader with shaderId: ${shaderId}!`);

    this.glCtx.compileShader(shader);
  }

  #glGetShaderParameter(shaderId: number, param: GLenum): number {
    const shader = this.#shaders.get(shaderId);

    if (shader == null)
      throw new Error(`glShaderSource: Missing shader with shaderId: ${shaderId}!`);

    return this.glCtx.getShaderParameter(shader, param);
  }

  #glCreateProgram(): number {
    const program = this.glCtx.createProgram();
    const id = this.#nextProgramId;
    
    this.#programs.set(id, program);

    this.#nextProgramId++;

    return id;
  }

  #glAttachShader(programId: number, shaderId: number): void {
    const program = this.#programs.get(programId);

    if (program == null)
      throw new Error(`glAttachShader: Missing program with programId: ${programId}!`);

    const shader = this.#shaders.get(shaderId);

    if (shader == null)
      throw new Error(`glAttachShader: Missing shader with shaderId: ${shaderId}!`);

    this.glCtx.attachShader(program, shader);
  }

  #glLinkProgram(programId: number): void {
    const program = this.#programs.get(programId);

    if (program == null)
      throw new Error(`glLinkProgram: Missing program with programId: ${programId}!`);

    this.glCtx.linkProgram(program);
  }

  #glUseProgram(programId: number): void {
    const program = this.#programs.get(programId);

    if (program == null)
      throw new Error(`glUseProgram: Missing program with programId: ${programId}!`);

    this.glCtx.useProgram(program);
  }


  #glCreateBuffer(): number {
    const buffer = this.glCtx.createBuffer();
    const id = this.#nextBufferId;

    this.#buffers.set(id, buffer);
    this.#nextBufferId++;

    return id;
  }

  #glBindBuffer(target: number, bufferId: number): void {
    const buffer = this.#buffers.get(bufferId);

    if (buffer == null)
      throw new Error(`glBindBuffer: Missing buffer with bufferId: ${bufferId}!`);

    this.glCtx.bindBuffer(target, buffer);
  }

  #glBufferData(target: number, size: number, dataPtr: number, usage: GLenum): void {
    const data = new Float32Array(
      this.WasmInstance.exports.memory.buffer,
      dataPtr,
      Math.ceil(size / 4)
    );

    this.glCtx.bufferData(target, data, usage);
  }

  #glGetAttribLocation(programId: number, namePtr: number): number {
    const program = this.#programs.get(programId);

    if (program == null)
      throw new Error(`glGetAttribLocation: Missing program with programId: ${programId}`);

    const name = this.#ReadCString(namePtr);

    return this.glCtx.getAttribLocation(program, name);
  }

  #glEnableVertexAttribArray(idx: number): void {
    this.glCtx.enableVertexAttribArray(idx);
  }

  #glVertexAttribPointer(
    idx: number,
    size: number,
    type: number,
    normalized: boolean,
    stride: number,
    offset: number
  ): void {
    this.glCtx.vertexAttribPointer(idx, size, type, normalized, stride, offset);
  }

  #glDrawArrays(mode: number, first: number, count: number): void {
    let err = this.glCtx.getError();
    if (err != 0)
      throw new Error("WebGL error before draw: " + err);

    this.glCtx.drawArrays(mode, first, count);

    err = this.glCtx.getError();
    if (err != 0)
      throw new Error("WebGL error after draw: " + err);
  }


  #glGetUniformLocation(programId: number, namePtr: number): number {
    const program = this.#programs.get(programId);
    const name = this.#ReadCString(namePtr);

    console.log("glGetUniformLocation name:", name);

    if (program == null)
      throw new Error(`glGetUniformLocation: Missing program with programId ${programId}!`);

    const location = this.glCtx.getUniformLocation(program, name);

    if (location == null)
      throw new Error(`glGetUniformLocation: Missing UniformLocation with programId ${programId}!`);

    const id = this.#nextUniformId++;
    this.#uniformLocations.set(id, location);

    return id;
  }

  #glUniform1i(locationId: number, value: number): void {
    const loc = this.#uniformLocations.get(locationId);

    if (loc == null)
      throw new Error(`glUniform1i: Missing UniformLocation with locationId: ${locationId}!`);

    this.glCtx.uniform1i(loc, value);
  }

  #glActiveTexture(textureId: number): void {
    this.glCtx.activeTexture(textureId);
  }
}
