unit PanicDisplay;

{$Mode TP}

interface

procedure panicHaltWithDisplay(const msg: string);


implementation

procedure panicHaltWithDisplay(const msg: string);
var
  msgBuffer: array[0..255] of byte;
begin
  { TODO: Handle display }

  { Prepare string buffer }
  for a:=1 to length(msg) do
    msgBuffer[a-1] := ord(msg[a]);

  jsPanicHalt(@msgBuffer, length(msg));
end;

end;