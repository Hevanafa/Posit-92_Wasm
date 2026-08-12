{
  Default boilerplate
  Mixins: bmfont, sound
}

library Game;

{$Mode ObjFPC}
{$H+}  { Use AnsiStrings }
{$J-}  { Switch off assignments to typed constants }

uses
  P92Core, P92Conversions, P92Fonts, P92WasmHost, P92AssetRegistry,
  P92Logger,
  P92Keyboard, P92Mouse,
  P92TexDraw, P92Timing, P92FPS, P92VGA,
  P92WasmHeap,
  Assets;

var
  { Game state variables }
  gameTime: double;

procedure DrawMouse;
begin
  Spr(imgCursor, mouseX, mouseY)
end;

procedure TestBasicAllocFree;
var
  p1, p2: pointer;
begin
  writelog('Begin TestBasicAllocFree');

  p1 := GetMem(1024);
  assert(p1 <> nil, 'Alloc 1024 failed');
  Freemem(p1);

  p2 := GetMem(1024);
  assert(p2 = p1, 'Expected the same address after free');
  Freemem(p2);

  writelog('End of TestBasicAllocFree');
end;

procedure TestExhaustAndCoalesce;
var
  blocks: array[0..2047] of pointer;
  a: smallint;
  big: pointer;
begin
  writelog('Begin TestExhaustAndCoalesce');

  { Exhaust the memory with 512-byte blocks }
  for a:=0 to high(blocks) do begin
    blocks[a] := getmem(512);
    assert(blocks[a] <> nil, 'Exhaustion at block ' + I32Str(a));
  end;

  assert(GetMem(512) = nil, 'Should be out-of-memory');

  { Free all }
  for a:=0 to high(blocks) do
    freemem(blocks[a]);

  { Full coalescing test }
  big := GetMem(1 shl 20);  { 20 is obtained from BuddyMaxOrder }
  assert(big <> nil, 'Coalescing to max order failed');
  freemem(big);

  writelog('End of TestExhaustAndCoalesce');
end;


procedure TestSplitNoOverlap;
var
  a, b, c: PByte;
begin
  a := getmem(1 shl 18); { 256KB }
  b := getmem(1 shl 16); { 64KB }
  c := getmem(1 shl 16); { 64KB }

  Assert((a <> nil) and (b <> nil) and (c <> nil), 'alloc failed');
  assert(abs(ptrint(a) - ptrint(b)) >= (1 shl 18), 'a/b overlap');
  assert(abs(ptrint(b) - ptrint(c)) >= (1 shl 16), 'b/c overlap');

  freemem(c);
  freemem(b);
  freemem(a)
end;

procedure OnPreload;
begin
  imgCursor := RequestImage('assets/images/cursor.png');

  imgSpecimenP92[0] := RequestImage('assets/images/specimen_p-92_1.png');
  imgSpecimenP92[1] := RequestImage('assets/images/specimen_p-92_2.png');

  imgTest := RequestImage('assets/fonts/nokia_cellphone_fc_8_0.png');
end;

procedure OnReady;
begin
  HideCursor;

  { Initialise game state here }
  gameTime := 0.0;

  TestBasicAllocFree;
  { TestExhaustAndCoalesce; }
  TestSplitNoOverlap;
end;

procedure Update;
begin
  if IsKeyDown(SC_ESCAPE) then SignalDone;

  gameTime := gameTime + DeltaTime
end;

procedure Draw;
begin
  Cls($FF6495ED);

  if (trunc(gameTime * 4) and 1) > 0 then
    Spr(imgSpecimenP92[1], 148, 84)
  else
    Spr(imgSpecimenP92[0], 148, 84);

  PrintDefaultCentred('Hello world!', VgaWidth div 2, 120);

  DrawMouse;
  DrawFPS;
end;

exports
  OnPreload, OnReady, Update, Draw;

begin
{ Starting point is intentionally left empty }
end.
