{
  Big Integer unit
  Part of Posit-92 game engine
  By Hevanafa
  
  This unit requires the mixin `BigIntMixin`
}

unit BigInt;

{$Mode ObjFPC}
{$H+}
{$J+}

interface

function BigIntFetchRegA: string;
procedure BigIntSetA(const n: string);
function BigIntFetchRegB: string;
procedure BigIntSetB(const n: string);

procedure JsBigIntAdd; external 'env' name 'JsBigIntAdd';
procedure JsBigIntSubtract; external 'env' name 'JsBigIntSubtract';
procedure JsBigIntMultiply; external 'env' name 'JsBigIntMultiply';
procedure JsBigIntDivide; external 'env' name 'JsBigIntDivide';

{ Sets the Result register to either -1, 0, or 1 }
procedure JsBigIntCompare; external 'env' name 'JsBigIntCompare';

{ Requires only register A, outputs to the Result register }
function BigIntFormat(const n: string): string;
function BigIntFormatScientific(const n: string): string;
function BigIntFetchResult: string;


implementation

uses Conv, InteropBuf;

{
  Verbs used for data flow:
  Set  : Pascal --> JS
  Fetch: JS --> Pascal
}

procedure JsBigIntSetA; external 'env' name 'JsBigIntSetA';
procedure JsBigIntSetB; external 'env' name 'JsBigIntSetB';

procedure JsBigIntFetchRegA; external 'env' name 'JsBigIntFetchRegA';
procedure JsBigIntFetchRegB; external 'env' name 'JsBigIntFetchRegB';

procedure JsBigIntFormat; external 'env' name 'JsBigIntFormat';
procedure JsBigIntFormatScientific; external 'env' name 'JsBigIntFormatScientific';
procedure JsBigIntFetchResult; external 'env' name 'JsBigIntFetchResult';

function BigIntFetchRegA: string;
begin
  JsBigIntFetchRegA;
  BigIntFetchRegA := ReadInteropString
end;

procedure BigIntSetA(const n: string);
begin
  WriteInteropString(n);
  JsBigIntSetA
end;

function BigIntFetchRegB: string;
begin
  JsBigIntFetchRegB;
  BigIntFetchRegB := ReadInteropString
end;

procedure BigIntSetB(const n: string);
begin
  WriteInteropString(n);
  JsBigIntSetB
end;

function BigIntFormat(const n: string): string;
begin
  BigIntSetA(n);
  JsBigIntFormat;
  BigIntFormat := ReadInteropString
end;

function BigIntFormatScientific(const n: string): string;
begin
  BigIntSetA(n);
  JsBigIntFormatScientific;
  BigIntFormatScientific := ReadInteropString
end;

function BigIntFetchResult: string;
begin
  JsBigIntFetchResult;
  BigIntFetchResult := ReadInteropString
end;

end.
