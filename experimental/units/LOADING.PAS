{
  Loading unit - Part of Posit-92 game engine
  Hevanafa
}

unit Loading;

{$Mode ObjFPC}
{$H+}{$J-}

interface

procedure renderLoadingScreen;

implementation

uses
  Conv, VGA,
  Assets;

function getLoadingActual: smallint; external 'env' name 'getLoadingActual';
function getLoadingTotal: smallint; external 'env' name 'getLoadingTotal';

procedure renderLoadingScreen;
var
  s: string;
  w: word;
begin
  cls($00000000);

  s := 'Progress: ' + i32str(getLoadingActual) + ' / ' + i32str(getLoadingTotal);
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, vgaHeight div 2 - defaultFont.lineHeight);

  vgaFlush
end;

end.
