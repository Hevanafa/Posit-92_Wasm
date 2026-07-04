{
  Easings unit
  Part of Posit-92 game engine
  By Hevanafa

  Generic unit that contains easing functions
  All the time / tick units are in seconds
}

unit P92Easings;

{$Mode ObjFPC}
{$H+}{$J-}

interface

type
  { Stateless easing timer
    Requires a pair of start & end values }
  TEasingTimer = record
    startTick, endTick: double;
  end;

procedure InitEasing(var lt: TEasingTimer; const startTick, duration: double);

function NewEasingTimer(const startTick, duration: double): TEasingTimer;
function GetEasingPerc(const lt: TEasingTimer; const t: double): double;
function IsEasingComplete(const lt: TEasingTimer; const t: double): boolean;

{
  Base easing functions
  perc: 0.0 .. 1.0 (must be clamped manually)
}

function EaseInQuad(const perc: double): double;
function EaseOutQuad(const perc: double): double;
function EaseInOutQuad(const perc: double): double;

function EaseInSine(const perc: double): double;
function EaseOutSine(const perc: double): double;
function EaseInOutSine(const perc: double): double;

{
  Helper functions
  These call both:
  - Percentage normalisation
  - Performs interpolation using easing with the provided start & end values (a and z)
}

function LerpLinear(const a, z: double; perc: double): double;

function LerpEaseInQuad(const a, z, perc: double): double;
function LerpEaseOutQuad(const a, z, perc: double): double;
function LerpEaseInOutQuad(const a, z, perc: double): double;

function LerpEaseInSine(const a, z, perc: double): double;
function LerpEaseOutSine(const a, z, perc: double): double;
function LerpEaseInOutSine(const a, z, perc: double): double;


implementation

uses P92Maths, P92Timing;

procedure InitEasing(var lt: TEasingTimer; const startTick, duration: double);
begin
  lt.startTick := startTick;
  lt.endTick := startTick + duration;
end;

function NewEasingTimer(const startTick, duration: double): TEasingTimer;
begin
  NewEasingTimer.startTick := startTick;
  NewEasingTimer.endTick := startTick + duration;
end;

function GetEasingPerc(const lt: TEasingTimer; const t: double): double;
begin
  GetEasingPerc := clamp((t - lt.startTick) / (lt.endTick - lt.startTick), 0.0, 1.0)
end;

function IsEasingComplete(const lt: TEasingTimer; const t: double): boolean;
begin
  IsEasingComplete := t >= lt.endTick
end;


{ Begin easing functions }

function EaseInQuad(const perc: double): double;
begin
  EaseInQuad := perc * perc
end;

function EaseOutQuad(const perc: double): double;
begin
  EaseOutQuad := 1 - (1 - perc) * (1 - perc)
end;

function EaseInOutQuad(const perc: double): double;
var
  n: double;
begin
  if perc < 0.5 then
    EaseInOutQuad := 2 * perc * perc
  else begin
    n := -2 * perc + 2;
    EaseInOutQuad := 1 - n * n / 2;
  end;
end;

function EaseInSine(const perc: double): double;
begin
  EaseInSine := 1 - cos(perc * pi / 2.0)
end;

function EaseOutSine(const perc: double): double;
begin
  EaseOutSine := sin(perc * pi / 2.0)
end;

function EaseInOutSine(const perc: double): double;
begin
  EaseInOutSine := -(cos(pi * perc) - 1.0) / 2.0
end;


function LerpLinear(const a, z: double; perc: double): double;
begin
  perc := clamp(perc, 0.0, 1.0);
  LerpLinear := a + perc * (z - a)
end;

function LerpEaseInQuad(const a, z, perc: double): double;
begin
  LerpEaseInQuad := a + EaseInQuad(perc) * (z - a)
end;

function LerpEaseOutQuad(const a, z, perc: double): double;
begin
  LerpEaseOutQuad := a + EaseOutQuad(perc) * (z - a)
end;

function LerpEaseInOutQuad(const a, z, perc: double): double;
begin
  LerpEaseInOutQuad := a + EaseInOutQuad(perc) * (z - a)
end;


function LerpEaseInSine(const a, z, perc: double): double;
begin
  LerpEaseInSine := a + EaseInSine(perc) * (z - a)
end;

function LerpEaseOutSine(const a, z, perc: double): double;
begin
  LerpEaseOutSine := a + EaseOutSine(perc) * (z - a)
end;

function LerpEaseInOutSine(const a, z, perc: double): double;
begin
  LerpEaseInOutSine := a + EaseInOutSine(perc) * (z - a)
end;

end.
