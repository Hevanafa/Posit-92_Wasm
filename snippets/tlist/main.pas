{
  Compile:
  E:\lazarus-wasm\fpc\bin\x86_64-win64\fpc.exe -Pwasm32 -Tembedded .\main.pas
  remove-item .\main.wasm; rename-item "main" "main.wasm"

  Run:
  npx http-server
}

library Main;

{$Mode TP}

uses Classes;

procedure helloWorld; external 'env' name 'helloWorld';

procedure init;
var
  list: TList;
begin
  list := TList.create;

  list.add(pointer(10));
  list.add(pointer(20));
  list.add(pointer(30));

  list.delete(0);
  list.clear;
  list.free;
  
  helloWorld
end;

exports
  init;

begin
{ Starting point is intentionally left empty }
end.
