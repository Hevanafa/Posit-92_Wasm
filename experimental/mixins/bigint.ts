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
      // JsBigIntSetA: this.#BigIntSetResult.bind(this),

      // AddBigInt: () => this.#AddBigInt.bind(this),
      // SubtractBigInt: () => this.#SubtractBigInt.bind(this),
      // MultiplyBigInt: () => this.#MultiplyBigInt.bind(this),
      // DivideBigInt: () => this.#DivideBigInt.bind(this),

      // CompareBigInt: () => this.#CompareBigInt.bind(this),
      // FormatBigInt: () => this.#FormatBigInt.bind(this),
      // FormatBigIntScientific: () => this.#FormatBigIntScientific.bind(this)
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
    console.log(this.#bigIntA);
  }

  #BigIntSetB(): void {
    this.#bigIntB = BigInt(this.ReadInteropBuffer());
    console.log(this.#bigIntB);
  }

  // #LoadBigIntResult(n: bigint | string): void {
  //   if ((typeof n != "bigint") && (typeof n != "string"))
  //     throw new Error("n should be either of type BigInt or string");
// 
  //   const length = this.WriteInteropBuffer(n.toString());
  //   const bufferPtr = this.WasmInstanceExports.GetStringBuffer();
  //   this.WasmInstanceExports.LoadBigIntResult(bufferPtr, length);
  // }

  // #BufferPtrToString(bufferPtr: number): string {
  //   this.AssertNumber(bufferPtr);

  //   const buffer = new Uint8Array(this.WasmInstance.exports.memory.buffer, bufferPtr, 256);
  //   const len = buffer[0];
  //   const bytes = buffer.slice(1, 1 + len);

  //   return new TextDecoder().decode(bytes);
  // }


  // Begin arithmetic operations

  /*
  #AddBigInt(): void {
    const biStrA = this.#BufferPtrToString(
      this.WasmInstanceExports.GetBigIntAPtr());
    const biStrB = this.#BufferPtrToString(
      this.WasmInstanceExports.GetBigIntBPtr());
    
    const [a, b] = [BigInt(biStrA), BigInt(biStrB)];

    // console.log("BigIntA", a)
    // console.log("BigIntB", b)
    // console.log(a + b, (a + b).toString());

    this.#LoadBigIntResult(a + b);
  }

  #SubtractBigInt(): void {
    const biStrA = this.#BufferPtrToString(this.WasmInstanceExports.GetBigIntAPtr());
    const biStrB = this.#BufferPtrToString(this.WasmInstanceExports.GetBigIntBPtr());
    
    const [a, b] = [BigInt(biStrA), BigInt(biStrB)];
    this.#LoadBigIntResult(a - b);
  }

  #MultiplyBigInt(): void {
    const biStrA = this.#BufferPtrToString(this.WasmInstanceExports.GetBigIntAPtr());
    const biStrB = this.#BufferPtrToString(this.WasmInstanceExports.GetBigIntBPtr());
    
    const [a, b] = [BigInt(biStrA), BigInt(biStrB)];
    this.#LoadBigIntResult(a * b);
  }

  #DivideBigInt(): void {
    const biStrA = this.#BufferPtrToString(this.WasmInstanceExports.GetBigIntAPtr());
    const biStrB = this.#BufferPtrToString(this.WasmInstanceExports.GetBigIntBPtr());
    
    const [a, b] = [BigInt(biStrA), BigInt(biStrB)];
    this.#LoadBigIntResult(a / b);
  }

  #CompareBigInt(): void {
    const biStrA = this.#BufferPtrToString(this.WasmInstanceExports.GetBigIntAPtr());
    const biStrB = this.#BufferPtrToString(this.WasmInstanceExports.GetBigIntBPtr());
    
    const [a, b] = [BigInt(biStrA), BigInt(biStrB)];

    if (a > b)
      this.#LoadBigIntResult(1n);
    else if (a < b)
      this.#LoadBigIntResult(-1n);
    else
      this.#LoadBigIntResult(0n);
  }

  #FormatBigInt(): void {
    const biStrA = this.#BufferPtrToString(this.WasmInstanceExports.GetBigIntAPtr());
    const a = BigInt(biStrA);
    let readable = 0;

    if (a >= 10n ** 33n) {
      readable = Number(a / 10n ** 32n) / 10;
      this.#LoadBigIntResult(readable + "Dc");

    } else if (a >= 10n ** 30n) {
      readable = Number(a / 10n ** 29n) / 10;
      this.#LoadBigIntResult(readable + "No");

    } else if (a >= 10n ** 27n) {
      readable = Number(a / 10n ** 26n) / 10;
      this.#LoadBigIntResult(readable + "Oc");

    } else if (a >= 10n ** 24n) {
      readable = Number(a / 10n ** 23n) / 10;
      this.#LoadBigIntResult(readable + "Sp");

    } else if (a >= 10n ** 21n) {
      readable = Number(a / 10n ** 20n) / 10;
      this.#LoadBigIntResult(readable + "Sx");

    } else if (a >= 10n ** 18n) {
      readable = Number(a / 10n ** 17n) / 10;
      this.#LoadBigIntResult(readable + "Qi");

    } else if (a >= 10n ** 15n) {
      readable = Number(a / 10n ** 14n) / 10;
      this.#LoadBigIntResult(readable + "Qa");
    
    } else if (a >= 10n ** 12n) {
      readable = Number(a / 10n ** 11n) / 10;
      this.#LoadBigIntResult(readable + "T");

    } else if (a >= 1_000_000_000n) {
      readable = Number(a / 100_000_000n) / 10;
      this.#LoadBigIntResult(readable + "B");
      
    } else if (a >= 1_000_000n) {
      readable = Number(a / 100_000n) / 10;
      this.#LoadBigIntResult(readable + "M");

    } else if (a >= 1000n) {
      readable = Number(a / 100n) / 10;
      this.#LoadBigIntResult(readable + "K");

    } else
      this.#LoadBigIntResult(a);
  }


  #FormatBigIntScientific(): void {
    const biStrA = this.#BufferPtrToString(this.WasmInstanceExports.GetBigIntAPtr());
    const a = BigInt(biStrA);
    const digits = a.toString().length;

    if (a >= 1000n) {
      const readable = Number(a / 10n ** (BigInt(digits) - 2n)) / 10;
      this.#LoadBigIntResult(readable + " * 10^" + (digits - 1));
    } else
      this.#LoadBigIntResult(a);
  }
  */
}