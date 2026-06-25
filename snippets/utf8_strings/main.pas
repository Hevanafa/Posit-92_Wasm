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

{ type
  TByteArray = array[0..255] of byte; }

var
  interopBuffer: TBytes;
  interopBufferLen: longint;

function getInteropBufPtr: pointer; public name 'getInteropBufPtr';
begin
  getInteropBufPtr := @interopBuffer[0]
end;

function getInteropBufLen: longint; public name 'getInteropBufLen';
begin
  getInteropBufLen := interopBufferLen
end;

procedure setInteropBufLen(value: longint); public name 'setInteropBufLen';
begin
  interopBufferLen := value
end;

{ procedure helloWorld; external 'env' name 'helloWorld'; }
procedure logWithPtr(ptr: pointer; len: longint); external 'env' name 'logWithPtr';

procedure init;
begin
  initHeapMgr;

  { Assign this only once on init }
  SetLength(interopBuffer, 256);

  { Test Pascal to JS }

  { interopBuffer := BytesOf('Hello!');
  interopBufferLen := Length(interopBuffer); }

  interopBuffer := BytesOf('你好香港');
  interopBufferLen := Length(interopBuffer);

  logWithPtr(@interopBuffer[0], interopBufferLen);
end;


exports
  init;

begin
{ Starting point is intentionally left empty }
end.
