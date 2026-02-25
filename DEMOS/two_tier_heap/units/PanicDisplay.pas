unit PanicDisplay;

{$Mode TP}

interface

procedure panicHaltWithDisplay(const msg: string);


implementation

uses ImmedGUI, Panic, VGA;

procedure panicHaltWithDisplay(const msg: string);
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