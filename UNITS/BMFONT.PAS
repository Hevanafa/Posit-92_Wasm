unit BMFont;

interface

type
  TBMFontGlyph = record
    id: word;
    x, y, width, height: word;
    xoffset, yoffset: integer;
    xadvance: integer;
  end;
  TBMFont = record
    face: string;
    filename: string;
    lineHeight: word;
    imgHandle: longword;
  end;

{ procedure printBMFont(const text: string; const x, y: integer; const font: TBMFont; const fontGlyphs: array of TBMFontGlyph); public name 'printBMFont'; }
procedure printBMFont(const text: string; const x, y: integer); public name 'printBMFont';


implementation

uses Bitmap;

procedure printBMFont(const text: string; const x, y: integer);
begin
  { TODO: Write the content }
end;

end.