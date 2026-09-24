{
  Immediate GUI Prompt Box Implementation
  Part of Posit-92 game engine
}

library Game;

{$Mode ObjFPC}
{$H+}{$J-}

uses
  P92Core, P92Fonts, P92Conversions, P92FPS, P92WasmHost, P92AssetRegistry,
  P92Graphics, P92Geometry, P92Loading, P92BMFont,
  P92Tex, P92TexDraw, P92TexEffects,
  P92ImmediateGUI, ImmediateGUIPromptBox,
  P92Keyboard, P92Mouse,
  P92Panic, P92Timing, P92VGA,
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

  PromptKeyTest = 'TestPrompt';

var
  lastEsc: boolean;

  { Game state variables }
  gameTime: double;

  clicks: word;
  showFPS: TCheckboxState;

procedure DrawFPS;
begin
  printDefault('FPS:' + I32Str(getLastFPS), 240, 0);
end;

procedure DrawMouse;
begin
  if HasHoveredWidget then
    Spr(texHandCursor, GetMouseX - 5, GetMouseY - 1)
  else
    Spr(texCursor, GetMouseX, GetMouseY);
end;


procedure OnPreload;
begin
  texCursor := RequestImage('assets/images/cursor.png');
  texHandCursor := RequestImage('assets/images/hand.png');

  texDosuEXE[0] := RequestImage('assets/images/dosu_1.png');
  texDosuEXE[1] := RequestImage('assets/images/dosu_2.png');

  texWinNormal := RequestImage('assets/images/win_normal.png');
  texWinHovered := RequestImage('assets/images/win_hovered.png');
  texWinPressed := RequestImage('assets/images/win_pressed.png');

  texPromptBG := RequestImage('assets/images/prompt_bg.png');
  texPromptButtonNormal := RequestImage('assets/images/btn_prompt_normal.png');
  texPromptButtonPressed := RequestImage('assets/images/btn_prompt_pressed.png');

  fontBlack := RequestBMFont('assets/fonts/p92_sans_8_regular.txt');
  fontPicotron := RequestBMFont('assets/fonts/picotron_8px.txt');
end;

procedure OnReady;
var
  fontPtr: PBMFont;
begin
  HideCursor;

  { Initialise game state here }
  gameTime := 0.0;

  InitImmediateGUI;
  GuiSetFont(GetDefaultFontHandle);
  SetPromptBoxAssets(texPromptBG, texPromptButtonNormal, texPromptButtonNormal, texPromptButtonPressed);

  fontPtr := BorrowBMFontPtr(fontBlack);
  ReplaceColour(fontPtr^.texHandle, $FFFFFFFF, $FF000000);

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
  SetClickConsumed(false)
end;

procedure Draw;
var
  w: integer;
  s: string;
begin
  Cls(CornflowerBlue);

  if UnderButton('Under button', 50, 20, 30, 24) then
    inc(clicks);

  if UnderImageButton(
    (vgaWidth - GetTexWidth(texWinNormal)) div 2, 88,
    texWinNormal, texWinHovered, texWinPressed) then
      ShowPromptBox('Accept?', PromptKeyTest);

  s := 'Clicks: ' + i32str(clicks);
  w := MeasureDefault(s);
  TextLabel(s, (vgaWidth - w) div 2, 120);

  case PromptBox of
    PromptResultYes:
      case GetPromptKey of
        PromptKeyTest: inc(clicks, 100);
      end;
    PromptResultNo:;
    else
  end;

  DrawMouse;

  if showFPS.checked then DrawFPS;
end;

procedure Init;
var
  appConfig: TP92AppConfig;
begin
  appConfig := DefaultP92AppConfig;

  P92Start(appConfig);
end;

exports
  Init,
  OnPreload,
  OnReady,
  Update,
  Draw;

begin
{ Starting point is intentionally left empty }
end.

