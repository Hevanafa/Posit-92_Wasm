{
  Loading unit
  Part of Posit-92 game engine
  Hevanafa
}

unit P92Loading;

{$Mode ObjFPC}
{$H+}
{$J-}

interface

procedure RenderLoadingScreen;


implementation

uses
  Conv, VGA,
  P92Core, P92AssetRegistry;

procedure RenderLoadingScreen;
var
  s: string;
begin
  Cls($00000000);

  s := 'Progress: ' + I32Str(AssetReadyCount) + ' / ' + I32Str(AssetTotalCount);
  Print(s, 8, 16);

  VgaUpload;
  VgaPresent
end;

end.
