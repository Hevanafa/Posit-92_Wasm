{
  Composite blitting unit
  Part of Posit-92 game engine
  Hevanafa

  Similar to ImgRefFast but with a proper alpha blending logic
}

unit P92TexComp;

{$Mode ObjFPC}
{$H+}{$J-}

interface

uses P92AssetHandles;

procedure SprAlpha(const texHandle: TTextureHandle; const x, y: smallint; opacity: double);
procedure SprBlend(const texHandle: TTextureHandle; const x, y: smallint);


implementation

uses P92Tex, P92Maths, P92VGA;

procedure SprAlpha(const texHandle: TTextureHandle; const x, y: smallint; opacity: double);
var
  texturePtr: PSoftwareTex;
  px, py: smallint;
  colour: longword;
  alpha: byte;
begin
  if not IsTextureSet(texHandle) then exit;

  texturePtr := BorrowTexturePtr(texHandle);
  opacity := clamp(opacity, 0.0, 1.0);

  for py := 0 to texturePtr^.height - 1 do
    for px := 0 to texturePtr^.width - 1 do begin
      if (x + px > clipX2) or (x + px < clipX1)
        or (y + py > clipY2) or (y + py < clipY1) then continue;

      colour := unsafeSprPget(texturePtr, px, py);
      alpha := colour shr 24;
      if alpha = 0 then continue;

      alpha := trunc(alpha * opacity);
      colour := (colour and $FFFFFF) or (alpha shl 24);

      unsafePsetBlend(x + px, y + py, colour)
    end;
end;

procedure SprBlend(const texHandle: TTextureHandle; const x, y: smallint);
var
  texturePtr: PSoftwareTex;
  px, py: smallint;
  colour: longword;
begin
  if not IsTextureSet(texHandle) then exit;

  texturePtr := BorrowTexturePtr(texHandle);

  for py := 0 to texturePtr^.height - 1 do
    for px := 0 to texturePtr^.width - 1 do begin
      if (x + px > clipX2) or (x + px < clipX1)
        or (y + py > clipY2) or (y + py < clipY1) then continue;

      colour := unsafeSprPget(texturePtr, px, py);
      psetBlend(x + px, y + py, colour)
    end;
end;

end.
