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
function getZoneCX(const zone: TRect): double;
function getZoneCY(const zone: TRect): double;
function getZoneDist(const a, b: TRect): double;

function newPoint(const x, y: double): TPoint;
function newRect(const x, y, width, height: double): TRect;

function rectIntersects(const self, other: TRect): boolean;


implementation

uses Graphics;

procedure drawZone(const zone: TRect; const colour: longword);
begin
  rect(trunc(zone.x), trunc(zone.y), trunc(zone.x + zone.width), trunc(zone.y + zone.height), colour)
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

end.
