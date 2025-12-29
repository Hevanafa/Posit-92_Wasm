unit PanicDisplay;

{$Mode TP}

interface

procedure panicHaltWithDisplay(const msg: string);


implementation

uses ImmedGUI, Panic, VGA;

procedure panicHaltWithDisplay(const msg: string);
var
  a: word;
  msgBuffer: array[0..255] of byte;
begin
  cls($FF550000);
  { TODO: Handle display }

  TextLabel('PANIC', 10, 10);

  TextLabelWrap(msg, 10, 30, vgaWidth - 20);


  vgaFlush;

  { Prepare string buffer }
  for a:=1 to length(msg) do
    msgBuffer[a-1] := ord(msg[a]);

  jsPanicHalt(@msgBuffer, length(msg));
end;

end.