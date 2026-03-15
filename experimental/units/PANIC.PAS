{
  Panic unit - Part of Posit-92 game engine
  Hevanafa

  Mainly used to halt the program immediately & output an error message to the console
}

unit Panic;

{$Mode TP}

interface

{$ifdef WASM}
procedure jsPanicHalt(const textPtr: PByte; const textLen: integer); external 'env' name 'jsPanicHalt';
{$endif}

procedure panicHalt(const msg: string);


implementation

{$ifdef WASM}
uses VGA;
{$endif}
{$ifdef Windows}
uses Logger, Windows;
{$endif}


{$ifdef Windows}
procedure panicHalt(const msg: string);
var
  s: string;
  p: pchar;
begin
  s := 'PANIC: ' + msg + #0;
  MessageBox(0, PChar(@s[1]), 'Panic', MB_OK or MB_ICONERROR);
  halt(1)
end;

{$else}
{ Default: WASM }
procedure panicHalt(const msg: string);
var
  a: word;
  msgBuffer: array[0..255] of byte;
begin
  for a:=1 to length(msg) do
    msgBuffer[a-1] := ord(msg[a]);

  jsPanicHalt(@msgBuffer, length(msg));
  halt(1)
end;
{$endif}

end.
