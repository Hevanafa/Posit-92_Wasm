{
  Loading unit
  Part of Posit-92 game engine
  Hevanafa
}

unit P92Loading;

{$Mode ObjFPC}
{$H-}{$J-}

interface

procedure RenderLoadingScreen;


implementation

uses
  P92Core, P92Conversions, P92AssetRegistry,
  P92VGA, P92WebGL;

procedure RenderLoadingScreen;
var
  s: string;
begin
  Cls($00000000);

  s := 'Progress: ' + I32Str(GetAssetReadyCount) + ' / ' + I32Str(GetAssetTotalCount);
  Print(s, 8, 16);

  VgaUpload;
{$ifdef P92_WEBGL}
  WebGLPresent;
{$else}
  VgaPresent;
{$endif}
end;

end.
