{
  lerp_timer snippet
  By Hevanafa, 03-12-2025

  This snippet demonstrates how to use a basic TLerpTimer pattern
}


{ Step 1: Create a pair of start & end values to interpolate }
var
  startX, endX: integer;

{ Step 2: Create the TLerpTimer record }
  XLerpTimer: TLerpTimer;

{ Step 3: Intialise the LerpTimer with real time,
          anywhere in init or afterinit }
initLerp(XLerpTimer, getTimer, 2.0);

{ Step 4: Obtain the percentage and use it with the appropriate
          easing function }
var
  perc, x: double;
begin
  perc := getLerpPerc(XLerpTimer, getTimer);
  x := lerpEaseOutQuad(startX, endX, perc);

  spr(imgYourSprite, trunc(x), 100);
end;

{ You can change real time `getTimer` with your own custom time (in seconds) }
{ in init }
initLerp(XLerpTimer, gameTime, 2.0);

{ in render logic (draw) }
perc := getLerpPerc(XLerpTimer, gameTime);
x := lerpEaseOutQuad(startX, endX, perc);


{ === COMPLETE EXAMPLE === }

uses Lerp;

var
  startX, endX: integer;
  XLerpTimer: TLerpTimer;

procedure init;
begin
  startX := 50;
  endX := 270;
  initLerp(XLerpTimer, getTimer, 2.0);
end;

procedure draw;
var
  perc, x: double;
begin
  perc := getLerpPerc(XLerpTimer, getTimer);
  x := lerpEaseOutQuad(startX, endX, perc);
  spr(imgYourSprite, trunc(x), 100)
end;
