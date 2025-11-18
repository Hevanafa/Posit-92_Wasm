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

uses Bitmap;


implementation


end.