{
  Graphics Primitives
  Part of Posit-92 game framework
}

unit Graphics;

interface

{
procedure circ(const cx, cy, radius: integer; const colour: byte);
procedure circfill(const cx, cy, radius: integer; const colour: byte);
}

procedure rect(x0, y0, x1, y1: integer; const colour: longword); public name 'rect';

{ procedure rectfill(const x0, y0, x1, y1: integer; const colour: byte); }
{
procedure hline(const x0, x1, y: integer; const colour: byte);
procedure vline(const x, y0, y1: integer; const colour: byte);
procedure line(const x0, y0, x1, y1: integer; const colour: byte);
}


implementation

uses VGA;

procedure rect(x0, y0, x1, y1: integer; const colour: longword);
var
  a, b, temp: integer;
begin
  if x0 > x1 then begin
    temp := x0; x0 := x1; x1 := temp
  end;
  if y0 > y1 then begin
    temp := y0; y0 := y1; y1 := temp
  end;
  for b:=y0 to y1 do begin
    pset(x0, b, colour);
    pset(x1, b, colour)
  end;
  for a:=x0 to x1 do begin
    pset(a, y0, colour);
    pset(a, y1, colour)
  end;
end;

end.
