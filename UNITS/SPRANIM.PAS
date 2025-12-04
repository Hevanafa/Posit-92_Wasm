unit SprAnim;

{$Mode TP}
{$B-}

interface

type
  { Stateless sprite animation
    Requires 2 variables: frame index, start tick }
  TSpriteAnim = record
    imgHandle: longint;
    frameCount: word;
    frameWidth, frameHeight: word;
    interval: double;  { in seconds }
    looping: boolean;
  end;

procedure initSpriteAnim(
  var sprite: TSpriteAnim;
  const imgHandle: longint;
  const frameCount, frameWidth, frameHeight: word;
  const interval: double);

procedure updateSpriteAnim(
  const sprite: TSpriteAnim;
  const t: double;
  var startTick: double;
  var frameIdx: integer);

procedure rewindSpriteAnim(var startTickRef: double; const startTick: double; var frameIdx: integer);

procedure drawSpriteAnim(const sprite: TSpriteAnim; const frameIdx: integer; const x, y: integer);


implementation

uses ImgRefFast;

procedure initSpriteAnim(
  var sprite: TSpriteAnim;
  const imgHandle: longint;
  const frameCount, frameWidth, frameHeight: word;
  const interval: double);
begin
  sprite.imgHandle := imgHandle;
  sprite.frameCount := frameCount;
  sprite.frameWidth := frameWidth;
  sprite.frameHeight := frameHeight;
  sprite.interval := interval;
  sprite.looping := true
end;

procedure updateSpriteAnim(
  const sprite: TSpriteAnim;
  const t: double;
  var startTick: double;
  var frameIdx: integer);
begin
  if t >= startTick + sprite.interval then begin
    if frameIdx < sprite.frameCount - 1 then begin
      inc(frameIdx);
      startTick := startTick + sprite.interval
    end else if sprite.looping then begin
      frameIdx := 0;
      startTick := startTick + sprite.interval
    end;
  end;
end;

procedure rewindSpriteAnim(var startTickRef: double; const startTick: double; var frameIdx: integer);
begin
  startTickRef := startTick;
  frameIdx := 0
end;

procedure drawSpriteAnim(const sprite: TSpriteAnim; const frameIdx: integer; const x, y: integer);
begin
  if frameIdx >= sprite.frameCount then exit;

  sprRegion(
    sprite.imgHandle,
    sprite.frameWidth * frameIdx, 0, sprite.frameWidth, sprite.frameHeight,
    x, y);
end;

end.