{
  Compile:
  perl .\make.pl

  Run:
  npx http-server
}

library Main;

{$Mode ObjFPC}
{$H+}

uses
  SysUtils, WasmMemMgr;

type
  TByteArray = array[0..255] of byte;

var
  byteArray: TBytes;
  byteArrayLen: longint;

function getByteArrayPtr: pointer; public name 'getByteArrayPtr';
begin
  getByteArrayPtr := @byteArray[0]
end;

function getByteArrayLen: longint; public name 'getByteArrayLen';
begin
  getByteArrayLen := byteArrayLen
end;

procedure setByteArrayLen(value: longint); public name 'setByteArrayLen';
begin
  byteArrayLen := value
end;


{ procedure helloWorld; external 'env' name 'helloWorld'; }
procedure logWithPtr(ptr: pointer; len: longint); external 'env' name 'logWithPtr';

procedure init;
begin
  initHeapMgr;

  { Test Pascal to JS }

  { byteArray := BytesOf('Hello!');
  byteArrayLen := Length(byteArray); }

  byteArray := BytesOf('你好香港');
  byteArrayLen := Length(byteArray);

  logWithPtr(@byteArray[0], byteArrayLen);
end;


exports
  init;

begin
{ Starting point is intentionally left empty }
end.
