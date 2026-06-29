{
  Loading unit
  Part of Posit-92 game engine
  Hevanafa
}

unit Loading;

{$Mode ObjFPC}
{$H+}{$J-}

interface

function GetLoadingActual: smallint; external 'env' name 'GetLoadingActual';
function GetLoadingTotal: smallint; external 'env' name 'GetLoadingTotal';

procedure RenderLoadingScreen;


implementation

uses
  Conv, VGA,
  EngineFonts;

procedure RenderLoadingScreen;
var
  s: string;
  w: word;
begin
  Cls($00000000);

  s := 'Progress: ' + I32Str(GetLoadingActual) + ' / ' + I32Str(GetLoadingTotal);
  w := MeasureDefault(s);
  PrintDefault(s, (VgaWidth - w) div 2, VgaHeight div 2 - DefaultFontPtr^.lineHeight);

  VgaUpload;
  VgaPresent
end;

end.
