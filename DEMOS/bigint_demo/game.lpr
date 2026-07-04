{
  Title: BigInt demo
  Mixins: bigint
}

library Game;

{$Mode ObjFPC}
{$H+}{$J-}

uses
  P92Core, P92Fonts, P92WasmHost, P92AssetRegistry,
  P92InteropBuf, P92Logger,
  P92Conversions, P92FPS,
  P92SoftwareTexDraw,
  P92Keyboard, P92Mouse,
  P92Timing, P92VGA,
  P92BigInt, Assets;

var
  lastEsc: boolean;
  lastLeft, lastRight: boolean;

  { Game state variables }
  gameTime: double;

  points: string; { BigInt }
  formattedPoints: string;
  scientificPoints: string;

procedure DrawMouse;
begin
  spr(imgCursor, mouseX, mouseY)
end;

procedure LoadGameAssets;
begin
  imgCursor := RequestImage('assets/images/cursor.png');
  imgDosuEXE[0] := RequestImage('assets/images/dosu_1.png');
  imgDosuEXE[1] := RequestImage('assets/images/dosu_2.png');

  RequestBMFont('assets/fonts/nokia_cellphone_fc_8.txt', DefaultFontPtr, DefaultFontGlyphsPtr)
end;

procedure OnReady;
begin
  hideCursor;
  fitCanvas;

  { Initialise game state here }
  gameTime := 0.0;

  points := '1234';

  BigIntSetA(points);
  formattedPoints := BigIntFormat(points);
  scientificPoints := BigIntFormatScientific(points);

  { Addition }
  BigIntSetA('20');
  writelog('a = ' + BigIntFetchRegA);
  BigIntSetB('57');
  writelog('b = ' + BigIntFetchRegB);
  JsBigIntAdd;
  WriteLog(BigIntFetchResult);

  { Subtraction }
  BigIntSetA('56');
  BigIntSetB('78');
  JsBigIntSubtract;
  WriteLog(BigIntFetchResult);

  { Multiplication }
  BigIntSetA('6');
  BigIntSetB('7');
  JsBigIntMultiply;
  writelog(BigIntFetchResult);

  { Division }
  BigIntSetA('80');
  BigIntSetB('8');
  JsBigIntDivide;
  writelog(BigIntFetchResult);

  { Comparison }
  BigIntSetA('6');
  BigIntSetB('7');
  JsBigIntCompare;
  writeLog('compare(a, b) = ' + BigIntFetchResult);
end;


procedure PrintCentred(const text: string; const y: integer);
var
  w: integer;
begin
  w := MeasureDefault(text);
  PrintDefault(text, (vgaWidth - w) div 2, y)
end;

procedure Update;
begin
  { Your Update logic here }
  if lastEsc <> isKeyDown(SC_ESCAPE) then begin
    lastEsc := isKeyDown(SC_ESCAPE);

    if lastEsc then begin
      writeLog('ESC is pressed!');
      signalDone
    end;
  end;

  if lastLeft <> isKeyDown(SC_LEFT) then begin
    lastLeft := isKeyDown(SC_LEFT);

    if lastLeft then begin
      BigIntSetA(points);
      BigIntSetB('1000');
      JsBigIntCompare;

      if parseInt(BigIntFetchResult) > 0 then begin
        BigIntSetB('10');
        JsBigIntDivide;

        points := BigIntFetchResult;
        formattedPoints := BigIntFormat(points);
        scientificPoints := BigIntFormatScientific(points);
      end;
    end;
  end;

  if lastRight <> isKeyDown(SC_RIGHT) then begin
    lastRight := isKeyDown(SC_RIGHT);

    if lastRight then begin
      BigIntSetA(points);
      BigIntSetB('10');
      JsBigIntMultiply;

      points := BigIntFetchResult;
      formattedPoints := BigIntFormat(points);
      scientificPoints := BigIntFormatScientific(points);
    end;
  end;

  gameTime := gameTime + DeltaTime
end;

procedure Draw;
begin
  cls($FF6495ED);

  if (trunc(gameTime * 4) and 1) > 0 then
    spr(imgDosuEXE[1], 148, 88)
  else
    spr(imgDosuEXE[0], 148, 88);

  PrintCentred(points, 140);
  PrintCentred(formattedPoints, 150);
  PrintCentred(scientificPoints, 160);

  PrintCentred('Left - Decrease | Right - Increase', 180);

  DrawMouse;
  DrawFPS;

  VgaUpload;
  VgaPresent
end;

exports
  LoadGameAssets, OnReady,
  Update, Draw;

begin
{ Starting point is intentionally left empty }
end.

