{
  Graphics Primitives
  Part of Posit-92 game framework
}

unit Graphics;

{$Mode TP}
{$B-}  { Enable boolean short-circuiting }

interface

procedure circ(const cx, cy, radius: integer; const colour: longword);
procedure circfill(const cx, cy, radius: integer; const colour: longword);

procedure rect(x0, y0, x1, y1: integer; const colour: longword);
procedure rectfill(x0, y0, x1, y1: integer; const colour: longword);
procedure hline(x0, x1, y: integer; const colour: longword);
procedure vline(x, y0, y1: integer; const colour: longword);

procedure line(x0, y0, x1, y1: integer; const colour: longword);


implementation

uses VGA;

procedure circ(const cx, cy, radius: integer; const colour: longword);
var
  x, y, p: integer;
begin
  x := 0;
  y := radius;
  p := 3 - 2 * radius;

  while x <= y do begin
    pset(cx + x, cy + y, colour);
    pset(cx - x, cy + y, colour);
    pset(cx + x, cy - y, colour);
    pset(cx - x, cy - y, colour);
    pset(cx + y, cy + x, colour);
    pset(cx - y, cy + x, colour);
    pset(cx + y, cy - x, colour);
    pset(cx - y, cy - x, colour);

    if p < 0 then
      p := p+4 * x+6
    else begin
      p := p+4 * (x-y)+10;
      dec(y);
    end;
    inc(x);
  end;
end;

procedure circfill(const cx, cy, radius: integer; const colour: longword);
var
  x, y, p: integer;
  a: integer;
begin
  x := 0;
  y := radius;
  p := 3 - 2 * radius;

  while x <= y do begin
    for a:=cx-x to cx+x do begin
      pset(a, cy + y, colour);
      pset(a, cy - y, colour)
    end;
    for a:=cx-y to cx+y do begin
      pset(a, cy + x, colour);
      pset(a, cy - x, colour)
    end;

    if p < 0 then
      p := p+4 * x+6
    else begin
      p := p+4 * (x-y)+10;
      dec(y)
    end;

    inc(x)
  end;
end;

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

procedure rectfill(x0, y0, x1, y1: integer; const colour: longword);
var
  b, temp: integer;
begin
  if x0 > x1 then begin
    temp := x0; x0 := x1; x1 := temp
  end;
  if y0 > y1 then begin
    temp := y0; y0 := y1; y1 := temp
  end;
  for b:=y0 to y1 do
    hline(x0, x1, b, colour);
end;

procedure hline(x0, x1, y: integer; const colour: longword);
var
  x: integer;
begin
  if x1 < x0 then begin
    x := x0; x0 := x1; x1 := x
  end;

  for x := x0 to x1 do
    pset(x, y, colour);
end;

procedure vline(x, y0, y1: integer; const colour: longword);
var
  temp, a: integer;
begin
  if (x < 0) or (x >= vgaWidth) then exit;

  if y0 > y1 then begin
    temp := y0; y0 := y1; y1 := temp
  end;

  if (y0 >= vgaHeight) or (y1 < 0) then exit;

  for a:=y0 to y1 do begin
    if (a < 0) then continue;
    pset(x, a, colour)
  end;
end;

procedure line(x0, y0, x1, y1: integer; const colour: longword);
var
  dx, dy, sx, sy, err, e2: integer;
begin
  if x0 = x1 then begin
    vline(x0, y0, y1, colour);
    exit
  end;

  if y0 = y1 then begin
    hline(x0, x1, y0, colour);
    exit
  end;

  dx := abs(x1 - x0);
  dy := abs(y1 - y0);

  if x0 < x1 then sx := 1 else sx := -1;
  if y0 < y1 then sy := 1 else sy := -1;

  err := dx - dy;

  while (x0 <> x1) or (y0 <> y1) do begin
    pset(x0, y0, colour);
    e2 := 2 * err;

    if e2 > -dy then begin
      err := err - dy;
      x0 := x0 + sx;
    end;

    if e2 < dx then begin
      err := err + dx;
      y0 := y0 + sy;
    end;
  end;

  pset(x0, y0, colour)
end;

end.
