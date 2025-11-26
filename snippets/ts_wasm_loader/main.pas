{
  Compile:
  E:\fpc-wasm\fpc\bin\x86_64-win64\fpc.exe -Pwasm32 -Tembedded .\main.pas
  remove-item .\main.wasm; rename-item "main" "main.wasm"

  Run:
  npx http-server
}

library Main;

{$Mode TP}

procedure helloWorld; external 'env' name 'helloWorld';

procedure init;
begin
  helloWorld
end;

exports
  init;

begin
{ Starting point is intentionally left empty }
end.
