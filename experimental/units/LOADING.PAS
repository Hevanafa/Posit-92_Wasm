{
  Loading unit - Part of Posit-92 game engine
  Hevanafa
}

unit Loading;

{$Mode ObjFPC}
{$H+}{$J-}

interface

procedure RenderLoadingScreen;

implementation

uses
  Conv, VGA,
  Assets;

function GetLoadingActual: smallint; external 'env' name 'getLoadingActual';
function GetLoadingTotal: smallint; external 'env' name 'getLoadingTotal';

procedure RenderLoadingScreen;
var
  s: string;
  w: word;
begin
  Cls($00000000);

  s := 'Progress: ' + I32Str(GetLoadingActual) + ' / ' + I32Str(GetLoadingTotal);
  w := MeasureDefault(s);
  PrintDefault(s, (VgaWidth - w) div 2, VgaHeight div 2 - defaultFont.lineHeight);

  VgaUpload;
  VgaPresent
end;

end.
