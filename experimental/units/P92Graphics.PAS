{
  Graphics Primitives - Part of Posit-92 game engine
  Hevanafa
}

unit P92Graphics;

{$Mode ObjFPC}
{$H+}{$J-}
{$PointerMath ON}

interface

uses P92Geometry;

function GetAlpha(const colour: longword): byte;
{ Raises the alpha to $FF or leaves it at $00 }
function SolidColour(const colour: longword): longword;

procedure Circ(const cx, cy, radius: smallint; const colour: longword);
procedure CircFill(const cx, cy, radius: smallint; const colour: longword);

procedure Rect(x0, y0, x1, y1: smallint; const colour: longword);
procedure RectFill(x0, y0, x1, y1: smallint; const colour: longword);
procedure HLine(x0, x1, y: smallint; const colour: longword);
{ procedure hline2(x0, x1, y: smallint; const colour: longword); }
procedure VLine(x, y0, y1: smallint; const colour: longword);
{ procedure vline2(x, y0, y1: smallint; const colour: longword); }

procedure Line(x0, y0, x1, y1: smallint; const colour: longword);
procedure LineThick(x0, y0, x1, y1, thickness: smallint; const colour: longword);

procedure Ellipse(const cx, cy, rx, ry: smallint; const colour: longword);
procedure Ellipsefill(const cx, cy, rx, ry: smallint; const colour: longword);

procedure Tri(x0, y0, x1, y1, x2, y2: smallint; const colour: longword);
procedure TriFill(x1, y1, x2, y2, x3, y3: smallint; const colour: longword);

procedure Polygon(points: array of TPoint; const colour: longword);
procedure PolygonPtr(points: PPoint; const count: smallint; const colour: longword);

procedure Arc(
  const cx, cy, radius: smallint;
  const startRad, endRad: double;
  const colour: longword);
procedure Pie(
  const cx, cy, radius: smallint;
  const startRad, endRad: double;
  const colour: longword);

procedure RectRound(x0, y0, x1, y1, radius: smallint; const colour: longword);


implementation

uses P92VGA;

function GetAlpha(const colour: longword): byte;
begin
  GetAlpha := colour shr 24 and $FF
end;

function SolidColour(const colour: longword): longword;
begin
  if colour and $FF000000 > 0 then
    SolidColour := (colour or $FF000000)
  else
    SolidColour := colour
end;

procedure Circ(const cx, cy, radius: smallint; const colour: longword);
var
  x, y, p: smallint;
  solid: longword;
begin
  if GetAlpha(colour) = 0 then exit;

  x := 0;
  y := radius;
  p := 3 - 2 * radius;
  solid := SolidColour(colour);

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

procedure CircFill(const cx, cy, radius: smallint; const colour: longword);
var
  x, y, p: smallint;
  a: smallint;
  solid: longword;
begin
  if GetAlpha(colour) = 0 then exit;

  x := 0;
  y := radius;
  p := 3 - 2 * radius;
  solid := SolidColour(colour);

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

procedure Rect(x0, y0, x1, y1: smallint; const colour: longword);
var
  a, b, temp: smallint;
  solid: longword;
begin
  if GetAlpha(colour) = 0 then exit;
  solid := SolidColour(colour);

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

procedure RectFill(x0, y0, x1, y1: smallint; const colour: longword);
var
  b, temp: smallint;
  solid: longword;
begin
  if GetAlpha(colour) = 0 then exit;
  solid := SolidColour(colour);

  if x0 > x1 then begin
    temp := x0; x0 := x1; x1 := temp
  end;
  if y0 > y1 then begin
    temp := y0; y0 := y1; y1 := temp
  end;
  for b:=y0 to y1 do
    HLine(x0, x1, b, solid);
end;

procedure LegacyHLine(x0, x1, y: smallint; const colour: longword);
var
  x: smallint;
  solid: longword;
begin
  if GetAlpha(colour) = 0 then exit;
  solid := SolidColour(colour);

  if x1 < x0 then begin
    x := x0; x0 := x1; x1 := x
  end;

  for x := x0 to x1 do
    pset(x, y, solid);
end;

procedure HLine(x0, x1, y: smallint; const colour: longword);
var
  x: smallint;
  solid: longword;
begin
  if GetAlpha(colour) = 0 then exit;
  solid := SolidColour(colour);

  if (y < clipY1) or (y > clipY2) then exit;

  if x1 < x0 then begin
    x := x0; x0 := x1; x1 := x
  end;

  if x0 < clipX1 then x0 := clipX1;
  if x1 > clipX2 then x1 := clipX2;

  for x:=x0 to x1 do
    unsafePset(x, y, solid);
end;

procedure LegacyVLine(x, y0, y1: smallint; const colour: longword);
var
  temp, a: smallint;
  solid: longword;
begin
  if GetAlpha(colour) = 0 then exit;
  if (x < 0) or (x >= vgaWidth) then exit;
  solid := SolidColour(colour);

  if y0 > y1 then begin
    temp := y0; y0 := y1; y1 := temp
  end;

  if (y0 >= vgaHeight) or (y1 < 0) then exit;

  for a:=y0 to y1 do begin
    if (a < 0) then continue;
    pset(x, a, solid)
  end;
end;

procedure VLine(x, y0, y1: smallint; const colour: longword);
var
  y, temp: smallint;
  solid: longword;
begin
  if GetAlpha(colour) = 0 then exit;
  if (x < clipX1) or (x > clipX2) then exit;

  solid := SolidColour(colour);

  if y1 < y0 then begin
    temp := y0; y0 := y1; y1 := temp
  end;

  if y0 < clipY1 then y0 := clipY1;
  if y1 > clipY2 then y1 := clipY2;
  if y0 > y1 then exit;

  for y:=y0 to y1 do
    unsafePset(x, y, solid);
end;


procedure Line(x0, y0, x1, y1: smallint; const colour: longword);
var
  dx, dy, sx, sy, err, e2: smallint;
  solid: longword;
begin
  if GetAlpha(colour) = 0 then exit;
  solid := SolidColour(colour);

  if x0 = x1 then begin
    VLine(x0, y0, y1, solid);
    exit
  end;

  if y0 = y1 then begin
    HLine(x0, x1, y0, solid);
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

procedure LineThick(x0, y0, x1, y1, thickness: smallint; const colour: longword);
var
  dx, dy, len: double;
  perpX, perpY: double;  { perpendicular }
  offset: double;
  a, halfThick: smallint;
  solid: longword;
begin
  if GetAlpha(colour) = 0 then exit;
  solid := SolidColour(colour);

  if thickness <= 0 then exit;
  if thickness = 1 then begin
    Line(x0, y0, x1, y1, solid);
    exit
  end;

  { Calculate direction vector }
  dx := x1 - x0;
  dy := y1 - y0;
  len := sqrt(dx * dx + dy * dy);  { Line length }

  if len = 0 then exit;

  { Render logic }
  perpX := -dy / len;
  perpY := dx / len;
  halfThick := thickness div 2;

  for a:=-halfThick to halfThick do begin
    if ((thickness and 1) = 0) and (a = 0) then continue;

    offset := a;
    if ((thickness and 1) = 0) and (a > 0) then offset := a - 0.5;
    if ((thickness and 1) = 0) and (a < 0) then offset := a + 0.5;

    Line(
      round(x0 + perpX * offset),
      round(y0 + perpY * offset),
      round(x1 + perpX * offset),
      round(y1 + perpY * offset),
      solid)
  end;
end;


procedure Ellipse(const cx, cy, rx, ry: smallint; const colour: longword);
var
  x, y: smallint;
  rx2, ry2, tworx2, twory2: smallint;
  p: smallint;
  solid: longword;
begin
  if GetAlpha(colour) = 0 then exit;
  solid := SolidColour(colour);

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


procedure Ellipsefill(const cx, cy, rx, ry: smallint; const colour: longword);
var
  x, y: smallint;
  rx2, ry2, tworx2, twory2: smallint;
  p: smallint;
  solid: longword;
begin
  if GetAlpha(colour) = 0 then exit;
  solid := SolidColour(colour);

  x := 0; y := ry;
  rx2 := rx * rx;
  ry2 := ry * ry;
  tworx2 := 2 * rx2;
  twory2 := 2 * ry2;

  { Handle slope < -1 }
  p := round(ry2 - (rx2 * ry) + (rx2 / 4));
  
  while (twory2 * x) <= (tworx2 * y) do begin
    HLine(cx - x, cx + x, cy + y, solid);
    HLine(cx - x, cx + x, cy - y, solid);

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
    HLine(cx - x, cx + x, cy + y, solid);
    HLine(cx - x, cx + x, cy - y, solid);

    if p > 0 then
      p := p - tworx2 * y + rx2
    else begin
      p := p + twory2 * x - tworx2 * y + rx2;
      inc(x)
    end;

    dec(y)
  end;
end;

procedure Tri(x0, y0, x1, y1, x2, y2: smallint; const colour: longword);
var
  solid: longword;
begin
  if GetAlpha(colour) = 0 then exit;
  solid := SolidColour(colour);

  Line(x0, y0, x1, y1, solid);
  Line(x1, y1, x2, y2, solid);
  Line(x0, y0, x2, y2, solid)
end;

procedure TriFill(x1, y1, x2, y2, x3, y3: smallint; const colour: longword);
var
  temp, minY, maxY, y: smallint;
  xa, xb: single;
  dxa, dxb: single;
  solid: longword;
begin
  if GetAlpha(colour) = 0 then exit;
  solid := SolidColour(colour);

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
      HLine(round(xa), round(xb), y, solid);
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
      HLine(round(xa), round(xb), y, solid);
      xa := xa + dxa;
      xb := xb + dxb
    end;
  end;
end;


procedure Polygon(points: array of TPoint; const colour: longword);
var
  a, last: smallint;
  solid: longword;
begin
  if GetAlpha(colour) = 0 then exit;
  solid := SolidColour(colour);

  { Skip if it doesn't form at least a line }
  if length(points) < 2 then exit;

  last := high(points);
  for a:=0 to last - 1 do
    Line(round(points[a].x), round(points[a].y),
      round(points[a + 1].x), round(points[a + 1].y), solid);

  Line(round(points[last].x), round(points[last].y),
    round(points[0].x), round(points[0].y), solid);
end;

procedure PolygonPtr(points: PPoint; const count: smallint; const colour: longword);
var
  a: smallint;
  solid: longword;
  p: PPoint;
begin
  if GetAlpha(colour) = 0 then exit;
  solid := SolidColour(colour);

  { Skip if it doesn't form at least a line }
  if count < 2 then exit;

  p := points;
  for a:=0 to count - 2 do begin
    line(round(p^.x), round(p^.y),
      round((p + 1)^.x), round((p + 1)^.y), solid);
    inc(p)
  end;

  { Close the Polygon }
  Line(round(p^.x), round(p^.y),
    round(points^.x), round(points^.y), solid);
end;


procedure Arc(
  const cx, cy, radius: smallint;
  const startRad, endRad: double;
  const colour: longword);
var
  angle, step: double;
  x, y, prevX, prevY: smallint;
  first: boolean;
  solid: longword;
begin
  if GetAlpha(colour) = 0 then exit;
  solid := SolidColour(colour);

  if radius <= 0 then exit;

  { Draw the Arc }
  step := 1.0 / radius;
  if step > 0.1 then step := 0.1;

  angle := startRad;
  first := true;
  { Initialise anyway }
  x := 0; y := 0;
  prevX := x; prevY := y;
  
  while angle <= endRad do begin
    x := cx + round(cos(angle) * radius);
    y := cy + round(sin(angle) * radius);

    if not first then
      Line(prevX, prevY, x, y, solid)
    else
      first := false;

    prevX := x; prevY := y;
    angle := angle + step
  end;

  { Draw final segment }
  x := cx + round(cos(endRad) * radius);
  y := cy + round(sin(endRad) * radius);

  if not first then
    Line(prevX, prevY, x, y, solid);
end;

procedure Pie(
  const cx, cy, radius: smallint;
  const startRad, endRad: double;
  const colour: longword);
var
  angle, step: double;
  x, y, prevX, prevY: smallint;
  first: boolean;
  solid: longword;
begin
  if GetAlpha(colour) = 0 then exit;
  solid := SolidColour(colour);

  if radius <= 0 then exit;

  { Draw the Arc }
  step := 1.0 / radius;
  if step > 0.1 then step := 0.1;

  angle := startRad;
  first := true;
  { Initialise anyway }
  x := 0; y := 0;
  prevX := x; prevY := y;
  
  while angle <= endRad do begin
    x := cx + round(cos(angle) * radius);
    y := cy + round(sin(angle) * radius);

    if not first then
      TriFill(cx, cy, prevX, prevY, x, y, solid)
    else
      first := false;

    prevX := x; prevY := y;
    angle := angle + step
  end;

  { Draw final segment }
  x := cx + round(cos(endRad) * radius);
  y := cy + round(sin(endRad) * radius);

  if not first then
    TriFill(cx, cy, prevX, prevY, x, y, solid);
end;


procedure RectRound(x0, y0, x1, y1, radius: smallint; const colour: longword);
var
  temp, maxRadius: smallint;
  solid: longword;
begin
  if GetAlpha(colour) = 0 then exit;
  solid := SolidColour(colour);

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
    maxRadius := (y1 - y0) div 2;

  if radius > maxRadius then radius := maxRadius;
  if radius < 0 then radius := 0;

  if radius = 0 then begin
    Rect(x0, y0, x1, y1, colour);
    exit
  end;

  { Handle edges }
  HLine(x0 + radius, x1 - radius, y0, solid);
  HLine(x0 + radius, x1 - radius, y1, solid);

  VLine(x0, y0 + radius, y1 - radius, solid);
  VLine(x1, y0 + radius, y1 - radius, solid);

  { Handle corners }
  Arc(x0 + radius, y0 + radius, radius, pi, 3 / 2 * pi, solid);
  Arc(x1 - radius, y0 + radius, radius, 3 / 2 * pi, 2 * pi, solid);
  Arc(x0 + radius, y1 - radius, radius, pi / 2, pi, solid);
  Arc(x1 - radius, y1 - radius, radius, 0, pi / 2, solid);
end;


end.
