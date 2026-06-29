unit InteropBuf;

{$Mode ObjFPC}
{$H+}

interface

function GetInteropBufPtr: pointer; public name 'GetInteropBufPtr';
function GetInteropBufLen: longint; public name 'GetInteropBufLen';
procedure SetInteropBufLen(value: longint); public name 'SetInteropBufLen';

procedure WriteInteropString(const s: AnsiString);
function ReadInteropString: AnsiString;


implementation

const
  InteropBufCapacity = 1020;

var
  interopBufArray: array[0..InteropBufCapacity - 1] of byte;
  interopBufLen: longint;

function GetInteropBufPtr: pointer;
begin

end;

function GetInteropBufLen: longint;
begin

end;

procedure SetInteropBufLen(value: longint);
begin

end;

procedure WriteInteropString(const s: AnsiString);
begin

end;

function ReadInteropString: AnsiString;
begin

end;

initialization
  fillchar(interopBufArray, SizeOf(interopBuf), 0);
  interopBufLen := 0;

end.

