unit SprAnim;

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

end.