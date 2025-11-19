unit Shapes;

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

procedure drawZone(const zone: TRect; const colour: byte);
function getZoneCX(const zone: TRect): double;
function getZoneCY(const zone: TRect): double;
function rectIntersects(const self, other: TRect): boolean;


implementation

uses Graphics;

procedure drawZone(const zone: TRect; const colour: byte);
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

function rectIntersects(const self, other: TRect): boolean;
begin
  rectIntersects := (other.x < self.x + self.width) and
    (self.x < other.x + other.width) and
    (other.y < self.y + self.height) and
    (self.y < other.y + other.height)
end;

end.
