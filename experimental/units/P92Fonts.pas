unit P92Fonts;

{$Mode ObjFPC}
{$H-}  { Use ShortStrings }
{$J-}  { Don't allow assignments to typed consts }

interface

uses P92AssetHandles;

procedure LoadDefaultFont;
function GetDefaultFontHandle: TBMFontHandle;

procedure PrintDefault(const text: string; const x, y: integer);
procedure PrintDefaultCentred(const text: string; const cx, y: integer);
function MeasureDefault(const text: string): word;

function PrintCharColour(const ch: char; const x, y: integer; const colour: longword): word;


implementation

uses P92AssetRegistry, P92BMFont, P92Core;

var
  defaultFontHandle: TBMFontHandle;

function GetDefaultFontHandle: TBMFontHandle;
begin
  GetDefaultFontHandle := defaultFontHandle
end;

procedure LoadDefaultFont;
begin
{$ifdef P92_WASM}
  defaultFontHandle := RequestBMFont('assets/fonts/nokia_cellphone_fc_8.txt')
{$endif}

{$ifdef P92_SDL2}
  defaultFontHandle := LoadBMFont(bootConfig.defaultFontPath)
{$endif}
end;

procedure PrintDefault(const text: string; const x, y: integer);
begin
  PrintBMFont(defaultFontHandle, text, x, y)
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
  MeasureDefault := MeasureBMFont(defaultFontHandle, text)
end;

{ Returns the width of the glyph }
function PrintCharColour(const ch: char; const x, y: integer; const colour: longword): word;
begin
  PrintCharColour := PrintBMFontCharColour(
    defaultFontHandle, ch, x, y, colour)
end;

end.

