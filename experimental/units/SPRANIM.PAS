unit SprAnim;

interface

type
  { Stateless sprite animation
    Requires 3 variables: frame index, start tick }
  TSpriteAnim = record
    imgHandle: longint;
    frameCount: word;
    frameWidth, frameHeight: word;
    interval: double;  { in seconds }
    isLooping: boolean;
  end;

implementation

end.