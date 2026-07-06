unit P92PanicDisplay;

{$Mode ObjFPC}
{$H-}{$J-}

interface

procedure PanicHaltDisplay(const msg: string);
procedure PascalPanicHaltDisplay; public name 'PascalPanicHaltDisplay';


implementation

uses
  P92Core, P92InteropBuf, P92Panic, P92VGA
{$ifdef P92_WEBGL}
  , P92WebGL
{$endif}
  ;

procedure PanicHaltDisplay(const msg: string);
var
  a, b: word;
  msgBuffer: array[0..255] of byte;
  height: word;
begin
  cls($FF550000);

  { Scanlines }
  b:=0;
  while b<vgaHeight do begin
    for a:=0 to vgaWidth-1 do
      unsafePset(a, b, $FF2A0000);

    inc(b, 3)
  end;

  print('Fatal Error', 8, 8);

  TextLabelWrap(msg, 10, 30, vgaWidth - 20);

  TextLabel('Check Console for details', 10, 40 + height);

  VgaUpload;
{$ifdef P92_WEBGL}
  WebGLPresent;
{$else}
  VgaPresent;
{$endif}

  PanicHalt(msg)
end;

procedure PascalPanicHaltDisplay;
begin
  PanicHaltDisplay(ReadInteropString)
end;

end.
