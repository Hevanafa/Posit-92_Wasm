unit Panic;

{$Mode TP}

interface

procedure panicHalt(const msg: string);
{$ifdef WASM}
procedure panicDisplay(const msg: string);
{$endif}


implementation

{$ifdef WASM}
uses Assets, VGA;
procedure jsPanicHalt(const textPtr: PByte; const textLen: integer); external 'env' name 'panicHalt';
{$endif}
{$ifdef WIN64}
uses Logger;
{$endif}


{$ifdef WASM}
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

{$ifdef WIN64}
procedure panicHalt(const msg: string);
begin
  writeLog('PANIC: ' + msg);
  halt(1)
end;
{$endif}


{$ifdef WASM}
procedure panicDisplay(const msg: string);
var
  a: word;
  msgBuffer: array[0..255] of byte;
begin
  cls($FF000000);
  printDefault('PANIC: ' + msg, 0, 0);
  flush;

  for a:=1 to length(msg) do
    msgBuffer[a-1] := ord(msg[a]);

  jsPanicHalt(@msgBuffer, length(msg));
  { halt(1) } { This triggers _haltproc }
end;
{$endif}

end.
