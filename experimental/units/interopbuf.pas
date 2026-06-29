unit InteropBuf;

{$Mode ObjFPC}
{$H+}

interface

procedure InitInteropBuffer;

function GetInteropBufPtr: pointer; public name 'GetInteropBufPtr';
function GetInteropBufLen: longint; public name 'GetInteropBufLen';
procedure SetInteropBufLen(value: longint); public name 'SetInteropBufLen';

procedure WriteInteropString(const s: AnsiString);
function ReadInteropString: AnsiString;


implementation

uses
  SysUtils;

const
  InteropBufCapacity = 1020;

var
  interopBufArray: array[0..InteropBufCapacity - 1] of byte;
  interopBufLen: longint;

procedure InitInteropBuffer;
begin
  fillchar(interopBufArray, SizeOf(interopBufArray), 0);
  interopBufLen := 0
end;

function GetInteropBufPtr: pointer;
begin
  GetInteropBufPtr := @interopBufArray[0]
end;

function GetInteropBufLen: longint;
begin
  GetInteropBufLen := interopBufLen
end;

procedure SetInteropBufLen(value: longint);
begin
  interopBufLen := value
end;

procedure WriteInteropString(const s: AnsiString);
var
  byteAry: TBytes;
begin
  byteAry := BytesOf(s);
  interopBufLen := length(byteAry);
  move(byteAry, interopBufArray, interopBufLen);
end;

function ReadInteropString: AnsiString;
begin
  SetString(ReadInteropString, PAnsiChar(@interopBufArray[0]), interopBufLen)
end;

end.

