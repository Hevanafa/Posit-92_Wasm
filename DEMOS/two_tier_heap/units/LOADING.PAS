{
  Loading unit - Part of Posit-92 game engine
  Hevanafa
}

unit Loading;

interface

procedure renderLoadingScreen;

implementation

uses
  Conv, VGA,
  Assets;

function getLoadingActual: integer; external 'env' name 'getLoadingActual';
function getLoadingTotal: integer; external 'env' name 'getLoadingTotal';

procedure renderLoadingScreen;
var
  s: string;
  w: word;
begin
  cls($FF000000);

  s := 'Progress: ' + i32str(getLoadingActual) + ' / ' + i32str(getLoadingTotal);
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, vgaHeight div 2 - defaultFont.lineHeight);

  vgaFlush
end;

end.
