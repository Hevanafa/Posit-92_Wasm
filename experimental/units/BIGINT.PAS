{
  Big Integer - Part of Posit-92 game engine
  Hevanafa
  
  This unit requires JS bindings
  See `posit-92.js` in `bigint` demo to see how
}

unit BigInt;

{$Mode ObjFPC}
{$H+}
{$J+}

interface

procedure BigIntSetA(const n: string);
procedure BigIntSetB(const n: string);

procedure JsBigIntSetA; external 'env' name 'JsBigIntSetA';
procedure JsBigIntSetB; external 'env' name 'JsBigIntSetB';

procedure JsBigIntAdd; external 'env' name 'JsBigIntAdd';
procedure JsBigIntSubtract; external 'env' name 'JsBigIntSubtract';
procedure JsBigIntMultiply; external 'env' name 'JsBigIntMultiply';
procedure JsBigIntDivide; external 'env' name 'JsBigIntDivide';

{ Sets the Result register to either -1, 0, or 1 }
procedure JsBigIntCompare; external 'env' name 'JsBigIntCompare';

{ Requires only register A, outputs to the Result register }
{ procedure FormatBigInt; external 'env' name 'FormatBigInt';
procedure FormatBigIntScientific; external 'env' name 'FormatBigIntScientific'; }


implementation

uses Conv, InteropBuf;

procedure BigIntSetA(const n: string);
begin
  WriteInteropString(n);
  JsBigIntSetA
end;

procedure BigIntSetB(const n: string);
begin
  WriteInteropString(n);
  JsBigIntSetB
end;

end.
