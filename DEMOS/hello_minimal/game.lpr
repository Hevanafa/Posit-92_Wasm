library Game;

{$Mode ObjFPC}
{$H+}
{$J-}  { Switch off assignments to typed constants }

uses
  EngineCore, Logger, VGA;

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

  VgaUpload;
  VgaPresent
end;

exports
  OnReady, Update, Draw;

begin
{ Starting point is intentionally left empty }
end.
