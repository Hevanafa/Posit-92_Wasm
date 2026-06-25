{
  Compile:
  perl .\make.pl

  Run:
  npx http-server
}

library Main;

{$Mode ObjFPC}
{$H+}

uses SysUtils;

type
  TByteArray = array[0..255] of byte;

var
  byteArray: TBytes;
  byteArrayLen: LongInt;

function getByteArrayPtr: pointer; public name 'getBytePtr';
begin
  getByteArrayPtr := @byteArray[0]
end;

function getByteArrayLen: longint; public name 'getByteArrayLen';
begin
  getByteArrayLen := byteArrayLen
end;

{ procedure helloWorld; external 'env' name 'helloWorld'; }

procedure init;
begin
  byteArray := BytesOf('Hello!');
  byteArrayLen := Length(byteArray)
end;

exports
  init;

begin
{ Starting point is intentionally left empty }
end.
