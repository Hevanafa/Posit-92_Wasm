{
  Common conversion utility unit - Part of Posit-92 game engine
  Hevanafa
}

unit Conv;

{$Mode ObjFPC}
{$H-}{$J+}

interface

function I32Str(const value: Longint): string;
function F32str(const value: double): string;
function ToFixed(const value: double; const decimals: smallint): string;
function I16HexStr(const value: word): string;
function I8HexStr(const value: byte): string;
function BoolStr(const value: boolean): string;
function ParseInt(const text: string): smallint;

function StrPtrToString(const strPtr: PByte; const strLen: byte): ShortString;


implementation

function I32Str(const value: longInt): string;
begin
  str(value, I32Str)
end;

function F32str(const value: double): string;
begin
  str(value:0:4, F32str)
end;

function ToFixed(const value: double; const decimals: smallint): string;
begin
  str(value:0:decimals, ToFixed)
end;



function I16HexStr(const value: word): string;
const
  digits: array[0..15] of char = '0123456789ABCDEF';
var
  a: byte;
begin
  I16HexStr := '';
  for a := 3 downto 0 do
    I16HexStr := I16HexStr + digits[(value shr (a * 4)) and $F];
end;

function I8HexStr(const value: byte): string;
const
  digits: array[0..15] of char = '0123456789ABCDEF';
begin
  I8HexStr := digits[(value shr 4) and $F] + digits[value and $F];
end;

function BoolStr(const value: boolean): string;
begin
  if value then
    BoolStr := 'true'
  else
    BoolStr := 'false'
end;

function ParseInt(const text: string): smallint;
var
  parseResult: smallint;
begin
  val(text, ParseInt, parseResult);

  if parseResult <> 0 then begin
    writeLn('Error parsing to smallint:', text);
    ParseInt := 0
  end;
end;


function StrPtrToString(const strPtr: PByte; const strLen: byte): ShortString;
var
  text: string;
  a: smallint;
  charPtr: ^byte;
begin
  setLength(text, strLen);
  charPtr := strPtr;
  for a:=1 to strLen do begin
    text[a] := char(charPtr^);
    inc(charPtr)
  end;

  StrPtrToString := text
end;


end.
