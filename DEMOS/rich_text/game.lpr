library Game;

{$Mode ObjFPC}
{$H+}
{$J-}

uses
  P92Core, P92AssetRegistry, P92WasmHost,
  P92Conversions, P92FPS, P92Logger,
  P92Keyboard, P92Mouse,
  P92Tex, P92TexDraw,
  P92RichText, P92Timing, P92VGA,
  Assets;

const
  CornflowerBlue = $FF6495ED;

  Palette: array of longword = (
    $FF000000,
    $FFFF5555,
    $FF55FF55,
    $FF5555FF
  );

var
  lastEsc: boolean;

  { Init your game state here }
  actualGameState: TGameStates;
  gameTime: double;


procedure printDefault(const text: string; const x, y: integer);
begin
  printBMFont(defaultFont, defaultFontGlyphs, text, x, y)
end;

procedure printDefaultCentred(const text: string; const cx, y: integer);
var
  w: word;
begin
  w := measureDefault(text);
  printDefault(text, cx - w div 2, y)
end;

function measureDefault(const text: string): word;
begin
  measureDefault := measureBMFont(defaultFontGlyphs, text)
end;

procedure drawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure drawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure beginLoadingState;
begin
  actualGameState := GameStateLoading;
  fitCanvas;
  loadAssets
end;

procedure beginPlayingState;
begin
  hideCursor;
  fitCanvas;

  { Initialise game state here }
  actualGameState := GameStatePlaying;
  gameTime := 0.0;

  rtfSetFont(defaultFont, defaultFontGlyphs);

  rtfSetBoldFont(boldFont, boldFontGlyphs);
  rtfSetItalicFont(italicFont, italicFontGlyphs);
  rtfSetBoldItalicFont(boldItalicFont, boldItalicFontGlyphs);
end;


procedure init;
begin
  initHeapMgr;
  initDeltaTime;
  initFPSCounter
end;

procedure afterInit;
begin
  beginPlayingState
end;

procedure update;
begin
  updateDeltaTime;
  incrementFPS;

  { Handle inputs }
  updateMouse;

  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);

    if lastEsc then begin
      writeLog('ESC is pressed!');
      signalDone
    end;
  end;

  { Handle game state updates }
  gameTime := gameTime + dt
end;

procedure draw;
begin
  if actualGameState = GameStateLoading then begin
    renderLoadingScreen;
    exit
  end;

  cls(CornflowerBlue);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  RichTextLabel('\bBold text,\plain Regular text', 20, 120, Palette);
  RichTextLabel('Black text\cf1 Red text \cf0Black text', 20, 140, Palette);
  RichTextLabel('\bBold,\b0\i Italic,\i0\b\i Bold italic', 20, 150, Palette);
  RichTextLabel('\cf1Colour 1 \cf2Colour 2 \cf3 Colour 3', 20, 160, Palette);

  drawMouse;
  drawFPS;

  vgaFlush
end;

exports
  beginLoadingState,
  init, afterInit, update, draw;

begin
{ Starting point is intentionally left empty }
end.

