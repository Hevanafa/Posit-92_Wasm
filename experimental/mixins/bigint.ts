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
      // FormatBigInt: this.#FormatBigInt.bind(this),
      // FormatBigIntScientific: this.#FormatBigIntScientific.bind(this)
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
    console.log("bigIntA", this.#bigIntA);
  }

  #BigIntSetB(): void {
    this.#bigIntB = BigInt(this.ReadInteropBuffer());
    console.log("bigIntB", this.#bigIntB);
  }

  // Begin arithmetic operations

  #BigIntAdd(): void {
    this.#bigIntResult = this.#bigIntA + this.#bigIntB;
    this.WriteInteropBuffer(this.#bigIntResult.toString());
  }

  #BigIntSubtract(): void {
    this.#bigIntResult = this.#bigIntA - this.#bigIntB;
    console.log("BigIntSubtract", this.#bigIntResult);

    this.WriteInteropBuffer(this.#bigIntResult.toString());
  }

  #BigIntMultiply(): void {
    this.#bigIntResult = this.#bigIntA * this.#bigIntB;
    console.log("BigIntMultiply", this.#bigIntResult);

    this.WriteInteropBuffer(this.#bigIntResult.toString());
  }

  #BigIntDivide(): void {
    this.#bigIntResult = this.#bigIntA / this.#bigIntB;
    console.log("BigIntDivide", this.#bigIntResult);

    this.WriteInteropBuffer(this.#bigIntResult.toString());
  }

  #BigIntCompare(): void {
    if (this.#bigIntA > this.#bigIntB)
      this.#bigIntResult = 1n;
    else if (this.#bigIntA < this.#bigIntB)
      this.#bigIntResult = -1n;
    else
      this.#bigIntResult = 0n;

    this.WriteInteropBuffer(this.#bigIntResult.toString());
  }

  // #FormatBigInt(): void {
  //   const biStrA = this.#BufferPtrToString(this.WasmInstanceExports.GetBigIntAPtr());
  //   const a = BigInt(biStrA);
  //   let readable = 0;

  //   if (a >= 10n ** 33n) {
  //     readable = Number(a / 10n ** 32n) / 10;
  //     this.#LoadBigIntResult(readable + "Dc");

  //   } else if (a >= 10n ** 30n) {
  //     readable = Number(a / 10n ** 29n) / 10;
  //     this.#LoadBigIntResult(readable + "No");

  //   } else if (a >= 10n ** 27n) {
  //     readable = Number(a / 10n ** 26n) / 10;
  //     this.#LoadBigIntResult(readable + "Oc");

  //   } else if (a >= 10n ** 24n) {
  //     readable = Number(a / 10n ** 23n) / 10;
  //     this.#LoadBigIntResult(readable + "Sp");

  //   } else if (a >= 10n ** 21n) {
  //     readable = Number(a / 10n ** 20n) / 10;
  //     this.#LoadBigIntResult(readable + "Sx");

  //   } else if (a >= 10n ** 18n) {
  //     readable = Number(a / 10n ** 17n) / 10;
  //     this.#LoadBigIntResult(readable + "Qi");

  //   } else if (a >= 10n ** 15n) {
  //     readable = Number(a / 10n ** 14n) / 10;
  //     this.#LoadBigIntResult(readable + "Qa");
    
  //   } else if (a >= 10n ** 12n) {
  //     readable = Number(a / 10n ** 11n) / 10;
  //     this.#LoadBigIntResult(readable + "T");

  //   } else if (a >= 1_000_000_000n) {
  //     readable = Number(a / 100_000_000n) / 10;
  //     this.#LoadBigIntResult(readable + "B");
      
  //   } else if (a >= 1_000_000n) {
  //     readable = Number(a / 100_000n) / 10;
  //     this.#LoadBigIntResult(readable + "M");

  //   } else if (a >= 1000n) {
  //     readable = Number(a / 100n) / 10;
  //     this.#LoadBigIntResult(readable + "K");

  //   } else
  //     this.#LoadBigIntResult(a);
  // }


  // #FormatBigIntScientific(): void {
  //   const biStrA = this.#BufferPtrToString(this.WasmInstanceExports.GetBigIntAPtr());
  //   const a = BigInt(biStrA);
  //   const digits = a.toString().length;

  //   if (a >= 1000n) {
  //     const readable = Number(a / 10n ** (BigInt(digits) - 2n)) / 10;
  //     this.#LoadBigIntResult(readable + " * 10^" + (digits - 1));
  //   } else
  //     this.#LoadBigIntResult(a);
  // }
}