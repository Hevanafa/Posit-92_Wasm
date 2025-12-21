unit Shapes;

{$Mode TP}
{$B-}

interface

type
  PPoint = ^TPoint;
  TPoint = record
    x, y: double;
  end;

  TZone = record
    x, y: double;
    width, height: double;
  end;

  TPhysicsBody = record
    x, y: double;
    width, height: double;
    vx, vy: double;
  end;

  TCircle = record
    cx, cy, radius: double;
    vx, vy: double;
  end;

procedure drawZone(const zone: TZone; const colour: longword);
procedure drawPhysicsBody(const body: TPhysicsBody; const colour: longword);
procedure drawCircleZone(const zone: TCircle; const colour: longword);

function getDist(const a, b: TPoint): double;

function getZoneCX(const zone: TZone): double;
function getZoneCY(const zone: TZone): double;
function getZoneDist(const a, b: TZone): double;

function getPhysicsCPoint(const body: TPhysicsBody): TPoint;
function getPhysicsBodyCX(const body: TPhysicsBody): double;
function getPhysicsBodyCY(const body: TPhysicsBody): double;

function newPoint(const x, y: double): TPoint;
function newZone(const x, y, width, height: double): TZone;
function physicsBodyToZone(const body: TPhysicsBody): TZone;

function rectIntersects(const self, other: TZone): boolean;
function circleIntersects(const self, other: TCircle): boolean;
function circleRectIntersects(const circ: TCircle; const rect: TZone): boolean;
function pointInCircle(const p: TPoint; const circ: TCircle): boolean;
function pointInRect(const p: TPoint; const rect: TZone): boolean;


implementation

uses Maths, Graphics;

procedure drawZone(const zone: TZone; const colour: longword);
begin
  rect(trunc(zone.x), trunc(zone.y), trunc(zone.x + zone.width), trunc(zone.y + zone.height), colour)
end;

procedure drawPhysicsBody(const body: TPhysicsBody; const colour: longword);
begin
  rect(trunc(body.x), trunc(body.y), trunc(body.x + body.width), trunc(body.y + body.height), colour)
end;

procedure drawCircleZone(const zone: TCircle; const colour: longword);
begin
  circ(trunc(zone.cx), trunc(zone.cy), trunc(zone.radius), colour)
end;

function getDist(const a, b: TPoint): double;
var
  dx, dy: double;
begin
  dx := b.x - a.x;
  dy := b.y - a.y;
  getDist := dx * dx + dy * dy
end;

function getZoneCX(const zone: TZone): double;
begin
  getZoneCX := trunc(zone.x + zone.width / 2)
end;

function getZoneCY(const zone: TZone): double;
begin
  getZoneCY := trunc(zone.y + zone.height / 2)
end;

function getZoneDist(const a, b: TZone): double;
var
  x, y: double;
begin
  x := getZoneCX(b) - getZoneCX(a);
  y := getZoneCY(b) - getZoneCY(a);
  getZoneDist := x * x + y * y
end;


function getPhysicsCPoint(const body: TPhysicsBody): TPoint;
var
  result: TPoint;
begin
  result.x := getPhysicsBodyCX(body);
  result.y := getPhysicsBodyCY(body);
  getPhysicsCPoint := result
end;

function getPhysicsBodyCX(const body: TPhysicsBody): double;
begin
  getPhysicsBodyCX := trunc(body.x + body.width / 2)
end;

function getPhysicsBodyCY(const body: TPhysicsBody): double;
begin
  getPhysicsBodyCY := trunc(body.y + body.height / 2)
end;

function newPoint(const x, y: double): TPoint;
var
  result: TPoint;
begin
  result.x := x;
  result.y := y;
  newPoint := result
end;

function newZone(const x, y, width, height: double): TZone;
var
  result: TZone;
begin
  result.x := x;
  result.y := y;
  result.width := width;
  result.height := height;
  newZone := result
end;

function physicsBodyToZone(const body: TPhysicsBody): TZone;
var
  result: TZone;
begin
  result.x := body.x;
  result.y := body.y;
  result.width := body.width;
  result.height := body.height;

  physicsBodyToZone := result
end;

function rectIntersects(const self, other: TZone): boolean;
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
function circleRectIntersects(const circ: TCircle; const rect: TZone): boolean;
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

function pointInCircle(const p: TPoint; const circ: TCircle): boolean;
var
  dx, dy, dist: double;
begin
  dx := p.x - circ.cx;
  dy := p.y - circ.cy;
  dist := dx * dx + dy * dy;

  pointInCircle := dist < circ.radius * circ.radius
end;

function pointInRect(const p: TPoint; const rect: TZone): boolean;
begin
  pointInRect := (p.x >= rect.x)
    and (p.x < rect.x + rect.width)
    and (p.y >= rect.y)
    and (p.y < rect.y + rect.height)
end;


end.
