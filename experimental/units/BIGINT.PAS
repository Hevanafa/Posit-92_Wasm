{
  Big Integer - Part of Posit-92 game engine
  Hevanafa
  
  This unit requires JS bindings
  See `posit-92.js` in `bigint` demo to see how
}

unit BigInt;

{$Mode ObjFPC}
{$H-}{$J+}

interface

{ procedure LoadBigIntResult(const textPtr: pointer; const textLen: smallint); public name 'LoadBigIntResult'; }

procedure BigIntSetA(const n: string);
procedure JsBigIntSetA; external 'env' name 'JsBigIntSetA';

{ function GetBigIntAPtr: pointer; public name 'GetBigIntAPtr';
function GetBigIntBPtr: pointer; public name 'GetBigIntBPtr';
function GetBigIntResultPtr: pointer; public name 'GetBigIntResultPtr';

procedure AddBigInt; external 'env' name 'AddBigInt';
procedure SubtractBigInt; external 'env' name 'SubtractBigInt';
procedure MultiplyBigInt; external 'env' name 'MultiplyBigInt';
procedure DivideBigInt; external 'env' name 'DivideBigInt'; }

{ Sets the Result register to either -1, 0, or 1 }
{ procedure CompareBigInt; external 'env' name 'CompareBigInt'; }

{ Requires only register A, outputs to the Result register }
{ procedure FormatBigInt; external 'env' name 'FormatBigInt';
procedure FormatBigIntScientific; external 'env' name 'FormatBigIntScientific'; }


implementation

uses Conv, InteropBuf;

var
  { BigInt "registers". The result register isn't always a number }
  bigIntA, bigIntB, bigIntResult: string;

procedure LoadBigIntResult(const textPtr: pointer; const textLen: smallint);
begin
  bigIntResult := strPtrToString(textPtr, textLen)
end;

function GetBigIntAPtr: pointer;
begin
  GetBigIntAPtr := @bigIntA
end;

function GetBigIntBPtr: pointer;
begin
  GetBigIntBPtr := @bigIntB
end;

function GetBigIntResultPtr: pointer;
begin
  GetBigIntResultPtr := @bigIntResult
end;

procedure BigIntSetA(const n: string);
begin
  bigIntA := n;
  WriteInteropString(n);
  JsBigIntSetA
end;

end.
