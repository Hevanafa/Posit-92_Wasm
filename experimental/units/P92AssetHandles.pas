{
  P92 asset handle unit
  Part of Posit-92 game engine

  The asset handles are automatically incremented by P92AssetRegistry
}

unit P92AssetHandles;

{$Mode ObjFPC}
{$H-}  { Use ShortStrings }
{$J-}  { Don't allow assignments to typed consts }

interface

type
  { Starts from 1 }
  TTextureHandle = type longint;
  { Starts from 1 }
  TBMFontHandle = type longint;
  { Starts from 1 }
  TSoundHandle = type longint;
  { Starts from 1 }
  THWTextureHandle = type longint;

implementation

end.
