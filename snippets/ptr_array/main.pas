{
  Compile:
  E:\fpc-wasm\fpc\bin\x86_64-win64\fpc.exe -Pwasm32 -Tembedded .\main.pas
  remove-item .\main.wasm; rename-item "main" "main.wasm"

  Run:
  npx http-server
}

library Main;

{$Mode ObjFPC}

type
  PPoint = ^TPoint;
  TPoint = record
    x, y: integer;
  end;

var
  points: array[0..2] of PPoint;

procedure helloWorld; external 'env' name 'helloWorld';
procedure logI32(const value: longint); external 'env' name 'logI32';
procedure logI32Pair(const a, b: longint); external 'env' name 'logI32Pair';

function newPoint(const x, y: integer): TPoint;
begin
  newPoint.x := x;
  newPoint.y := y;
end;

procedure init;
var
  point: TPoint;
  a: word;
begin
  point := newPoint(1, 2);
  points[0] := @point;

  point := newPoint(3, 4);
  points[1] := @point;

  point := newPoint(5, 6);
  points[2] := @point;

  for a:=0 to high(points) do
    logI32Pair(points[a]^.x, points[a]^.y);
  
  helloWorld
end;

exports
  init;

begin
{ Starting point is intentionally left empty }
end.
