{
  Common conversion utility unit that doesn't rely on SysUtils
  Part of Posit-92 game engine
  By Hevanafa
}

unit P92Conversions;

{$Mode ObjFPC}
{$H-}  { Use ShortStrings }
{$J-}  { Don't allow assignments to typed consts }

interface

function I32Str(const value: Longint): string;
function U32Str(const value: longword): string;
function F32Str(const value: double): string;
function NumberToStr(const value: double): string;

function ToFixed(const value: double; const decimals: smallint): string;

function U16HexStr(const value: word): string;
function U8HexStr(const value: byte): string;

function BoolStr(const value: boolean): string;
function ParseInt(const text: string): smallint;


implementation

function I32Str(const value: longint): string;
begin
  str(value, I32Str)
end;

function U32Str(const value: longword): string;
begin
  str(value, U32Str)
end;

function F32Str(const value: double): string;
begin
  str(value:0:4, F32Str)
end;

function NumberToStr(const value: double): string;
var
  s: string;
begin
  if frac(value) = 0 then
    str(trunc(value), NumberToStr)
  else begin
    str(value:0:15, s);

    while s[length(s)] = '0' do
      s := copy(s, 1, length(s) - 1);

    NumberToStr := s
  end;
end;

function ToFixed(const value: double; const decimals: smallint): string;
begin
  str(value:0:decimals, ToFixed)
end;

function U16HexStr(const value: word): string;
const
  digits: array[0..15] of char = '0123456789ABCDEF';
var
  a: byte;
begin
  U16HexStr := '';
  for a := 3 downto 0 do
    U16HexStr := U16HexStr + digits[(value shr (a * 4)) and $F];
end;

function U8HexStr(const value: byte): string;
const
  digits: array[0..15] of char = '0123456789ABCDEF';
begin
  U8HexStr := digits[(value shr 4) and $F] + digits[value and $F];
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

end.
