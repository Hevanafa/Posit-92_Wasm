unit Shapes;

{$Mode TP}
{$B-}

interface

type
  TPoint = record
    x, y: double;
  end;

  TRect = record
    x, y: double;
    width, height: double;
    vx, vy: double;
  end;

  TCircle = record
    cx, cy, radius: double;
    vx, vy: double;
  end;

procedure drawZone(const zone: TRect; const colour: longword);
procedure drawCircleZone(const zone: TCircle; const colour: longword);

function getZoneCX(const zone: TRect): double;
function getZoneCY(const zone: TRect): double;
function getZoneDist(const a, b: TRect): double;

function newPoint(const x, y: double): TPoint;
function newRect(const x, y, width, height: double): TRect;

function rectIntersects(const self, other: TRect): boolean;
function circleIntersects(const self, other: TCircle): boolean;
function circleRectIntersects(const circ: TCircle; const rect: TRect): boolean;
function pointCircleIntersects(const p: TPoint; const circ: TCircle): boolean;
function pointRectIntersects(const p: TPoint; const rect: TRect): boolean;

implementation

uses Maths, Graphics;

procedure drawZone(const zone: TRect; const colour: longword);
begin
  rect(trunc(zone.x), trunc(zone.y), trunc(zone.x + zone.width), trunc(zone.y + zone.height), colour)
end;

procedure drawCircleZone(const zone: TCircle; const colour: longword);
begin
  circ(trunc(zone.cx), trunc(zone.cy), trunc(zone.radius), colour)
end;

function getZoneCX(const zone: TRect): double;
begin
  getZoneCX := trunc(zone.x + zone.width / 2)
end;

function getZoneCY(const zone: TRect): double;
begin
  getZoneCY := trunc(zone.y + zone.height / 2)
end;

function getZoneDist(const a, b: TRect): double;
var
  x, y: double;
begin
  x := getZoneCX(b) - getZoneCX(a);
  y := getZoneCY(b) - getZoneCY(a);
  getZoneDist := x * x + y * y
end;

function newPoint(const x, y: double): TPoint;
var
  result: TPoint;
begin
  result.x := x;
  result.y := y;
  newPoint := result
end;

function newRect(const x, y, width, height: double): TRect;
var
  result: TRect;
begin
  result.x := x;
  result.y := y;
  result.width := width;
  result.height := height;
  newRect := result
end;

function rectIntersects(const self, other: TRect): boolean;
begin
  rectIntersects := (other.x < self.x + self.width)
    and (self.x < other.x + other.width)
    and (other.y < self.y + self.height)
    and (self.y < other.y + other.height)
end;

{ Distance isn't square rooted }
function circleIntersects(const self, other: TCircle): boolean;
var
  dx, dy, dist, radiusSum: double;
begin
  dx := other.cx - self.cx;
  dy := other.cy - self.cy;

  radiusSum := self.radius + other.radius;

  dist := dx * dx + dy * dy;
  circleIntersects := dist < radiusSum * radiusSum
end;

{ Distance isn't square rooted }
function circleRectIntersects(const circ: TCircle; const rect: TRect): boolean;
var
  closestX, closestY: double;
  dx, dy, dist: double;
begin
  closestX := clamp(circ.cx, rect.x, rect.x + rect.width);
  closestY := clamp(circ.cy, rect.y, rect.y + rect.height);

  dx := circ.cx - closestX;
  dy := circ.cy - closestY;
  dist := dx * dx + dy * dy;

  circleRectIntersects := dist < circ.radius * circ.radius
end;

function pointCircleIntersects(const p: TPoint; const circ: TCircle): boolean;
var
  dx, dy, dist: double;
begin
  dx := p.x - circ.cx;
  dy := p.y - circ.cy;
  dist := dx * dx + dy * dy;

  pointCircleIntersects := dist < circ.radius * circ.radius
end;

function pointRectIntersects(const p: TPoint; const rect: TRect): boolean;
begin
  pointRectIntersects := (p.x >= rect.x)
    and (p.x < rect.x + rect.width)
    and (p.y >= rect.y)
    and (p.y < rect.y + rect.height)
end;


end.
