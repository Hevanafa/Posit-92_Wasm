{
  Panic unit - Part of Posit-92 game engine
  Hevanafa

  Mainly used to halt the program immediately & output an error message to the console
}

unit Panic;

{$Mode TP}

interface

procedure panicHalt(const msg: string);


implementation

{$ifdef WASM}
uses Assets, VGA;
{$endif}
{$ifdef WIN64}
uses Logger;
{$endif}


{$ifdef WIN64}
procedure panicHalt(const msg: string);
begin
  writeLog('PANIC: ' + msg);
  halt(1)
end;

{$else}
{ Default: WASM }
procedure jsPanicHalt(const textPtr: PByte; const textLen: integer); external 'env' name 'panicHalt';

procedure panicHalt(const msg: string);
var
  a: word;
  msgBuffer: array[0..255] of byte;
begin
  for a:=1 to length(msg) do
    msgBuffer[a-1] := ord(msg[a]);

  jsPanicHalt(@msgBuffer, length(msg));
end;
{$endif}

end.
