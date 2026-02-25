{
  Common conversion utility unit - Part of Posit-92 game engine
  Hevanafa
}

unit Conv;

{$Mode TP}
{$B-}

interface

function i32str(const value: Longint): string;
function f32str(const value: double): string;
function toFixed(const value: double; const decimals: integer): string;
function i16HexStr(const value: word): string;
function i8HexStr(const value: byte): string;
function boolStr(const value: boolean): string;
function parseInt(const text: string): integer;

function strPtrToString(const strPtr: PByte; const strLen: byte): ShortString;


implementation

function i32str(const value: longInt): string;
var
  result: string;
begin
  str(value, result);
  i32str := result
end;

function f32str(const value: double): string;
var
  result: string;
begin
  str(value:0:4, result);
  f32str := result
end;

function toFixed(const value: double; const decimals: integer): string;
var
  result: string;
begin
  str(value:0:decimals, result);
  toFixed := result
end;



function i16HexStr(const value: word): string;
const
  digits: array[0..15] of char = '0123456789ABCDEF';
var
  result: string;
  a: byte;
begin
  result:='';
  for a := 3 downto 0 do
    result:=result + digits[(value shr (a * 4)) and $F];
  i16hexStr := result
end;

function i8HexStr(const value: byte): string;
const
  digits: array[0..15] of char = '0123456789ABCDEF';
begin
  i8HexStr := digits[(value shr 4) and $F] + digits[value and $F];
end;

function boolStr(const value: boolean): string;
begin
  if value then
    boolStr := 'true'
  else
    boolStr := 'false'
end;

function parseInt(const text: string): integer;
var
  result, parseResult: integer;
begin
  val(text, result, parseResult);
  if parseResult <> 0 then begin
    writeLn('Error parsing to integer:', text);
    parseInt := 0
  end else
    parseInt := result;
end;


function strPtrToString(const strPtr: PByte; const strLen: byte): ShortString;
var
  text: string;
  a: integer;
  charPtr: ^byte;
begin
  setLength(text, strLen);
  charPtr := strPtr;
  for a:=1 to strLen do begin
    text[a] := char(charPtr^);
    inc(charPtr)
  end;

  strPtrToString := text
end;


end.
