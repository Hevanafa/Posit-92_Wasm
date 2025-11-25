unit Panic;

{$Mode TP}

interface

procedure panicHalt(const msg: string);
procedure panicHalt2(const msg: string);


implementation

uses Assets, VGA;

procedure jsPanicHalt(const textPtr: pointer; const textLen: integer); external 'env' name 'panicHalt';

procedure panicHalt(const msg: string);
var
  a: word;
  msgBuffer: array[0..255] of byte;
begin
  for a:=1 to length(msg) do
    msgBuffer[a-1] := ord(msg[a]);

  jsPanicHalt(@msgBuffer, length(msg))
end;

procedure panicHalt2(const msg: string);
var
  a: word;
  msgBuffer: array[0..255] of byte;
begin
  cls($FF000000);
  printDefault('PANIC: ' + msg, 0, 0);
  flush;

  for a:=1 to length(msg) do
    msgBuffer[a-1] := ord(msg[a]);

  jsPanicHalt(@msgBuffer, length(msg))
end;

end.
