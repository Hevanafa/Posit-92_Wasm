type TBMFontGlyph = {
  id: number,
  x: number,
  y: number,
  width: number,
  height: number,
  xoffset: number,
  yoffset: number,
  xadvance: number,
  lineHeight: number
}

type BMFontWasmExports = WasmExports & {
  // AssetRegistry
  PascalBMFontLoaded: (bmfontHandle: number) => void;
  PascalBMFontFailed: (bmfontHandle: number, errorCode: number) => void;

  GetBMFontBufferPtr: () => number;
  GetBMFontBufferLen: () => number;
  SetBMFontBufferLen: (value: number) => void;
  GetBMFontBufferCapacity: () => number;
}

globalThis.BMFontMixin = <T extends Constructor<Posit92>>(Base: T) =>
class BMFontMixin extends Base {
  /**
   * @override
   */
  SetupImportObject(): void {
    super.SetupImportObject();
    
    const { env } = super.WasmImportObject;
    
    Object.assign(env, {
      JsRequestBMFont: this.#RequestBMFont.bind(this)
    });
  }

  get WasmInstanceExports(): BMFontWasmExports {
    return <BMFontWasmExports>this.WasmInstance.exports;
  }

  async #RequestBMFont(bmfontHandle: number): Promise<void> {
    const url = this.ReadInteropBuffer();

    if (debugRequests)
      console.log("ReadInteropBuffer", bmfontHandle, url);

    try {
      const res = await fetch(url);

      if (!res.ok) {
        const lines = [
          "Failed to load BMFont",
          "",
          "Path: " + url,
          "Reason: HTTP status " + res.status
        ];

        this.PanicHaltDisplay(lines.join("\n"));
        this.WasmInstanceExports.PascalBMFontFailed(bmfontHandle, 1);
        
        return;
      }

      this.WriteBMFontBuffer(await res.text());
      this.WasmInstanceExports.PascalBMFontLoaded(bmfontHandle);
    } catch (error) {
      if (error instanceof Error)
        console.error("RequestBMFont:", error);

      this.WasmInstanceExports.PascalBMFontFailed(bmfontHandle, 1);
    }
  }

  WriteBMFontBuffer(s: string): void {
    const encoder = new TextEncoder(); // Default: utf-8
    const bytes = encoder.encode(s);

    const ptr = this.WasmInstanceExports.GetBMFontBufferPtr();
    const len = bytes.length;
    const capacity = this.WasmInstanceExports.GetBMFontBufferCapacity();

    if (len > capacity)
      this.PanicHaltDisplay(`BMFont buffer overflow: ${len} > ${capacity}`);

    const memview = new Uint8Array(this.WasmInstanceExports.memory.buffer);
    memview.set(bytes, ptr);

    this.WasmInstanceExports.SetBMFontBufferLen(len);
  }
}
