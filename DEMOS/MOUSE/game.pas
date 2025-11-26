library Game;

{$Mode ObjFPC}

uses Bitmap, BMFont, Conv, FPS,
  Graphics, Keyboard, Logger, Mouse,
  Panic, SprFast, Sounds, Timing, VGA,
  Assets;

const
  SC_ESC = $01;
  SC_SPACE = $39;

var
  lastEsc: boolean;

  stringBuffer: array[0..255] of byte;

  { Game state }
  lastLeftButton: boolean;
  clicks: word;

{ Use this to set `done` to true }
procedure signalDone; external 'env' name 'signalDone';

function getStringBuffer: pointer; public name 'getStringBuffer';
begin
  getStringBuffer := @stringBuffer
end;

procedure debugStringBuffer; public name 'debugStringBuffer';
var
  a: word;
begin
  writeLog('First 20 bytes of stringBuffer');

  for a:=0 to 19 do
    writeLogI32(stringBuffer[a]);
end;

procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure debugMouse;
begin
  printDefault('Mouse: {x:' + i32str(mouseX) + ', y:' + i32str(mouseY) + '}', 0, 0);
  printDefault('Button: ' + i32str(integer(mouseButton)), 0, 8);
end;


procedure init;
begin
  initBuffer;
  initDeltaTime;
  initFPSCounter;
end;

procedure afterInit;
begin
  { Initialise game state here }
  hideCursor;
end;

procedure update;
begin
  updateDeltaTime;
  incrementFPS;

  updateMouse;

  { Your update logic here }
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);

    if lastEsc then begin
      writeLog('ESC is pressed!');
      signalDone
    end;
  end;

  if lastLeftButton <> (0 <> mouseButton and 1) then begin
    lastLeftButton := (0 <> mouseButton and 1);

    if lastLeftButton then inc(clicks);
  end;
end;

procedure draw;
var
  image: PBitmap;
  w: integer;
  s: string;
begin
  cls($FF6495ED);

  image := getImagePtr(imgGasolineMaid);
  spr(imgGasolineMaid, (vgaWidth - image^.width) div 2, (vgaHeight - image^.height) div 2);

  s := 'Clicks: ' + i32str(clicks);
  w := measureBMFont(s, _defaultFontGlyphs);
  printDefault(s, (vgaWidth - w) div 2, 160);

  drawMouse;

  debugMouse;
  drawFPS;

  flush
end;

exports
  { Main game loop }
  init,
  afterInit,
  update,
  draw;

begin
{ Starting point is intentionally left empty }
end.

