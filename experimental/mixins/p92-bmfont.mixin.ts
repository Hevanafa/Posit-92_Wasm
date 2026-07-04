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

type BMFontWasmImports = WasmImports & {
  env: {
    JsRequestBMFont: (fontPtr: number, fontGlyphsPtr: number) => Promise<void>
  }
};

// Obligatory for mixins
type Constructor<T = {}> = new (...args: any[]) => T;

interface IBMFont {
  // List the public members
}

const BMFontMixin = <T extends Constructor<Posit92>>(Base: T) =>
class extends Base {
  /**
   * @override
   */
  SetupImportObject(): void {
    const { env } = super.WasmImportObject;
    
    Object.assign(env, {
      JsRequestBMFont: this.#RequestBMFont.bind(this)
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

  async LoadBMFont(url: string, fontPtr: number, fontGlyphsPtr: number): Promise<void> {
    this.AssertString(url);
    this.AssertNumber(fontPtr);
    this.AssertNumber(fontGlyphsPtr);

    const res = await fetch(url);
    const text = await res.text();

    const lines = text.endsWith("\r\n") ? text.split("\r\n") : text.split("\n");

    let txtLine = "";
    let pairs: Array<StringPair>;
    
    // eslint-disable-next-line @typescript-eslint/no-unused-vars, prefer-const
    let k = "", v = "";

    let fontface = "";
    let filename = "";
    let lineHeight = 0;

    const fontGlyphs: Map<number, TBMFontGlyph> = new Map();
    let glyphCount = 0;
    let imgHandle = 0;
    const spacing = [0, 0];

    for (const line of lines) {
      txtLine = line.replaceAll(/\s+/g, " ");
      
      pairs = txtLine.split(" ").map(part => <StringPair>part.split("="));

      if (txtLine.startsWith("info")) {
        // [k, v] = <StringPair>(pairs.find(pair => pair[0] == "face"));

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

    console.log("Loaded", glyphCount, "glyphs");

    // Load font bitmap
    imgHandle = await this.LoadImage(filename);

    // Load TBMFont
    const fontMem = new DataView(
      this.WasmInstance.exports.memory.buffer,
      fontPtr);

    let offset = 0;
    offset += 16;  // Skip fontface string
    offset += 64;  // Skip filename string

    // true makes it little-endian
    fontMem.setUint16(offset, lineHeight, true);
    fontMem.setUint8(offset + 2, spacing[0]);
    fontMem.setUint8(offset + 3, spacing[1]);
    fontMem.setInt32(offset + 4, imgHandle, true);

    // Load glyphs
    const glyphsMem = new DataView(
      this.WasmInstance.exports.memory.buffer,
      fontGlyphsPtr);

    for (const charID of fontGlyphs.keys()) {
      const glyph = fontGlyphs.get(charID)!;

      // Range check
      if (charID < 32 || charID > 126) continue;

      // 16 is from the 8 fields of TBMFontGlyph, all 2 bytes
      const glyphOffset = (charID - 32) * 16;

      glyphsMem.setUint16(glyphOffset + 0, glyph.id, true);

      glyphsMem.setUint16(glyphOffset + 2, glyph.x, true);
      glyphsMem.setUint16(glyphOffset + 4, glyph.y, true);
      glyphsMem.setUint16(glyphOffset + 6, glyph.width, true);
      glyphsMem.setUint16(glyphOffset + 8, glyph.height, true);

      glyphsMem.setInt16(glyphOffset + 10, glyph.xoffset, true);
      glyphsMem.setInt16(glyphOffset + 12, glyph.yoffset, true);
      glyphsMem.setInt16(glyphOffset + 14, glyph.xadvance, true);
    }

    console.log("loadBMFont", fontface, "completed");
  }

  async #RequestBMFont(fontPtr: number, fontGlyphsPtr: number): Promise<void> {
    const url = this.ReadInteropBuffer();

    console.log("RequestBMFont url", url);

    const res = await fetch(url);
    const text = await res.text();

    this.WasmInstance.exports.IncAssetReadyCount();

    const lines = text.endsWith("\r\n") ? text.split("\r\n") : text.split("\n");

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

    console.log("Loaded", glyphCount, "glyphs");

    // Load TBMFont
    const fontMem = new DataView(this.WasmInstance.exports.memory.buffer, fontPtr);

    let offset = 0;
    offset += 16;  // Skip fontface string
    offset += 64;  // Skip filename string

    // true makes it little-endian
    fontMem.setUint16(offset, lineHeight, true);
    fontMem.setUint8(offset + 2, spacing[0]);
    fontMem.setUint8(offset + 3, spacing[1]);
    // fontMem.setInt32(offset + 4, imgHandle, true);

    // Load font bitmap

    this.WriteInteropBuffer(filename);
    // This uses a reserved imgHandle provided by RequestBMFont from Pascal side
    await this.RequestImage(fontMem.getInt32(offset + 4, true));

    // Load glyphs
    const glyphsMem = new DataView(this.WasmInstance.exports.memory.buffer, fontGlyphsPtr);

    for (const charID of fontGlyphs.keys()) {
      const glyph = fontGlyphs.get(charID)!;

      // Range check
      if (charID < 32 || charID > 126) continue;

      // 16 is from the 8 fields of TBMFontGlyph, all 2 bytes
      const glyphOffset = (charID - 32) * 16;

      glyphsMem.setUint16(glyphOffset + 0, glyph.id, true);

      glyphsMem.setUint16(glyphOffset + 2, glyph.x, true);
      glyphsMem.setUint16(glyphOffset + 4, glyph.y, true);
      glyphsMem.setUint16(glyphOffset + 6, glyph.width, true);
      glyphsMem.setUint16(glyphOffset + 8, glyph.height, true);

      glyphsMem.setInt16(glyphOffset + 10, glyph.xoffset, true);
      glyphsMem.setInt16(glyphOffset + 12, glyph.yoffset, true);
      glyphsMem.setInt16(glyphOffset + 14, glyph.xadvance, true);
    }

    console.log("loadBMFont", fontface, "completed");
  }

  async LoadBMFontFromManifest(manifest: BMFontManifest): Promise<void> {
    const entries = Object.entries(manifest);

    const promises = entries.map(([key, params]) => {
      const setter = this.WasmInstance.exports[params.setter];

      if (typeof setter != "function") {
        console.error("loadBMFontFromManifest: Missing setter", setter);
        return { key, setterPtr: 0 };
      }

      const glyphSetter = this.WasmInstance.exports[params.glyphSetter];

      if (typeof glyphSetter != "function") {
        console.error("loadBMFontFromManifest: Missing glyphSetter", params.glyphSetter);
        return { key, glyphSetterPtr: 0 };
      }

      const [setterPtr, glyphSetterPtr] = [setter(), glyphSetter()];

      return this.LoadBMFont(params.path, setterPtr, glyphSetterPtr).then(() => {
        // On success
        this.WasmInstance.exports.IncAssetReadyCount();

        return { key, path: params.path, setterPtr, glyphSetterPtr };
      });
    });

    const results = await Promise.all(promises);

    const failures = results.filter(item => item.setterPtr == 0 || item.glyphSetterPtr == 0);

    if (failures.length > 0) {
      console.error(
        "Failed to load assets:",
        failures.map(item => item.key).join(", "));
      
      throw new Error("Failed to load some assets");
    }

    // for (const item of results) ;
  }
} as Constructor<IBMFont> & T;
