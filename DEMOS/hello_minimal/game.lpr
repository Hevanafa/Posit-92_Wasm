library Game;

{$Mode ObjFPC}
{$H+}{$J-}

uses
  P92Core, P92AssetRegistry, P92Logger, P92VGA;

procedure OnReady;
begin
  WriteLog('Hello from hello_minimal!')
end;

procedure Update;
begin

end;

procedure Draw;
begin
  Cls($FF101010);

  Print('Hello from hello_minimal!', 8, 8);
end;

procedure Init;
var
  config: TP92AppConfig;
begin
  config := DefaultP92AppConfig;

  config.LoadDefaultBMFont := false;
  config.LoadDefaultCursor := false;

  P92Start(config);
end;

exports
  Init, OnReady, Update, Draw;

begin
  { Starting point is intentionally left empty }
end.
