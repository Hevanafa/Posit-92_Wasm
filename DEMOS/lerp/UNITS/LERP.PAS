{
  Lerp unit
  Part of Posit-92 framework
  By Hevanafa, 23-11-2025

  Generic unit that contains easing functions
}

unit Lerp;

{$Mode TP}

interface

{ All the time / tick units are in seconds }

type
  TLerpTimer = record
    active: boolean;
    startTick, endTick: double;
    looping: boolean;
  end;

procedure initLerp(var lt: TLerpTimer; const startTick, duration: double);
function newLerp(const startTick, duration: double): TLerpTimer;
function getLerpPerc(const lt: TLerpTimer; const t: double): double;
function isLerpComplete(const lt: TLerpTimer; const t: double): boolean;

function easeOutQuad(const perc: double): double;

function lerpLinear(const a, z: double; perc: double): double;
function lerpEaseInQuad(const a, z, perc: double): double;
function lerpEaseOutQuad(const a, z, perc: double): double;
function lerpEaseInOutQuad(const a, z, perc: double): double;


implementation

uses Maths, Timing;

procedure initLerp(var lt: TLerpTimer; const startTick, duration: double);
begin
  lt.active := true;
  lt.startTick := startTick;
  lt.endTick := startTick + duration;
  lt.looping := false;
end;

function newLerp(const startTick, duration: double): TLerpTimer;
var
  result: TLerpTimer;
begin
  with result do begin
    result.active := true;
    result.startTick := startTick;
    result.endTick := startTick + duration;
    result.looping := false;
  end;

  newLerp := result
end;

function getLerpPerc(const lt: TLerpTimer; const t: double): double;
begin
  if not lt.active then begin
    getLerpPerc := 0.0;
    exit
  end;

  getLerpPerc := clamp((t - lt.startTick) / (lt.endTick - lt.startTick), 0.0, 1.0)
end;

function isLerpComplete(const lt: TLerpTimer; const t: double): boolean;
begin
  if lt.looping then begin
    isLerpComplete := false;
    exit
  end;

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
  easeInOutSine := -(cos(pi * x) - 1.0) / 2.0
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


end.
