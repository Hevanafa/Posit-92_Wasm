unit Colour;

interface

function HSVtoRGB(h, s, v: double): longword;
function lerpColour(const colourA, colourB: longword; const perc: double): longword;


implementation

uses Maths;

{ h, s, v: [0.0, 1.0] }
function HSVtoRGB(h, s, v: double): longword;
var
  r, g, b: byte;
  i: integer;
  f, p, q, t: double;
begin
  h := clamp(h, 0.0, 1.0);
  s := clamp(s, 0.0, 1.0);
  v := clamp(v, 0.0, 1.0);

  { Greyscale }
  if s = 0.0 then begin
    r := trunc(v * 255);
    g := r;
    b := r;
    HSVtoRGB := $FF000000 or (r shl 16) or (g shl 8) or b;
    exit
  end;

  { Convert hue to [0.0, 6.0] }
  h := h * 6.0;
  i := trunc(h);
  f := h - i;

  p := v * (1.0 - s);
  q := v * (1.0 - s * f);
  t := v * (1.0 - s * (1.0 - f));

  { Determine RGB }
  case i mod 6 of
    0: begin r := trunc(v * 255); g := trunc(t * 255); b := trunc(p * 255); end;
    1: begin r := trunc(q * 255); g := trunc(v * 255); b := trunc(p * 255); end;
    2: begin r := trunc(p * 255); g := trunc(v * 255); b := trunc(t * 255); end;
    3: begin r := trunc(p * 255); g := trunc(q * 255); b := trunc(v * 255); end;
    4: begin r := trunc(t * 255); g := trunc(p * 255); b := trunc(v * 255); end;
    5: begin r := trunc(v * 255); g := trunc(p * 255); b := trunc(q * 255); end;
  end;

  HSVtoRGB := $FF000000 or (r shl 16) or (g shl 8) or b
end;

function lerpColour(const colourA, colourB: longword; const perc: double): longword;
var
  a, r, g, b: byte;
begin
  a := trunc((colourA shr 24 and $FF) + perc * ((colourB shr 24 and $FF) - (colourA shr 24 and $FF)));
  r := trunc((colourA shr 16 and $FF) + perc * ((colourB shr 16 and $FF) - (colourA shr 16 and $FF)));
  g := trunc((colourA shr 8 and $FF) + perc * ((colourB shr 8 and $FF) - (colourA shr 8 and $FF)));
  b := trunc((colourA and $FF) + perc * ((colourB and $FF) - (colourA and $FF)));

  lerpColour := (a shl 24) or (r shl 16) or (g shl 8) or b
end;


end.
