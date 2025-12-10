{
  Graphics Primitives
  Part of Posit-92 game framework
}

unit Graphics;

{$Mode TP}
{$PointerMath ON}
{$B-}  { Enable boolean short-circuiting }

interface

uses Shapes;

procedure circ(const cx, cy, radius: integer; const colour: longword);
procedure circfill(const cx, cy, radius: integer; const colour: longword);

procedure rect(x0, y0, x1, y1: integer; const colour: longword);
procedure rectfill(x0, y0, x1, y1: integer; const colour: longword);
procedure hline(x0, x1, y: integer; const colour: longword);
{ procedure hline2(x0, x1, y: integer; const colour: longword); }
procedure vline(x, y0, y1: integer; const colour: longword);
{ procedure vline2(x, y0, y1: integer; const colour: longword); }

procedure line(x0, y0, x1, y1: integer; const colour: longword);

procedure ellipse(const cx, cy, rx, ry: integer; const colour: longword);
procedure ellipsefill(const cx, cy, rx, ry: integer; const colour: longword);

procedure tri(x0, y0, x1, y1, x2, y2: integer; const colour: longword);
procedure trifill(x1, y1, x2, y2, x3, y3: integer; const colour: longword);

procedure polygon(points: array of TPoint; const colour: longword);
procedure polygonPtr(points: PPoint; const count: integer; const colour: longword);

procedure arc(
  const cx, cy, radius: integer;
  const startRad, endRad: double;
  const colour: longword);

procedure rectRound(x0, y0, x1, y1, radius: integer; const colour: longword);


implementation

uses VGA;

function getAlpha(const colour: longword): byte;
begin
  getAlpha := colour shr 24 and $FF
end;

function solidify(const colour: longword): longword;
begin
  if colour and $FF000000 > 0 then
    solidify := (colour or $FF000000)
  else
    solidify := colour
end;

procedure circ(const cx, cy, radius: integer; const colour: longword);
var
  x, y, p: integer;
  solid: longword;
begin
  if getAlpha(colour) = 0 then exit;

  x := 0;
  y := radius;
  p := 3 - 2 * radius;
  solid := solidify(colour);

  while x <= y do begin
    pset(cx + x, cy + y, solid);
    pset(cx - x, cy + y, solid);
    pset(cx + x, cy - y, solid);
    pset(cx - x, cy - y, solid);
    pset(cx + y, cy + x, solid);
    pset(cx - y, cy + x, solid);
    pset(cx + y, cy - x, solid);
    pset(cx - y, cy - x, solid);

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
  solid: longword;
begin
  if getAlpha(colour) = 0 then exit;

  x := 0;
  y := radius;
  p := 3 - 2 * radius;
  solid := solidify(colour);

  while x <= y do begin
    for a:=cx-x to cx+x do begin
      pset(a, cy + y, solid);
      pset(a, cy - y, solid)
    end;
    for a:=cx-y to cx+y do begin
      pset(a, cy + x, solid);
      pset(a, cy - x, solid)
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
  solid: longword;
begin
  if getAlpha(colour) = 0 then exit;
  solid := solidify(colour);

  if x0 > x1 then begin
    temp := x0; x0 := x1; x1 := temp
  end;
  if y0 > y1 then begin
    temp := y0; y0 := y1; y1 := temp
  end;
  for b:=y0 to y1 do begin
    pset(x0, b, solid);
    pset(x1, b, solid)
  end;
  for a:=x0 to x1 do begin
    pset(a, y0, solid);
    pset(a, y1, solid)
  end;
end;

procedure rectfill(x0, y0, x1, y1: integer; const colour: longword);
var
  b, temp: integer;
  solid: longword;
begin
  if getAlpha(colour) = 0 then exit;
  solid := solidify(colour);

  if x0 > x1 then begin
    temp := x0; x0 := x1; x1 := temp
  end;
  if y0 > y1 then begin
    temp := y0; y0 := y1; y1 := temp
  end;
  for b:=y0 to y1 do
    hline(x0, x1, b, solid);
end;

procedure legacyHline(x0, x1, y: integer; const colour: longword);
var
  x: integer;
  solid: longword;
begin
  if getAlpha(colour) = 0 then exit;
  solid := solidify(colour);

  if x1 < x0 then begin
    x := x0; x0 := x1; x1 := x
  end;

  for x := x0 to x1 do
    pset(x, y, solid);
end;

procedure hline(x0, x1, y: integer; const colour: longword);
var
  x: integer;
  solid: longword;
begin
  if getAlpha(colour) = 0 then exit;
  solid := solidify(colour);

  if (y < 0) or (y >= vgaHeight) then exit;

  if x1 < x0 then begin
    x := x0; x0 := x1; x1 := x
  end;

  if x0 < 0 then x0 := 0;
  if x1 >= vgaWidth then x1 := vgaWidth - 1;
  if x0 > x1 then exit;

  for x:=x0 to x1 do
    unsafePset(x, y, solid);
end;

procedure legacyVline(x, y0, y1: integer; const colour: longword);
var
  temp, a: integer;
  solid: longword;
begin
  if getAlpha(colour) = 0 then exit;
  if (x < 0) or (x >= vgaWidth) then exit;
  solid := solidify(colour);

  if y0 > y1 then begin
    temp := y0; y0 := y1; y1 := temp
  end;

  if (y0 >= vgaHeight) or (y1 < 0) then exit;

  for a:=y0 to y1 do begin
    if (a < 0) then continue;
    pset(x, a, solid)
  end;
end;

procedure vline(x, y0, y1: integer; const colour: longword);
var
  y, temp: integer;
  solid: longword;
begin
  if getAlpha(colour) = 0 then exit;
  if (x < 0) or (x >= vgaWidth) then exit;
  solid := solidify(colour);

  if y1 < y0 then begin
    temp := y0; y0 := y1; y1 := temp
  end;

  if y0 < 0 then y0 := 0;
  if y1 >= vgaHeight then y1 := vgaHeight - 1;
  if y0 > y1 then exit;

  for y:=y0 to y1 do
    unsafePset(x, y, solid);
end;


procedure line(x0, y0, x1, y1: integer; const colour: longword);
var
  dx, dy, sx, sy, err, e2: integer;
  solid: longword;
begin
  if getAlpha(colour) = 0 then exit;
  solid := solidify(colour);

  if x0 = x1 then begin
    vline(x0, y0, y1, solid);
    exit
  end;

  if y0 = y1 then begin
    hline(x0, x1, y0, solid);
    exit
  end;

  dx := abs(x1 - x0);
  dy := abs(y1 - y0);

  if x0 < x1 then sx := 1 else sx := -1;
  if y0 < y1 then sy := 1 else sy := -1;

  err := dx - dy;

  while (x0 <> x1) or (y0 <> y1) do begin
    pset(x0, y0, solid);
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

  pset(x0, y0, solid)
end;


procedure ellipse(const cx, cy, rx, ry: integer; const colour: longword);
var
  x, y: integer;
  rx2, ry2, tworx2, twory2: integer;
  p: integer;
  solid: longword;
begin
  if getAlpha(colour) = 0 then exit;
  solid := solidify(colour);

  x := 0; y := ry;
  rx2 := rx * rx;
  ry2 := ry * ry;
  tworx2 := 2 * rx2;
  twory2 := 2 * ry2;

  { Handle slope < -1 }
  p := round(ry2 - (rx2 * ry) + (rx2 / 4));
  
  while (twory2 * x) <= (tworx2 * y) do begin
    pset(cx + x, cy + y, solid);
    pset(cx - x, cy + y, solid);
    pset(cx + x, cy - y, solid);
    pset(cx - x, cy - y, solid);

    if p < 0 then
      p := p + twory2 * x + ry2
    else begin
      p := p + twory2 * x - tworx2 * y + ry2;
      dec(y)
    end;

    inc(x)
  end;

  { Handle slope >= -1}
  p := round(
    ry2 * (x + 0.5) * (x + 0.5)
    + rx2 * (y - 1) * (y - 1)
    - rx2 * ry2);

  while y >= 0 do begin
    pset(cx + x, cy + y, solid);
    pset(cx - x, cy + y, solid);
    pset(cx + x, cy - y, solid);
    pset(cx - x, cy - y, solid);

    if p > 0 then
      p := p - tworx2 * y + rx2
    else begin
      p := p + twory2 * x - tworx2 * y + rx2;
      inc(x)
    end;

    dec(y)
  end;
end;


procedure ellipsefill(const cx, cy, rx, ry: integer; const colour: longword);
var
  x, y: integer;
  rx2, ry2, tworx2, twory2: integer;
  p: integer;
  solid: longword;
begin
  if getAlpha(colour) = 0 then exit;
  solid := solidify(colour);

  x := 0; y := ry;
  rx2 := rx * rx;
  ry2 := ry * ry;
  tworx2 := 2 * rx2;
  twory2 := 2 * ry2;

  { Handle slope < -1 }
  p := round(ry2 - (rx2 * ry) + (rx2 / 4));
  
  while (twory2 * x) <= (tworx2 * y) do begin
    hline(cx - x, cx + x, cy + y, solid);
    hline(cx - x, cx + x, cy - y, solid);

    if p < 0 then
      p := p + twory2 * x + ry2
    else begin
      p := p + twory2 * x - tworx2 * y + ry2;
      dec(y)
    end;

    inc(x)
  end;

  { Handle slope >= -1}
  p := round(
    ry2 * (x + 0.5) * (x + 0.5)
    + rx2 * (y - 1) * (y - 1)
    - rx2 * ry2);

  while y >= 0 do begin
    hline(cx - x, cx + x, cy + y, solid);
    hline(cx - x, cx + x, cy - y, solid);

    if p > 0 then
      p := p - tworx2 * y + rx2
    else begin
      p := p + twory2 * x - tworx2 * y + rx2;
      inc(x)
    end;

    dec(y)
  end;
end;

procedure tri(x0, y0, x1, y1, x2, y2: integer; const colour: longword);
var
  solid: longword;
begin
  if getAlpha(colour) = 0 then exit;
  solid := solidify(colour);

  line(x0, y0, x1, y1, solid);
  line(x1, y1, x2, y2, solid);
  line(x0, y0, x2, y2, solid)
end;

procedure trifill(x1, y1, x2, y2, x3, y3: integer; const colour: longword);
var
  temp, minY, maxY, y: integer;
  xa, xb: single;
  dxa, dxb: single;
  solid: longword;
begin
  if getAlpha(colour) = 0 then exit;
  solid := solidify(colour);

  { Handle bubble sort }
  if y1 > y2 then begin
    temp := y1; y1 := y2; y2 := temp;
    temp := x1; x1 := x2; x2 := temp;
  end;
  if y2 > y3 then begin
    temp := y2; y2 := y3; y3 := temp;
    temp := x2; x2 := x3; x3 := temp;
  end;
  if y1 > y2 then begin
    temp := y1; y1 := y2; y2 := temp;
    temp := x1; x1 := x2; x2 := temp;
  end;

  MinY := y1; maxY := y3;

  { Handle flat triangle / degenerate }
  if minY = maxY then exit;

  { Draw top half }
  if y2 > y1 then begin
    xa:=x1; xb:=x1;
    dxa := (x3 - x1) / (y3 - y1);  { long edge }
    dxb := (x2 - x1) / (y2 - y1);  { short edge }

    for y:=y1 to y2 - 1 do begin
      hline(round(xa), round(xb), y, solid);
      xa := xa + dxa;
      xb := xb + dxb
    end;
  end;

  { Draw bottom half }
  if y3 > y2 then begin
    { Continue long edge }
    xa := x1 + (x3 - x1) * ((y2 - y1) / (y3 - y1));
    xb := x2;
    dxa := (x3 - x1) / (y3 - y1);
    dxb := (x3 - x2) / (y3 - y2);

    for y:=y2 to y3 do begin
      hline(round(xa), round(xb), y, solid);
      xa := xa + dxa;
      xb := xb + dxb
    end;
  end;
end;


procedure polygon(points: array of TPoint; const colour: longword);
var
  a, last: integer;
  solid: longword;
begin
  if getAlpha(colour) = 0 then exit;
  solid := solidify(colour);

  { Skip if it doesn't form at least a line }
  if length(points) < 2 then exit;

  last := high(points);
  for a:=0 to last - 1 do
    line(round(points[a].x), round(points[a].y),
      round(points[a + 1].x), round(points[a + 1].y), solid);

  line(round(points[last].x), round(points[last].y),
    round(points[0].x), round(points[0].y), solid);
end;

procedure polygonPtr(points: PPoint; const count: integer; const colour: longword);
var
  a: integer;
  solid: longword;
  p: PPoint;
begin
  if getAlpha(colour) = 0 then exit;
  solid := solidify(colour);

  { Skip if it doesn't form at least a line }
  if count < 2 then exit;

  p := points;
  for a:=0 to count - 2 do begin
    line(round(p^.x), round(p^.y),
      round((p + 1)^.x), round((p + 1)^.y), solid);
    inc(p)
  end;

  { Close the polygon }
  line(round(p^.x), round(p^.y),
    round(points^.x), round(points^.y), solid);
end;


procedure arc(
  const cx, cy, radius: integer;
  const startRad, endRad: double;
  const colour: longword);
var
  angle, step: double;
  x, y, prevX, prevY: integer;
  first: boolean;
  solid: longword;
begin
  if getAlpha(colour) = 0 then exit;
  solid := solidify(colour);

  if radius <= 0 then exit;

  { Draw the arc }
  step := 1.0 / radius;
  if step > 0.1 then step := 0.1;

  angle := startRad;
  prevX := x; prevY := y;
  first := true;
  
  while angle <= endRad do begin
    x := cx + round(cos(angle) * radius);
    y := cy + round(sin(angle) * radius);

    if not first then
      line(prevX, prevY, x, y, solid)
    else
      first := false;

    prevX := x; prevY := y;
    angle := angle + step
  end;

  { Draw final segment }
  x := cx + round(cos(endRad) * radius);
  y := cy + round(sin(endRad) * radius);

  if not first then
    line(prevX, prevY, x, y, solid);
end;


procedure rectRound(x0, y0, x1, y1, radius: integer; const colour: longword);
var
  temp, maxRadius: integer;
  solid: longword;
begin
  if getAlpha(colour) = 0 then exit;
  solid := solidify(colour);

  { Sort coordinates }
  if x1 < x0 then begin
    temp := x0; x0 := x1; x1 := temp
  end;
  if y1 < y0 then begin
    temp := y0; y0 := y1; y1 := temp
  end;

  { Clamp radius }
  maxRadius := (x1 - x0) div 2;
  if (y1 - y0) div 2 < maxRadius then
    maxRadius := (y1 = y0) div 2;

  if radius > maxRadius then radius := maxRadius;
  if radius < 0 then radius := 0;

  if radius = 0 then begin
    rect(x0, y0, x1, y1, colour);
    exit
  end;

  { TODO: Handle edges }
  { TODO: Handle corners}
end;


end.
