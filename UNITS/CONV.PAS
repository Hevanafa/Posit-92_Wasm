{ Common conversion utility unit }

unit Conv;

{$Mode TP}
{$B-}

interface

function i32str(const value: Longint): string;
function f32str(const value: double): string;
function i16HexStr(const value: word): string;
function i8HexStr(const value: byte): string;
function boolStr(const value: boolean): string;
function parseInt(const text: string): integer;

function i16Iif(const expr: boolean; const truePart, falsePart: integer): integer;
function u16Iif(const expr: boolean; const truePart, falsePart: word): word;
function i32Iif(const expr: boolean; const truePart, falsePart: longint): longint;
function u32Iif(const expr: boolean; const truePart, falsePart: longword): longword;
function stringIif(const expr: boolean; const truePart, falsePart: string): string;

function strPtrToString(const textPtr: pointer; const textLen: word): string;


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

function i16Iif(const expr: boolean; const truePart, falsePart: integer): integer;
begin
  if expr then
    i16Iif := truePart
  else
    i16Iif := falsePart;
end;

function u16Iif(const expr: boolean; const truePart, falsePart: word): word;
begin
  if expr then
    u16Iif := truePart
  else
    u16Iif := falsePart;
end;

function i32Iif(const expr: boolean; const truePart, falsePart: longint): longint;
begin
  if expr then
    i32Iif := truePart
  else
    i32Iif := falsePart;
end;

function u32Iif(const expr: boolean; const truePart, falsePart: longword): longword;
begin
  if expr then
    u32Iif := truePart
  else
    u32Iif := falsePart;
end;

function stringIif(const expr: boolean; const truePart, falsePart: string): string;
begin
  if expr then
    stringIif := truePart
  else
    stringIif := falsePart;
end;

function strPtrToString(const textPtr: pointer; const textLen: word): string;
var
  text: string;
  a: integer;
  charPtr: ^byte;
begin
  setLength(text, textLen);
  charPtr := textPtr;
  for a:=1 to textLen do begin
    text[a] := char(charPtr^);
    inc(charPtr)
  end;

  strPtrToString := text
end;


end.
