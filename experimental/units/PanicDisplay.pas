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
  height: word;
begin
  cls($FF550000);

  TextLabel('PANIC', 10, 10);

  height := guiMeasureTextWrapHeight(msg, vgaWidth - 20);
  TextLabelWrap(msg, 10, 30, vgaWidth - 20);

  TextLabel('Check Console for details', 10, 40 + height);

  vgaFlush;

  { Prepare string buffer }
  for a:=1 to length(msg) do
    msgBuffer[a-1] := ord(msg[a]);

  jsPanicHalt(@msgBuffer, length(msg));
end;

end.