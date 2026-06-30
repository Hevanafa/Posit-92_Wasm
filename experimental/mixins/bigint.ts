type BigIntWasmExports = WasmExports & {
  LoadBigIntResult: (bufferPtr: number, length: number) => void;
  GetBigIntAPtr: () => number;
  GetBigIntBPtr: () => number;
};

// eslint-disable-next-line @typescript-eslint/no-unused-vars
class BigIntMixin extends Posit92 {
  SetupImportObject(): void {
    const { env } = super.WasmImportObject;

    console.log("SetupImportObject");

    Object.assign(env, {
      JsBigIntSetA: this.#BigIntSetA.bind(this),
      JsBigIntSetB: this.#BigIntSetB.bind(this),

      JsBigIntAdd: this.#BigIntAdd.bind(this),
      JsBigIntSubtract: this.#BigIntSubtract.bind(this),
      JsBigIntMultiply: this.#BigIntMultiply.bind(this),
      JsBigIntDivide: this.#BigIntDivide.bind(this),
      JsBigIntCompare: this.#BigIntCompare.bind(this),

      JsBigIntFetchResult: this.#BigIntFetchResult.bind(this),

      JsBigIntFormat: this.#BigIntFormat.bind(this),
      JsBigIntFormatScientific: this.#BigIntFormatScientific.bind(this)
    });
  }

  #bigIntA: bigint = 0n;
  #bigIntB: bigint = 0n;
  #bigIntResult: bigint = 0n;

  // get WasmInstance(): WebAssemblyInstance & { exports: BigIntWasmExports } {
  //   return super.WasmInstance as any;
  // }

  get WasmInstanceExports(): BigIntWasmExports {
    return this.WasmInstance.exports as BigIntWasmExports;
  }

  AssertBigInt(value: unknown): void {
    if (typeof value != "bigint")
      throw new Error(`Expected a BigInt, but received ${typeof value}`);
  }
  
  // BigInt interop

  #BigIntSetA(): void {
    this.#bigIntA = BigInt(this.ReadInteropBuffer());
  }

  #BigIntSetB(): void {
    this.#bigIntB = BigInt(this.ReadInteropBuffer());
  }

  // Begin arithmetic operations

  #BigIntAdd(): void {
    this.#bigIntResult = this.#bigIntA + this.#bigIntB;
  }

  #BigIntSubtract(): void {
    this.#bigIntResult = this.#bigIntA - this.#bigIntB;
  }

  #BigIntMultiply(): void {
    this.#bigIntResult = this.#bigIntA * this.#bigIntB;
  }

  #BigIntDivide(): void {
    this.#bigIntResult = this.#bigIntA / this.#bigIntB;
  }

  #BigIntCompare(): void {
    if (this.#bigIntA > this.#bigIntB)
      this.#bigIntResult = 1n;
    else if (this.#bigIntA < this.#bigIntB)
      this.#bigIntResult = -1n;
    else
      this.#bigIntResult = 0n;
  }

  #BigIntFetchResult(): void {
    this.WriteInteropBuffer(this.#bigIntResult.toString());
  }

  /**
   * Makes the result string available in the interop string
   * 
   * Uses only `bigIntA`
   */
  #BigIntFormat(): void {
    const n = this.#bigIntA;

    let readable = 0;

    if (n >= 10n ** 33n) {
      readable = Number(n / 10n ** 32n) / 10;
      this.WriteInteropBuffer(readable + "Dc");

    } else if (n >= 10n ** 30n) {
      readable = Number(n / 10n ** 29n) / 10;
      this.WriteInteropBuffer(readable + "No");

    } else if (n >= 10n ** 27n) {
      readable = Number(n / 10n ** 26n) / 10;
      this.WriteInteropBuffer(readable + "Oc");

    } else if (n >= 10n ** 24n) {
      readable = Number(n / 10n ** 23n) / 10;
      this.WriteInteropBuffer(readable + "Sp");

    } else if (n >= 10n ** 21n) {
      readable = Number(n / 10n ** 20n) / 10;
      this.WriteInteropBuffer(readable + "Sx");

    } else if (n >= 10n ** 18n) {
      readable = Number(n / 10n ** 17n) / 10;
      this.WriteInteropBuffer(readable + "Qi");

    } else if (n >= 10n ** 15n) {
      readable = Number(n / 10n ** 14n) / 10;
      this.WriteInteropBuffer(readable + "Qa");
    
    } else if (n >= 10n ** 12n) {
      readable = Number(n / 10n ** 11n) / 10;
      this.WriteInteropBuffer(readable + "T");

    } else if (n >= 1_000_000_000n) {
      readable = Number(n / 100_000_000n) / 10;
      this.WriteInteropBuffer(readable + "B");
      
    } else if (n >= 1_000_000n) {
      readable = Number(n / 100_000n) / 10;
      this.WriteInteropBuffer(readable + "M");

    } else if (n >= 1000n) {
      readable = Number(n / 100n) / 10;
      this.WriteInteropBuffer(readable + "K");

    } else
      this.WriteInteropBuffer(n.toString());
  }

  #BigIntFormatScientific(): void {
    const n = this.#bigIntA;
    const digits = n.toString().length;

    if (n >= 1000n) {
      const readable = Number(n / 10n ** (BigInt(digits) - 2n)) / 10;
      this.WriteInteropBuffer(readable + " * 10^" + (digits - 1));
    } else
      this.WriteInteropBuffer(n.toString());
  }
}