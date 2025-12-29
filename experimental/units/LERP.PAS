{
  Lerp unit - Part of Posit-92 game engine
  Hevanafa

  Generic unit that contains easing functions
  All the time / tick units are in seconds
}

unit Lerp;

{$Mode TP}

interface

type
  { Stateless lerp timer
    Requires a pair of start & end values }
  TLerpTimer = record
    startTick, endTick: double;
  end;

procedure initLerp(var lt: TLerpTimer; const startTick, duration: double);
function newLerp(const startTick, duration: double): TLerpTimer;
function getLerpPerc(const lt: TLerpTimer; const t: double): double;
function isLerpComplete(const lt: TLerpTimer; const t: double): boolean;

function lerpLinear(const a, z: double; perc: double): double;

function lerpEaseInQuad(const a, z, perc: double): double;
function lerpEaseOutQuad(const a, z, perc: double): double;
function lerpEaseInOutQuad(const a, z, perc: double): double;

function lerpEaseInSine(const a, z, perc: double): double;
function lerpEaseOutSine(const a, z, perc: double): double;
function lerpEaseInOutSine(const a, z, perc: double): double;


implementation

uses Maths, Timing;

procedure initLerp(var lt: TLerpTimer; const startTick, duration: double);
begin
  lt.startTick := startTick;
  lt.endTick := startTick + duration;
end;

function newLerp(const startTick, duration: double): TLerpTimer;
var
  result: TLerpTimer;
begin
  result.startTick := startTick;
  result.endTick := startTick + duration;

  newLerp := result
end;

function getLerpPerc(const lt: TLerpTimer; const t: double): double;
begin
  getLerpPerc := clamp((t - lt.startTick) / (lt.endTick - lt.startTick), 0.0, 1.0)
end;

function isLerpComplete(const lt: TLerpTimer; const t: double): boolean;
begin
  isLerpComplete := t >= lt.endTick
end;


{ Begin easing functions }

function easeInQuad(const perc: double): double;
begin
  easeInQuad := perc * perc
end;

function easeOutQuad(const perc: double): double;
begin
  easeOutQuad := 1 - (1 - perc) * (1 - perc)
end;

function easeInOutQuad(const perc: double): double;
var
  n: double;
begin
  if perc < 0.5 then
    easeInOutQuad := 2 * perc * perc
  else begin
    n := -2 * perc + 2;
    easeInOutQuad := 1 - n * n / 2;
  end;
end;

function easeInSine(const perc: double): double;
begin
  easeInSine := 1 - cos(perc * pi / 2.0)
end;

function easeOutSine(const perc: double): double;
begin
  easeOutSine := sin(perc * pi / 2.0)
end;

function easeInOutSine(const perc: double): double;
begin
  easeInOutSine := -(cos(pi * perc) - 1.0) / 2.0
end;


function lerpLinear(const a, z: double; perc: double): double;
begin
  perc := clamp(perc, 0.0, 1.0);
  lerpLinear := a + perc * (z - a)
end;

function lerpEaseInQuad(const a, z, perc: double): double;
begin
  lerpEaseInQuad := a + easeInQuad(perc) * (z - a)
end;

function lerpEaseOutQuad(const a, z, perc: double): double;
begin
  lerpEaseOutQuad := a + easeOutQuad(perc) * (z - a)
end;

function lerpEaseInOutQuad(const a, z, perc: double): double;
begin
  lerpEaseInOutQuad := a + easeInOutQuad(perc) * (z - a)
end;


function lerpEaseInSine(const a, z, perc: double): double;
begin
  lerpEaseInSine := a + easeInSine(perc) * (z - a)
end;

function lerpEaseOutSine(const a, z, perc: double): double;
begin
  lerpEaseOutSine := a + easeOutSine(perc) * (z - a)
end;

function lerpEaseInOutSine(const a, z, perc: double): double;
begin
  lerpEaseInOutSine := a + easeInOutSine(perc) * (z - a)
end;

end.
