class BigIntMixin extends Posit92 {
  #setupImportObject() {
    const { env } = super._getWasmImportObject();

    Object.assign(env, {
      // BigInt
      addBigInt: () => this.#addBigInt(),
      subtractBigInt: () => this.#subtractBigInt(),
      multiplyBigInt: () => this.#multiplyBigInt(),
      divideBigInt: () => this.#divideBigInt(),

      compareBigInt: () => this.#compareBigInt(),
      formatBigInt: () => this.#formatBigInt(),
      formatBigIntScientific: () => this.#formatBigIntScientific()
    })
  }

  /**
   * @override
   */
  async init() {
    this.#setupImportObject();
    await super.init()
  }

  #assertNumber(value) {
    if (typeof value != "number")
      throw new Error(`Expected a number, but received ${typeof value}`);

    if (isNaN(value))
      throw new Error("Expected a number, but received NaN");
  }

  #assertBigInt(value) {
    if (typeof value != "bigint")
      throw new Error(`Expected a BigInt, but received ${typeof value}`);
  }
  
  // BigInt interop
  /**
   * Pass a JS string to Pascal
   */
  #loadStringBuffer(text) {
    const encoder = new TextEncoder();
    const bytes = encoder.encode(text);

    const bufferPtr = this.wasmInstance.exports.getStringBuffer();
    const buffer = new Uint8Array(this.wasmInstance.exports.memory.buffer, bufferPtr, bytes.length);
    buffer.set(bytes);

    return bytes.length
  }

  #loadBigIntResult(n) {
    // this.#assertBigInt(n);
    if ((typeof n != "bigint") && (typeof n != "string"))
      throw new Error("n should be either of type BigInt or string");

    const length = this.#loadStringBuffer(n.toString());
    const bufferPtr = this.wasmInstance.exports.getStringBuffer();
    this.wasmInstance.exports.loadBigIntResult(bufferPtr, length);
  }

  #bufferPtrToString(bufferPtr) {
    this.#assertNumber(bufferPtr);

    const buffer = new Uint8Array(this.wasmInstance.exports.memory.buffer, bufferPtr, 256);
    const len = buffer[0];
    const bytes = buffer.slice(1, 1 + len);

    return new TextDecoder().decode(bytes)
  }



  // Begin arithmetic operations
  #addBigInt() {
    const biStrA = this.#bufferPtrToString(
      this.wasmInstance.exports.getBigIntAPtr());
    const biStrB = this.#bufferPtrToString(
      this.wasmInstance.exports.getBigIntBPtr());
    
    const [a, b] = [BigInt(biStrA), BigInt(biStrB)];

    // console.log("BigIntA", a)
    // console.log("BigIntB", b)
    // console.log(a + b, (a + b).toString());

    this.#loadBigIntResult(a + b)
  }

  #subtractBigInt() {
    const biStrA = this.#bufferPtrToString(this.wasmInstance.exports.getBigIntAPtr());
    const biStrB = this.#bufferPtrToString(this.wasmInstance.exports.getBigIntBPtr());
    
    const [a, b] = [BigInt(biStrA), BigInt(biStrB)];
    this.#loadBigIntResult(a - b)
  }

  #multiplyBigInt() {
    const biStrA = this.#bufferPtrToString(this.wasmInstance.exports.getBigIntAPtr());
    const biStrB = this.#bufferPtrToString(this.wasmInstance.exports.getBigIntBPtr());
    
    const [a, b] = [BigInt(biStrA), BigInt(biStrB)];
    this.#loadBigIntResult(a * b)
  }

  #divideBigInt() {
    const biStrA = this.#bufferPtrToString(this.wasmInstance.exports.getBigIntAPtr());
    const biStrB = this.#bufferPtrToString(this.wasmInstance.exports.getBigIntBPtr());
    
    const [a, b] = [BigInt(biStrA), BigInt(biStrB)];
    this.#loadBigIntResult(a / b)
  }

  #compareBigInt() {
    const biStrA = this.#bufferPtrToString(this.wasmInstance.exports.getBigIntAPtr());
    const biStrB = this.#bufferPtrToString(this.wasmInstance.exports.getBigIntBPtr());
    
    const [a, b] = [BigInt(biStrA), BigInt(biStrB)];

    if (a > b)
      this.#loadBigIntResult(1n)
    else if (a < b)
      this.#loadBigIntResult(-1n)
    else
      this.#loadBigIntResult(0n);
  }

  #formatBigInt() {
    const biStrA = this.#bufferPtrToString(this.wasmInstance.exports.getBigIntAPtr());
    const a = BigInt(biStrA);
    let readable = 0;

    if (a >= 10n ** 33n) {
      readable = Number(a / 10n ** 32n) / 10;
      this.#loadBigIntResult(readable + "Dc")

    } else if (a >= 10n ** 30n) {
      readable = Number(a / 10n ** 29n) / 10;
      this.#loadBigIntResult(readable + "No")

    } else if (a >= 10n ** 27n) {
      readable = Number(a / 10n ** 26n) / 10;
      this.#loadBigIntResult(readable + "Oc")

    } else if (a >= 10n ** 24n) {
      readable = Number(a / 10n ** 23n) / 10;
      this.#loadBigIntResult(readable + "Sp")

    } else if (a >= 10n ** 21n) {
      readable = Number(a / 10n ** 20n) / 10;
      this.#loadBigIntResult(readable + "Sx")

    } else if (a >= 10n ** 18n) {
      readable = Number(a / 10n ** 17n) / 10;
      this.#loadBigIntResult(readable + "Qi")

    } else if (a >= 10n ** 15n) {
      readable = Number(a / 10n ** 14n) / 10;
      this.#loadBigIntResult(readable + "Qa")
    
    } else if (a >= 10n ** 12n) {
      readable = Number(a / 10n ** 11n) / 10;
      this.#loadBigIntResult(readable + "T")

    } else if (a >= 1_000_000_000n) {
      readable = Number(a / 100_000_000n) / 10;
      this.#loadBigIntResult(readable + "B")
      
    } else if (a >= 1_000_000n) {
      readable = Number(a / 100_000n) / 10;
      this.#loadBigIntResult(readable + "M")

    } else if (a >= 1000n) {
      readable = Number(a / 100n) / 10;
      this.#loadBigIntResult(readable + "K")

    } else
      this.#loadBigIntResult(a);
  }


  #formatBigIntScientific() {
    const biStrA = this.#bufferPtrToString(this.wasmInstance.exports.getBigIntAPtr());
    const a = BigInt(biStrA);
    const digits = a.toString().length;

    if (a >= 1000n) {
      const readable = Number(a / 10n ** (BigInt(digits) - 2n)) / 10;
      this.#loadBigIntResult(readable + " * 10^" + (digits - 1))
    } else
      this.#loadBigIntResult(a);
  }

}