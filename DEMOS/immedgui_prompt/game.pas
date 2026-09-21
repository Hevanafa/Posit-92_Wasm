{
  Immediate GUI Prompt Box Implementation
  Part of Posit-92 game engine
}

library Game;

{$Mode ObjFPC}
{$H+}{$J-}

uses
  P92Core, P92Fonts, P92Conversions, P92FPS, P92WasmHost,
  P92Graphics, P92Geometry, P92Loading,
  P92Tex, P92TexDraw, P92TexEffects,
  P92ImmediateGUI, ImmediateGUIPromptBox,
  P92Keyboard, P92Logger, P92Mouse,
  P92Panic, P92Timing, P92WasmMemMgr, P92VGA,
  Assets;

type
  TGameStates = (
    GameStateIntro = 1,
    GameStateLoading = 2,
    GameStatePlaying = 3
  );

const
  SC_ESC = $01;
  SC_SPACE = $39;

  CornflowerBlue = $FF6495ED;
  SemitransparentBlack = $80000000;

  { Prompts enum }
  PromptTest = 1;

var
  lastEsc: boolean;

  { Game state variables }
  gameTime: double;

  clicks: word;
  showFPS: TCheckboxState;

procedure DrawFPS;
begin
  printDefault('FPS:' + i32str(getLastFPS), 240, 0);
end;

procedure DrawMouse;
begin
  if HasHoveredWidget then
    Spr(imgHandCursor, GetMouseX - 5, GetMouseY - 1)
  else
    Spr(imgCursor, GetMouseX, GetMouseY);
end;


procedure OnPreload;
begin
  { TODO: Load the assets from manifest }
end;

procedure OnReady;
begin
  HideCursor;

  { Initialise game state here }
  gameTime := 0.0;

  InitImmediateGUI;
  GuiSetFont(defaultFont);
  setPromptBoxAssets(imgPromptBG, imgPromptButtonNormal, imgPromptButtonNormal, imgPromptButtonPressed);

  ReplaceColour(blackFont.imgHandle, $FFFFFFFF, $FF000000);

  clicks := 0;
  showFPS.checked := true;
end;


procedure Update;
begin
  if lastEsc <> isKeyDown(SC_ESC) then begin
    lastEsc := isKeyDown(SC_ESC);

    if lastEsc then SignalDone;
  end;

  gameTime := gameTime + DeltaTime;

  resetWidgetIndices;
  { Used by prompt box }
  setClickConsumed(false)
end;

procedure draw;
var
  w: integer;
  s: string;
begin
  if actualGameState = GameStateLoading then begin
    renderLoadingScreen;
    exit
  end;
  
  cls(CornflowerBlue);

  if UnderButton('Under button', 50, 20, 30, 24) then
    inc(clicks);

  if UnderImageButton((vgaWidth - getImageWidth(imgWinNormal)) div 2, 88, imgWinNormal, imgWinHovered, imgWinPressed) then
    ShowPromptBox('Accept?', PromptTest);

  s := 'Clicks: ' + i32str(clicks);
  w := MeasureDefault(s);
  TextLabel(s, (vgaWidth - w) div 2, 120);

  case PromptBox of
    PromptYes:
      case getPromptKey of
        PromptTest: inc(clicks, 100);
      end;
    PromptNo:;
    else
  end;

  ResetActiveWidget;
  DrawMouse;

  if showFPS.checked then DrawFPS;

  vgaFlush
end;

exports
  OnPreload,
  OnReady,
  Update,
  Draw;

begin
{ Starting point is intentionally left empty }
end.

