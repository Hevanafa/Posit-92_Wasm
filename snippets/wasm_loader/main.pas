{
  E:\lazarus-wasm\fpc\bin\x86_64-win64\fpc.exe -Pwasm32 -Tembedded .\program.pas
  rename-item .\program .\program.wasm
}

library Program;

{$Mode ObjFPC}

procedure helloWorld; external 'env' name 'helloWorld';

begin

end.
