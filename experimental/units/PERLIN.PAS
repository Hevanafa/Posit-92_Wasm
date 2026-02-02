unit Perlin;

{$Mode TP}
{$J-}

interface
  type TPerlin = record
    permutation: array[0..511] of byte;
    seed: longword;
  end;

procedure initPerlin(var p: TPerlin; const seed: longword);
function noise2D(var p: TPerlin; const x, y: double): double;


implementation

uses Maths;

procedure initPerlin(var p: TPerlin; const seed: longword);
var
  a, b, temp: smallint;
begin
  randseed := seed;
  p.seed := seed;

  for a:=0 to 255 do
    p.permutation[a] := a;
  
  { Shuffle }
  for a:=255 downto 1 do begin
    b := random(a + 1);
    temp := p.permutation[a];
    p.permutation[a] := p.permutation[b];
    p.permutation[b] := temp
  end;

  { Duplicate permutation to handle overflow }
  for a:=0 to 255 do
    p.permutation[256 + a] := p.permutation[a];
end;

function fade(const t: double): double;
begin
  fade := t * t * t * (t * (t * 6 - 15) + 10)
end;

function grad(const hash: byte; const x, y: double): double;
var
  h: byte;
  u, v: double;
  result: double;
begin
  result := 0.0;

  h := hash and $F;
  if h < 8 then u := x else u := y;

  if h < 4 then
    v := y
  else if (h = 12) or (h = 14) then
    v := x
  else
    v := 0;

  if (h and 1) = 0 then
    result := u
  else
    result := -u;

  if (h and 2) = 0 then
    result := result + v
  else
    result := result - v;

  grad := result
end;

{ The same as lerpLinear with a different parameter order }
function lerp(const t, a, b: double): double;
begin
  lerp := a + t * (b - a)
end;

function noise2D(var p: TPerlin; const x, y: double): double;
var
  xi, yi, aa, ab, ba, bb: integer;
  xf, yf, u, v: double;
  x1, x2, y1: double;
begin
  xi := floor(x) and $FF;
  yi := floor(y) and $FF;

  xf := x - floor(x);
  yf := y - floor(y);

  u := fade(xf);  v := fade(yf);

  aa := p.permutation[p.permutation[xi] + yi];
  ab := p.permutation[p.permutation[xi] + yi + 1];
  ba := p.permutation[p.permutation[xi + 1] + yi];
  bb := p.permutation[p.permutation[xi + 1] + yi + 1];

  x1 := lerp(u, grad(aa, xf, yf), grad(ba, xf - 1, yf));
  x2 := lerp(u, grad(ab, xf, yf - 1), grad(bb, xf - 1, yf - 1));
  y1 := lerp(v, x1, x2);

  noise2D := (y1 + 1) / 2
end;

end.
