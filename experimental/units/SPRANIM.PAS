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
    isLooping: boolean;
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


implementation

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
  sprite.isLooping := true
end;

procedure updateSpriteAnim(
  const sprite: TSpriteAnim;
  const t: double;
  var startTick: double;
  var frameIdx: integer);
begin
  if t >= startTick + sprite.interval then begin
    if frameIdx < sprite.frameCount then begin
      inc(frameIdx);
      startTick := startTick + sprite.interval
    end;

    if (frameIdx >= sprite.frameCount) and sprite.isLooping then
      frameIdx := 0
    else
      frameIdx := sprite.frameCount - 1;
  end;
end;

end.