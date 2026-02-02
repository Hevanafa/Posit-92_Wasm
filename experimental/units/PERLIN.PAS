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

end.
