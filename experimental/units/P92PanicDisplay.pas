unit P92PanicDisplay;

{$Mode ObjFPC}
{$H-}{$J-}

interface

procedure PanicHaltDisplay(const msg: AnsiString);
{$ifdef P92_WASM}
procedure PascalPanicHaltDisplay; public name 'PascalPanicHaltDisplay';
{$endif}


implementation

uses
  P92Core, P92TexDraw, P92Panic, P92VGA
{$ifdef P92_WASM}
  , P92InteropBuf
{$endif}
{$ifdef P92_WEBGL}
  , P92WebGL
{$endif}
  ;

procedure PanicHaltDisplay(const msg: AnsiString);
var
  a, b: word;
begin
  cls($FF550000);

  { Scanlines }
  b:=0;
  while b < VgaHeight do begin
    for a:=0 to VgaWidth - 1 do
      unsafePset(a, b, $FF2A0000);

    inc(b, 3)
  end;

  Print('Fatal Error', 8, 8);

  PrintWrap(msg, 8, 24, VgaWidth - 16);

  Print('Check Console for details', 8, VgaHeight - 16);

  VgaUpload;
{$ifdef P92_WEBGL}
  WebGLPresent;
{$else}
  VgaPresent;
{$endif}

  PanicHalt(msg)
end;

{$ifdef P92_WASM}
procedure PascalPanicHaltDisplay;
begin
  PanicHaltDisplay(ReadInteropString)
end;
{$endif}

end.
