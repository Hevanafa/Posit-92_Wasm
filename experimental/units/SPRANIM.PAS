{
  Sprite Animation - Part of Posit-92 game engine
  Hevanafa
}

unit SprAnim;

{$Mode ObjFPC}
{$H+}{$J-}

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
  var frameIdxRef: smallint);

procedure rewindSpriteAnim(
  var startTickRef: double;
  const startTick: double;
  var frameIdxRef: smallint);

procedure drawSpriteAnim(
  const sprite: TSpriteAnim;
  const frameIdx: smallint;
  const x, y: smallint);

procedure drawSpriteAnimToDest(
  const sprite: TSpriteAnim;
  const destHandle: longint;
  const frameIdx: smallint;
  const x, y: smallint);


implementation

uses ImgRef, ImgRefFast;

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
  var frameIdxRef: smallint);
begin
  if t >= startTick + sprite.interval then begin
    if frameIdxRef < sprite.frameCount - 1 then begin
      inc(frameIdxRef);
      startTick := startTick + sprite.interval
    end else if sprite.looping then begin
      frameIdxRef := 0;
      startTick := startTick + sprite.interval
    end;
  end;
end;

procedure rewindSpriteAnim(
  var startTickRef: double;
  const startTick: double;
  var frameIdxRef: smallint);
begin
  startTickRef := startTick;
  frameIdxRef := 0
end;

procedure drawSpriteAnim(
  const sprite: TSpriteAnim;
  const frameIdx: smallint;
  const x, y: smallint);
begin
  if frameIdx >= sprite.frameCount then exit;

  sprRegion(
    sprite.imgHandle,
    sprite.frameWidth * frameIdx, 0, sprite.frameWidth, sprite.frameHeight,
    x, y);
end;

procedure drawSpriteAnimToDest(
  const sprite: TSpriteAnim;
  const destHandle: longint;
  const frameIdx: smallint;
  const x, y: smallint);
begin
  if not isImageSet(destHandle) then exit;
  if frameIdx >= sprite.frameCount then exit;

  sprRegionToDest(
    sprite.imgHandle,
    destHandle,
    sprite.frameWidth * frameIdx, 0, sprite.frameWidth, sprite.frameHeight,
    x, y);
end;

end.