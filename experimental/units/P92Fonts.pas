unit P92Fonts;

{$Mode ObjFPC}
{$H+}{$J-}

interface

uses P92BMFont;

procedure LoadDefaultFont;

procedure PrintDefault(const text: string; const x, y: integer);
procedure PrintDefaultCentred(const text: string; const cx, y: integer);
function MeasureDefault(const text: string): word;

function PrintCharColour(const ch: char; const x, y: integer; const colour: longword): word;


implementation

uses P92AssetRegistry;

var
  defaultFontHandle: longint;

procedure LoadDefaultFont;
begin
  defaultFontHandle := RequestBMFont('assets/fonts/nokia_cellphone_fc_8.txt')
end;

procedure PrintDefault(const text: string; const x, y: integer);
begin
  PrintBMFont(bmfonts[defaultFontHandle].font, text, x, y)
end;

procedure PrintDefaultCentred(const text: string; const cx, y: integer);
var
  w: word;
begin
  w := MeasureDefault(text);
  PrintDefault(text, cx - w div 2, y)
end;

function MeasureDefault(const text: string): word;
begin
  MeasureDefault := MeasureBMFont(bmfonts[defaultFontHandle].font, text)
end;

{ Returns the width of the glyph }
function PrintCharColour(const ch: char; const x, y: integer; const colour: longword): word;
begin
  PrintCharColour := PrintBMFontCharColour(
    bmfonts[defaultFontHandle].font, ch, x, y, colour)
end;

end.

