{
  Big Integer unit
  Part of Posit-92 framework
  By Hevanafa, 21-11-2025

  This unit requires JS bindings
  See `posit-92.js` in `bigint` demo to see how
}

unit BigInt;

{$Mode TP}

interface

var
  { BigInt "registers". The result register isn't always a number }
  BigIntA, BigIntB, BigIntResult: string;

procedure loadBigIntResult(const textPtr: pointer; const textLen: integer); public name 'loadBigIntResult';
function getBigIntAPtr: pointer; public name 'getBigIntAPtr';
function getBigIntBPtr: pointer; public name 'getBigIntBPtr';
function getBigIntResultPtr: pointer; public name 'getBigIntResultPtr';

procedure addBigInt; external 'env' name 'addBigInt';
procedure subtractBigInt; external 'env' name 'subtractBigInt';
procedure multiplyBigInt; external 'env' name 'multiplyBigInt';
procedure divideBigInt; external 'env' name 'divideBigInt';

{ Sets the Result register to either -1, 0, or 1 }
procedure compareBigInt; external 'env' name 'compareBigInt';

{ Requires only register A, outputs to the Result register }
procedure formatBigInt; external 'env' name 'formatBigInt';
procedure formatBigIntScientific; external 'env' name 'formatBigIntScientific';


implementation

uses Conv;

procedure loadBigIntResult(const textPtr: pointer; const textLen: integer);
begin
  BigIntResult := strPtrToString(textPtr, textLen)
end;

function getBigIntAPtr: pointer;
begin
  getBigIntAPtr := @BigIntA
end;

function getBigIntBPtr: pointer;
begin
  getBigIntBPtr := @BigIntB
end;

function getBigIntResultPtr: pointer;
begin
  getBigIntResultPtr := @BigIntResult
end;

end.