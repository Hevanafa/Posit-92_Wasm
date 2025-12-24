unit Loading;

interface

procedure renderLoadingScreen(const actual, total: integer); public name 'renderLoadingScreen';

implementation

uses
  Conv, VGA,
  Assets;

procedure renderLoadingScreen(const actual, total: integer);
var
  perc: double;
begin
  cls($FF6495ED);

  printDefault('Progress: ' + i32str(actual) + ' / ' + i32str(total), 10, 10);

  vgaFlush
end;

end.
