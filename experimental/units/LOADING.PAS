unit Loading;

interface

procedure renderLoadingScreen(const actual, total: integer); public name 'renderLoadingScreen';

implementation

uses
  Conv, VGA,
  Assets;

procedure renderLoadingScreen(const actual, total: integer);
var
  s: string;
  w: word;
begin
  cls($FF6495ED);

  s := 'Progress: ' + i32str(actual) + ' / ' + i32str(total);
  w := measureDefault(s);
  printDefault(s, (vgaWidth - w) div 2, vgaHeight div 2 - defaultFont.lineHeight);

  vgaFlush
end;

end.
