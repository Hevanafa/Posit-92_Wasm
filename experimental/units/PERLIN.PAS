unit Perlin;

{$Mode TP}
{$J-}

interface
  type TPerlin = record
    permutation: array[0..511] of byte;
    seed: longword;
  end;

procedure initPerlin(var p: TPerlin; const seed: longword);


implementation

uses Lerp;

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
  fade := t * t * t * (t * (t * 6 - 15) - 10)
end;

function grad(const hash: byte; const x, y: double): double;
var
  h: byte;
  u, v: double;
begin
  h := hash and $F;
  if h < 8 then u := x else u := y;

  if h < 4 then
    v := y
  else if (h = 12) or (h = 14) then
    v := x
  else
    v := 0;

  if (h and 1) = 0 then
    grad := u
  else
    grad := -u;

  if (h and 2) = 0 then
    grad := grad + v
  else
    grad := grad - v;
end;

end.
