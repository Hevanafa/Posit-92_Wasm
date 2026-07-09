unit P92Fonts;

{$Mode ObjFPC}
{$H+}{$J-}

interface

uses P92BMFont;

procedure LoadDefaultFont;

function DefaultFontPtr: PBMFont;

procedure PrintDefault(const text: string; const x, y: integer);
procedure PrintDefaultCentred(const text: string; const cx, y: integer);
function MeasureDefault(const text: string): word;

function PrintCharColour(const ch: char; const x, y: integer; const colour: longword): word;


implementation

uses P92AssetRegistry;

var
  defaultFont: TBMFont;

procedure LoadDefaultFont;
var
  bmfontHandle: longint;
begin
  defaultFont := default(TBMFont);
  bmfontHandle := RequestBMFont('assets/fonts/nokia_cellphone_fc_8.txt');
  GetBMFontEntryPtr(bmfontHandle)^.fontPtr := @defaultFont;
end;

function DefaultFontPtr: PBMFont;
begin
  DefaultFontPtr := @defaultFont
end;

procedure PrintDefault(const text: string; const x, y: integer);
begin
  PrintBMFont(defaultFont, text, x, y)
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
  MeasureDefault := MeasureBMFont(defaultFont, text)
end;

{ Returns the width of the glyph }
function PrintCharColour(const ch: char; const x, y: integer; const colour: longword): word;
begin
  PrintCharColour := PrintBMFontCharColour(
    defaultFont, ch, x, y, colour)
end;

end.

