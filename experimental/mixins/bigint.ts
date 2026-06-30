type BigIntWasmExports = WasmExports & {
  getStringBuffer: () => number;
};

// eslint-disable-next-line @typescript-eslint/no-unused-vars
class BigIntMixin extends Posit92 {
  SetupImportObject(): void {
    const { env } = super.WasmImportObject;

    Object.assign(env, {
      // BigInt
      addBigInt: () => this.#AddBigInt.bind(this),
      subtractBigInt: () => this.#SubtractBigInt.bind(this),
      multiplyBigInt: () => this.#MultiplyBigInt.bind(this),
      divideBigInt: () => this.#DivideBigInt.bind(this),

      compareBigInt: () => this.#CompareBigInt.bind(this),
      formatBigInt: () => this.#formatBigInt.bind(this),
      formatBigIntScientific: () => this.#formatBigIntScientific.bind(this)
    });
  }

  AssertBigInt(value: unknown): void {
    if (typeof value != "bigint")
      throw new Error(`Expected a BigInt, but received ${typeof value}`);
  }
  
  // BigInt interop

  /**
   * Pass a JS string to Pascal
   */
  #loadStringBuffer(text): void {
    const encoder = new TextEncoder();
    const bytes = encoder.encode(text);

    const bufferPtr = this.WasmInstance.exports.getStringBuffer();
    const buffer = new Uint8Array(this.WasmInstance.exports.memory.buffer, bufferPtr, bytes.length);
    buffer.set(bytes);

    return bytes.length;
  }

  #loadBigIntResult(n: bigint): void {
    this.AssertBigInt(n);

    if ((typeof n != "bigint") && (typeof n != "string"))
      throw new Error("n should be either of type BigInt or string");

    const length = this.#loadStringBuffer(n.toString());
    const bufferPtr = this.WasmInstance.exports.getStringBuffer();
    this.WasmInstance.exports.loadBigIntResult(bufferPtr, length);
  }

  #bufferPtrToString(bufferPtr: number): string {
    this.AssertNumber(bufferPtr);

    const buffer = new Uint8Array(this.WasmInstance.exports.memory.buffer, bufferPtr, 256);
    const len = buffer[0];
    const bytes = buffer.slice(1, 1 + len);

    return new TextDecoder().decode(bytes);
  }



  // Begin arithmetic operations

  #AddBigInt(): void {
    const biStrA = this.#bufferPtrToString(
      this.wasmInstance.exports.getBigIntAPtr());
    const biStrB = this.#bufferPtrToString(
      this.wasmInstance.exports.getBigIntBPtr());
    
    const [a, b] = [BigInt(biStrA), BigInt(biStrB)];

    // console.log("BigIntA", a)
    // console.log("BigIntB", b)
    // console.log(a + b, (a + b).toString());

    this.#loadBigIntResult(a + b);
  }

  #SubtractBigInt(): void {
    const biStrA = this.#bufferPtrToString(this.WasmInstance.exports.getBigIntAPtr());
    const biStrB = this.#bufferPtrToString(this.WasmInstance.exports.getBigIntBPtr());
    
    const [a, b] = [BigInt(biStrA), BigInt(biStrB)];
    this.#loadBigIntResult(a - b);
  }

  #MultiplyBigInt(): void {
    const biStrA = this.#bufferPtrToString(this.WasmInstance.exports.getBigIntAPtr());
    const biStrB = this.#bufferPtrToString(this.WasmInstance.exports.getBigIntBPtr());
    
    const [a, b] = [BigInt(biStrA), BigInt(biStrB)];
    this.#loadBigIntResult(a * b);
  }

  #DivideBigInt(): void {
    const biStrA = this.#bufferPtrToString(this.WasmInstance.exports.getBigIntAPtr());
    const biStrB = this.#bufferPtrToString(this.WasmInstance.exports.getBigIntBPtr());
    
    const [a, b] = [BigInt(biStrA), BigInt(biStrB)];
    this.#loadBigIntResult(a / b);
  }

  #CompareBigInt(): void {
    const biStrA = this.#bufferPtrToString(this.WasmInstance.exports.getBigIntAPtr());
    const biStrB = this.#bufferPtrToString(this.WasmInstance.exports.getBigIntBPtr());
    
    const [a, b] = [BigInt(biStrA), BigInt(biStrB)];

    if (a > b)
      this.#loadBigIntResult(1n);
    else if (a < b)
      this.#loadBigIntResult(-1n);
    else
      this.#loadBigIntResult(0n);
  }

  #formatBigInt(): void {
    const biStrA = this.#bufferPtrToString(this.WasmInstance.exports.getBigIntAPtr());
    const a = BigInt(biStrA);
    let readable = 0;

    if (a >= 10n ** 33n) {
      readable = Number(a / 10n ** 32n) / 10;
      this.#loadBigIntResult(readable + "Dc");

    } else if (a >= 10n ** 30n) {
      readable = Number(a / 10n ** 29n) / 10;
      this.#loadBigIntResult(readable + "No");

    } else if (a >= 10n ** 27n) {
      readable = Number(a / 10n ** 26n) / 10;
      this.#loadBigIntResult(readable + "Oc");

    } else if (a >= 10n ** 24n) {
      readable = Number(a / 10n ** 23n) / 10;
      this.#loadBigIntResult(readable + "Sp");

    } else if (a >= 10n ** 21n) {
      readable = Number(a / 10n ** 20n) / 10;
      this.#loadBigIntResult(readable + "Sx");

    } else if (a >= 10n ** 18n) {
      readable = Number(a / 10n ** 17n) / 10;
      this.#loadBigIntResult(readable + "Qi");

    } else if (a >= 10n ** 15n) {
      readable = Number(a / 10n ** 14n) / 10;
      this.#loadBigIntResult(readable + "Qa");
    
    } else if (a >= 10n ** 12n) {
      readable = Number(a / 10n ** 11n) / 10;
      this.#loadBigIntResult(readable + "T");

    } else if (a >= 1_000_000_000n) {
      readable = Number(a / 100_000_000n) / 10;
      this.#loadBigIntResult(readable + "B");
      
    } else if (a >= 1_000_000n) {
      readable = Number(a / 100_000n) / 10;
      this.#loadBigIntResult(readable + "M");

    } else if (a >= 1000n) {
      readable = Number(a / 100n) / 10;
      this.#loadBigIntResult(readable + "K");

    } else
      this.#loadBigIntResult(a);
  }


  #formatBigIntScientific() {
    const biStrA = this.#bufferPtrToString(this.WasmInstance.exports.getBigIntAPtr());
    const a = BigInt(biStrA);
    const digits = a.toString().length;

    if (a >= 1000n) {
      const readable = Number(a / 10n ** (BigInt(digits) - 2n)) / 10;
      this.#loadBigIntResult(readable + " * 10^" + (digits - 1));
    } else
      this.#loadBigIntResult(a);
  }

}