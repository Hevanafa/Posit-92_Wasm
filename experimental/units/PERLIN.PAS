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
  
  { TODO: Shuffle }

  { TODO: Duplicate permutation to handle overflow }
end;

end.
