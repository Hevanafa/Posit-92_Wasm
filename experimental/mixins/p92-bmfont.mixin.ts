// type BMFontManifest = Map<string, { path: string, setter: string, glyphSetter: string }>;

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
}

type BMFontWasmImports = WasmImports & {
  env: {
    JsRequestBMFontLegacy: (fontPtr: number, fontGlyphsPtr: number) => Promise<void>
  }
};

globalThis.BMFontMixin = <T extends Constructor<Posit92>>(Base: T) =>
class BMFontMixin extends Base {
  /**
   * @override
   */
  SetupImportObject(): void {
    super.SetupImportObject();
    
    const { env } = super.WasmImportObject;
    
    Object.assign(env, {
      JsRequestBMFont: this.#RequestBMFontLegacy.bind(this)
    });
  }

  #NewBMFontGlyph = (): TBMFontGlyph => ({
    id: 0,
    x: 0,
    y: 0,
    width: 0,
    height: 0,
    xoffset: 0,
    yoffset: 0,
    xadvance: 0,
    lineHeight: 0
  });

  get WasmInstanceExports(): BMFontWasmExports {
    return <BMFontWasmExports>this.WasmInstance.exports;
  }

  /**
   * Used by Pascal
   * @deprecated
   */
  async #RequestBMFontLegacy(bmfontHandle: number, fontPtr: number, fontGlyphsPtr: number): Promise<void> {
    const url = this.ReadInteropBuffer();

    if (debugRequests)
      console.log("ReadInteropBuffer", bmfontHandle, url);

    let fontData = "";

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

      fontData = await res.text();
    } catch (error) {
      if (error instanceof Error)
        console.error("RequestBMFont:", error);

      this.WasmInstanceExports.PascalBMFontFailed(bmfontHandle, 1);

      return;
    }

    const lines = fontData.endsWith("\r\n") ? fontData.split("\r\n") : fontData.split("\n");

    let txtLine = "";
    let pairs: Array<StringPair>;
    
    // eslint-disable-next-line @typescript-eslint/no-unused-vars, prefer-const
    let k = "", v = "";

    let fontface = "";
    let filename = "";
    let lineHeight = 0;

    const fontGlyphs: Map<number, TBMFontGlyph> = new Map();
    let glyphCount = 0;
    const spacing = [0, 0];

    for (const line of lines) {
      txtLine = line.replaceAll(/\s+/g, " ");
      
      pairs = txtLine.split(" ").map(part => <StringPair>part.split("="));

      if (txtLine.startsWith("info")) {
        for (const [k, v] of pairs) {
          switch (k) {
            case "face":
              const result = txtLine.match(/face=\"(.*?)\"/);
              fontface = result?.[1] ?? "";

              console.log("Loading BMFont", fontface);
              break;

            case "spacing":
              const [x, y] = v.split(",").map(s => Number(s));

              // console.log("spacing", x, y);
              spacing[0] = x;
              spacing[1] = y;
          }
        }


      } else if (txtLine.startsWith("common")) {
        [, v] = <StringPair>(pairs.find(pair => pair[0] == "lineHeight"));
        lineHeight = parseInt(v);

      } else if (txtLine.startsWith("page")) {
        [, v] = <StringPair>(pairs.find(pair => pair[0] == "file"));
        filename = v.replaceAll(/"/g, "");

      } else if (txtLine.startsWith("char") && !txtLine.startsWith("chars")) {
        const tempGlyph = this.#NewBMFontGlyph();

        for (const [k, v] of pairs) {
          switch (k) {
            case "id": tempGlyph.id = parseInt(v); break;
            case "x": tempGlyph.x = parseInt(v); break;
            case "y": tempGlyph.y = parseInt(v); break;
            case "width": tempGlyph.width = parseInt(v); break;
            case "height": tempGlyph.height = parseInt(v); break;
            case "xoffset": tempGlyph.xoffset = parseInt(v); break;
            case "yoffset": tempGlyph.yoffset = parseInt(v); break;
            case "xadvance": tempGlyph.xadvance = parseInt(v); break;
          }
        }

        fontGlyphs.set(tempGlyph.id, tempGlyph);
        glyphCount++;
      }
    }

    if (debugRequests)
      console.log("Loaded", glyphCount, "glyphs");

    // Load TBMFont
    const fontMem = new DataView(this.WasmInstanceExports.memory.buffer, fontPtr);

    let offset = 0;
    offset += 16;  // Skip fontface string
    offset += 64;  // Skip filename string

    // true makes it little-endian
    fontMem.setUint16(offset, lineHeight, true);
    fontMem.setUint8(offset + 2, spacing[0]);
    fontMem.setUint8(offset + 3, spacing[1]);

    // Load glyphs
    const glyphsMem = new DataView(this.WasmInstanceExports.memory.buffer, fontGlyphsPtr);

    for (const charID of fontGlyphs.keys()) {
      const glyph = fontGlyphs.get(charID)!;

      // Range check
      if (charID < 32 || charID > 126) continue;

      // 16 is from the 8 fields of TBMFontGlyph, all 2 bytes
      const glyphOffset = charID * 16;

      glyphsMem.setUint16(glyphOffset + 0, glyph.id, true);

      glyphsMem.setUint16(glyphOffset + 2, glyph.x, true);
      glyphsMem.setUint16(glyphOffset + 4, glyph.y, true);
      glyphsMem.setUint16(glyphOffset + 6, glyph.width, true);
      glyphsMem.setUint16(glyphOffset + 8, glyph.height, true);

      glyphsMem.setInt16(glyphOffset + 10, glyph.xoffset, true);
      glyphsMem.setInt16(glyphOffset + 12, glyph.yoffset, true);
      glyphsMem.setInt16(glyphOffset + 14, glyph.xadvance, true);
    }

    if (debugRequests)
      console.log("RequestBMFont", fontface, "completed");

    this.WriteInteropBuffer(filename);
    this.WasmInstanceExports.PascalBMFontLoaded(bmfontHandle);
  }
};
