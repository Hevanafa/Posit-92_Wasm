unit P92Perlin;

{$Mode ObjFPC}
{$H+}{$J-}

interface
  type TPerlin = record
    permutation: array[0..511] of byte;
    seed: longword;
  end;

procedure InitPerlin(var p: TPerlin; const seed: longword);

{ Both these functions return [0.0 .. 1.0] }
function Noise2D(var p: TPerlin; const x, y: double): double;
function Noise1D(var p: TPerlin; const x: double): double;


implementation

uses P92Maths;

procedure InitPerlin(var p: TPerlin; const seed: longword);
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

function Fade(const t: double): double;
begin
  Fade := t * t * t * (t * (t * 6 - 15) + 10)
end;

function Grad(const hash: byte; const x, y: double): double;
var
  h: byte;
  u, v: double;
begin
  Grad := 0.0;

  h := hash and $F;
  if h < 8 then u := x else u := y;

  if h < 4 then
    v := y
  else if (h = 12) or (h = 14) then
    v := x
  else
    v := 0;

  if (h and 1) = 0 then
    Grad := u
  else
    Grad := -u;

  if (h and 2) = 0 then
    Grad := Grad + v
  else
    Grad := Grad - v;
end;

{ The same as linear easing with a different parameter order }
function Lerp(const t, a, b: double): double;
begin
  Lerp := a + t * (b - a)
end;

function Noise2D(var p: TPerlin; const x, y: double): double;
var
  xi, yi, aa, ab, ba, bb: longint;
  xf, yf, u, v: double;
  x1, x2, y1: double;
begin
  xi := floor(x) and $FF;
  yi := floor(y) and $FF;

  xf := x - floor(x);
  yf := y - floor(y);

  u := Fade(xf);  v := Fade(yf);

  aa := p.permutation[p.permutation[xi] + yi];
  ab := p.permutation[p.permutation[xi] + yi + 1];
  ba := p.permutation[p.permutation[xi + 1] + yi];
  bb := p.permutation[p.permutation[xi + 1] + yi + 1];

  x1 := Lerp(u, Grad(aa, xf, yf), Grad(ba, xf - 1, yf));
  x2 := Lerp(u, Grad(ab, xf, yf - 1), Grad(bb, xf - 1, yf - 1));
  y1 := Lerp(v, x1, x2);

  Noise2D := (y1 + 1) / 2
end;

function Noise1D(var p: TPerlin; const x: double): double;
var
  xi, a, b: longint;
  xf, u: double;
  g1, g2: double;
begin
  xi := floor(x) and $FF;
  xf := x - floor(x);

  u := Fade(xf);
  
  a := p.permutation[xi];
  b := p.permutation[xi + 1];

  { Simple gradient: +1 or -1 }
  if (a and 1) = 0 then
    g1 := xf
  else
    g1 := -xf;

  if (b and 1) = 0 then
    g2 := xf - 1
  else
    g2 := -(xf - 1);

  Noise1D := (Lerp(u, g1, g2) + 1) / 2
end;

end.
