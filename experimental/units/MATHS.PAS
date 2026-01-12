{
  Maths unit - Part of Posit-92 game engine
  Hevanafa
}

unit Maths;

{$Mode TP}
{$B-}

interface

function clamp(const value, min, max: double): double;
function min(const a, b: double): double;
function max(const a, b: double): double;
function deg2rad(const deg: double): double;
function rad2deg(const rad: double): double;
function i32power(const i, exp: longint): longint;
function f32power(const i: double; exp: integer): double;
function floor(const value: double): integer;
function ceil(const value: double): integer;
function ArcTan2(const y, x: double): double;


implementation

uses Panic;

function clamp(const value, min, max: double): double;
begin
  if value < min then
    clamp := min
  else if value > max then
    clamp := max
  else
    clamp := value;
end;

function min(const a, b: double): double;
begin
  min := 0.0;
  if a<=b then min:=a
  else if a>b then min:=b
end;

function max(const a, b: double): double;
begin
  max := 0.0;
  if a<b then max:=b
  else if a>=b then max:=a
end;

function deg2rad(const deg: double): double;
begin
  deg2rad := deg / 180 * pi
end;

function rad2deg(const rad: double): double;
begin
  rad2deg := rad * 180 / pi
end;

function i32power(const i, exp: longint): longint;
var
  a, result: longint;
begin
  if exp < 0 then panicHalt('i32power: Negative exp isn''t supported!');
  if exp = 0 then begin i32power := 1; exit end;
  if exp = 1 then begin i32power := i; exit end;

  result := i;
  for a := 2 to exp do
    result := result * i;
  i32power := result
end;

function f32power(const i: double; exp: integer): double;
var
  a: integer;
  result: double;
begin
  if exp < 0 then panicHalt('f32power: Negative exp isn''t supported!');
  if exp = 0 then begin f32power := 1; exit end;
  if exp = 1 then begin f32power := i; exit end;

  result := i;
  for a := 2 to exp do
    result := result * i;
  f32power := result
end;

function floor(const value: double): integer;
begin
  floor := trunc(value)
end;

function ceil(const value: double): integer;
begin
  if trunc(value) = value then
    ceil := trunc(value)
  else
    ceil := trunc(value + 1);
end;

{ Ref: https://en.wikipedia.org/wiki/Atan2#Definition_and_computation }
function ArcTan2(const y, x: double): double;
begin
  if x > 0 then
    ArcTan2 := arctan(y / x)
  else if (x < 0) and (y >= 0) then
    ArcTan2 := arctan(y / x) + pi
  else if (x < 0) and (y < 0) then
    ArcTan2 := arctan(y / x) - pi
  else if (x = 0) and (y > 0) then
    ArcTan2 := pi / 2
  else if (x = 0) and (y < 0) then
    ArcTan2 := -pi / 2
  else { if (x = 0) and (y = 0) then }
    ArcTan2 := 0;  { undefined }
end;

end.
