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
      GLClearColor: this.#GLClearColor.bind(this),
      GLClear: this.#GLClear.bind(this),
      GLViewport: this.#GLViewport.bind(this),

      GLCreateTexture: this.#GLCreateTexture.bind(this),
      GLBindTexture: this.#GLBindTexture.bind(this),
      GLTexParameteri: this.#GLTexParameteri.bind(this),
      GLTexImage2D: this.#GLTexImage2D.bind(this),

      GLCreateShader: this.#GLCreateShader.bind(this),
      GLShaderSource: this.#GLShaderSource.bind(this),
      GLCompileShader: this.#GLCompileShader.bind(this),

      GLGetShaderParameter: this.#GLGetShaderParameter.bind(this),
      GLGetShaderInfoLog: this.#GLGetShaderInfoLog.bind(this),

      GLCreateProgram: this.#GLCreateProgram.bind(this),
      GLAttachShader: this.#GLAttachShader.bind(this),
      GLLinkProgram: this.#GLLinkProgram.bind(this),
      GLUseProgram: this.#GLUseProgram.bind(this),

      GLGetProgramParameter: this.#GLGetProgramParameter.bind(this),
      GLGetProgramInfoLog: this.#GLGetProgramInfoLog.bind(this),

      GLCreateBuffer: this.#GLCreateBuffer.bind(this),
      GLBindBuffer: this.#GLBindBuffer.bind(this),
      GLBufferData: this.#GLBufferData.bind(this),
      GLGetAttribLocation: this.#GLGetAttribLocation.bind(this),
      GLEnableVertexAttribArray: this.#GLEnableVertexAttribArray.bind(this),
      GLVertexAttribPointer: this.#GLVertexAttribPointer.bind(this),
      GLDrawArrays: this.#GLDrawArrays.bind(this),

      GLGetUniformLocation: this.#GLGetUniformLocation.bind(this),
      GLUniform1i: this.#GLUniform1i.bind(this),

      GLActiveTexture: this.#GLActiveTexture.bind(this)
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
  #GLClearColor(r: number, g: number, b: number, a: number): void {
    this.glCtx.clearColor(r, g, b, a);
  }

  #GLClear(mask: number): void {
    this.glCtx.clear(mask);
  }

  #GLViewport(x: number, y: number, w: number, h: number): void {
    this.glCtx.viewport(x, y, w, h);
  }


  #GLCreateTexture(): number {
    const texture = this.glCtx.createTexture();
    const id = this.#nextTextureId;

    this.#textures.set(id, texture);

    this.#nextTextureId++;

    return id;
  }

  #GLBindTexture(target: number, textureId: number): void {
    const texture = this.#textures.get(textureId);
    
    if (texture == null)
      throw new Error(`glBindTexture: Missing texture with textureId ${textureId}!`);

    this.glCtx.bindTexture(target, texture);
  }

  #GLTexParameteri(target: number, pname: number, param: number): void {
    this.glCtx.texParameteri(target, pname, param);
  }

  #GLTexImage2D(
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


  #GLCreateShader(type: number): number {
    const shader = this.glCtx.createShader(type)!;
    const id = this.#nextShaderId;

    console.log("shader id:", id);
    
    this.#shaders.set(id, shader);

    this.#nextShaderId++;

    return id;
  }

  #GLShaderSource(shaderId: number, sourcePtr: number): void {
    const shader = this.#shaders.get(shaderId);

    if (shader == null)
      throw new Error(`glShaderSource: Missing shader with shaderId: ${shaderId}!`);

    const source = this.#ReadCString(sourcePtr);

    this.glCtx.shaderSource(shader, source);
  }

  #GLCompileShader(shaderId: number): void {
    const shader = this.#shaders.get(shaderId);

    if (shader == null)
      throw new Error(`glCompileShader: Missing shader with shaderId: ${shaderId}!`);

    this.glCtx.compileShader(shader);
  }

  #GLGetShaderParameter(shaderId: number, param: GLenum): number {
    const shader = this.#shaders.get(shaderId);

    if (shader == null)
      throw new Error(`glGetShaderParameter: Missing shader with shaderId: ${shaderId}!`);

    return this.glCtx.getShaderParameter(shader, param);
  }

  /**
   * This loads a string into the interop buffer
   */
  #GLGetShaderInfoLog(shaderId: number): void {
    const shader = this.#shaders.get(shaderId);

    if (shader == null)
      throw new Error(`glGetShaderInfoLog: Missing shader with shaderId: ${shaderId}!`);

    this.WriteInteropBuffer(this.glCtx.getShaderInfoLog(shader) ?? "");
  }


  #GLCreateProgram(): number {
    const program = this.glCtx.createProgram();
    const id = this.#nextProgramId;
    
    this.#programs.set(id, program);

    this.#nextProgramId++;

    return id;
  }

  #GLAttachShader(programId: number, shaderId: number): void {
    const program = this.#programs.get(programId);

    if (program == null)
      throw new Error(`glAttachShader: Missing program with programId: ${programId}!`);

    const shader = this.#shaders.get(shaderId);

    if (shader == null)
      throw new Error(`glAttachShader: Missing shader with shaderId: ${shaderId}!`);

    this.glCtx.attachShader(program, shader);
  }

  #GLLinkProgram(programId: number): void {
    const program = this.#programs.get(programId);

    if (program == null)
      throw new Error(`glLinkProgram: Missing program with programId: ${programId}!`);

    this.glCtx.linkProgram(program);
  }

  #GLUseProgram(programId: number): void {
    const program = this.#programs.get(programId);

    if (program == null)
      throw new Error(`glUseProgram: Missing program with programId: ${programId}!`);

    this.glCtx.useProgram(program);
  }

  #GLGetProgramParameter(programId: number, param: GLenum): number {
    const program = this.#programs.get(programId);

    if (program == null)
      throw new Error(`glGetProgramParameter: Missing program with programId: ${programId}!`);

    return this.glCtx.getProgramParameter(program, param);
  }

  /**
   * This loads a string into the interop buffer
   */
  #GLGetProgramInfoLog(programId: number): void {
    const program = this.#programs.get(programId);

    if (program == null)
      throw new Error(`glGetProgramInfoLog: Missing program with programId: ${programId}!`);

    this.WriteInteropBuffer(this.glCtx.getProgramInfoLog(program) ?? "");
  }


  #GLCreateBuffer(): number {
    const buffer = this.glCtx.createBuffer();
    const id = this.#nextBufferId;

    this.#buffers.set(id, buffer);
    this.#nextBufferId++;

    return id;
  }

  #GLBindBuffer(target: number, bufferId: number): void {
    const buffer = this.#buffers.get(bufferId);

    if (buffer == null)
      throw new Error(`glBindBuffer: Missing buffer with bufferId: ${bufferId}!`);

    this.glCtx.bindBuffer(target, buffer);
  }

  #GLBufferData(target: number, size: number, dataPtr: number, usage: GLenum): void {
    const data = new Float32Array(
      this.WasmInstance.exports.memory.buffer,
      dataPtr,
      Math.ceil(size / 4)
    );

    this.glCtx.bufferData(target, data, usage);
  }

  #GLGetAttribLocation(programId: number, namePtr: number): number {
    const program = this.#programs.get(programId);

    if (program == null)
      throw new Error(`glGetAttribLocation: Missing program with programId: ${programId}`);

    const name = this.#ReadCString(namePtr);

    return this.glCtx.getAttribLocation(program, name);
  }

  #GLEnableVertexAttribArray(idx: number): void {
    this.glCtx.enableVertexAttribArray(idx);
  }

  #GLVertexAttribPointer(
    idx: number,
    size: number,
    type: number,
    normalized: boolean,
    stride: number,
    offset: number
  ): void {
    this.glCtx.vertexAttribPointer(idx, size, type, normalized, stride, offset);
  }

  #GLDrawArrays(mode: number, first: number, count: number): void {
    let err = this.glCtx.getError();
    if (err != 0)
      throw new Error("WebGL error before draw: " + err);

    this.glCtx.drawArrays(mode, first, count);

    err = this.glCtx.getError();
    if (err != 0)
      throw new Error("WebGL error after draw: " + err);
  }


  #GLGetUniformLocation(programId: number, namePtr: number): number {
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

  #GLUniform1i(locationId: number, value: number): void {
    const loc = this.#uniformLocations.get(locationId);

    if (loc == null)
      throw new Error(`glUniform1i: Missing UniformLocation with locationId: ${locationId}!`);

    this.glCtx.uniform1i(loc, value);
  }

  #GLActiveTexture(textureId: number): void {
    this.glCtx.activeTexture(textureId);
  }
}
