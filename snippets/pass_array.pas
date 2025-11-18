{ 
  Open array demo
  By Hevanafa, 18-11-2025
}

{ Notice the index of the array
  Instead of 1 to 30, it's reindexed from 0 to 29
  Ref: https://www.freepascal.org/docs-html/ref/refsu68.html }
procedure printBounds(const ary: array of integer);
begin
  writeln('low:', low(ary), ', high:', high(ary));
end;

var
  a: integer;
  ary: array[1..30] of integer;
begin
  for a:=low(ary) to high(ary) do
    ary[a] := a;
  
  printBounds(ary)
end.